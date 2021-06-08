/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A local HTTP Server which acts as a server for cloud files.
*/

import Foundation
import OSLog
import Common

public extension NSNotification.Name {
    static let itemsChanged: NSNotification.Name =
        NSNotification.Name(rawValue: Bundle(for: StandaloneServer.self).bundleIdentifier!.appending(".ItemsChanged"))
}

public class StandaloneServer {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "server")

    static let groupContainer = "group.com.example.apple-samplecode.FruitBasket"
    public let databaseURL: URL
    var dispatch: BackendDispatch!
    var itemDB: ItemDatabase!
    private let contentBasedChunkStore: ContentBasedChunkStore
    let queue = DispatchQueue(label: "notify queue")
    let notifyThrottle: Throttle

    public var port: in_port_t {
        dispatch.port
    }

    public init(_ databaseURL: URL?, contentBasedChunkStore: ContentBasedChunkStore) {
        if let databaseURL = databaseURL {
            self.databaseURL = databaseURL
        } else {
            self.databaseURL =
                FileManager().containerURL(forSecurityApplicationGroupIdentifier: StandaloneServer.groupContainer)!.appendingPathComponent("files.db")
        }
        self.contentBasedChunkStore = contentBasedChunkStore
        notifyThrottle = Throttle(timeout: .milliseconds(500), "notify throttle")

        notifyThrottle.handler = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.didHandleRequest()
        }
    }

    public func run() throws {
        // When a database item changes, remember the item and signal notifyThrottle to send a push notification later.
        let changeListener: ItemDatabase.ChangeListener = { [weak self] id in
            guard let strongSelf = self else { return }
            strongSelf.notify(for: id)
            strongSelf.notifyThrottle.signal()
        }

        // When the database account changes, update the server-side account listeners.
        let accountListener: ItemDatabase.AccountListener = { [weak self] accounts in
            guard let strongSelf = self else { return }
            strongSelf.queue.async {
                do {
                    try strongSelf.updateListeners(accounts: accounts)
                } catch let error as NSError {
                    strongSelf.logger.info("error updating account list: \(error)")
                }
            }
        }

        itemDB = try ItemDatabase(location: databaseURL, changeListener: changeListener, accountListener: accountListener)

        let name = "FruitBasket"
        dispatch = try BackendDispatch(name: name, accountBackend: AccountBackend(database: itemDB))
        let accounts = try itemDB.allAccounts()
        try updateListeners(accounts: accounts)
        notifyThrottle.resume()
        logger.info("serving from \(self.databaseURL.path):\(self.dispatch.port)...")
    }

    func updateListeners(accounts newAccounts: [AccountService.Account]) throws {
        let prev = synchronized(dispatch) {
            return dispatch.backends.keys
        }

        dispatch.removeBackends(except: newAccounts.map({ $0.identifier }))

        prev.filter({ ident in !newAccounts.contains(where: { acc in ident == acc.identifier }) }).forEach { ident in
            logger.info("removed account for \(ident)")
        }

        // Create a new dispatch for each listener.
        for account in newAccounts {
            let backend = try DomainBackend(identifier: account.identifier, database: itemDB, contentBasedChunkStore: self.contentBasedChunkStore)
            dispatch[account.identifier] = backend
            if prev.contains(account.identifier) {
                logger.info("updated account for \(account.identifier)")
            } else {
                logger.info("added account for \(account.identifier)")
            }
        }
    }

    func didHandleRequest() {
        itemsToNotify.forEach { item in
            DistributedNotificationCenter.default().post(Notification(name: .itemsChanged, object: "\(item.id)"))
        }

        queue.sync {
            self.itemsToNotify.removeAll()
        }
    }

    var itemsToNotify = Set<DomainService.ItemIdentifier>()

    func notify(for itemIdentifier: DomainService.ItemIdentifier) {
        queue.async {
            self.itemsToNotify.insert(itemIdentifier)
        }
    }
}
