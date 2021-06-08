/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A delegate that manages the app's lifecycle.
*/

import Cocoa
import FileProvider
import Common
import os.log
import Extension
import FinderSync
import Server
import SwiftUI

extension NSFileProviderDomain {
    var prettyDescription: String {
        return "\(displayName) (\(identifier.rawValue.suffix(12)))"
    }
}

private actor Notifier {
    let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "notifier")

    var itemsToNotify: Set<DomainService.ItemIdentifier> = []

    func notify(for itemIdentifier: DomainService.ItemIdentifier) {
        itemsToNotify.insert(itemIdentifier)
    }

    func serverChangeReceived(_ entries: [DomainEntry]) async {
        guard !self.itemsToNotify.isEmpty else { return }
        for entry in entries {
            guard let manager = NSFileProviderManager(for: entry.domain) else { continue }
            logger.debug("🔆 notifying \(entry.domain.prettyDescription) for changes on \(self.itemsToNotify)")
            do {
                try await manager.signalEnumerator(for: .workingSet)
            } catch let error as NSError {
                logger.debug("❌ failed to signal working set for \(entry.domain.prettyDescription): \(error)")
            }
        }
        self.itemsToNotify.removeAll()
    }

    func signalItems(_ entries: [DomainEntry]) async {
        for entry in entries {
            guard let manager = NSFileProviderManager(for: entry.domain) else { continue }
            logger.debug("🔆 notifying \(entry.domain.prettyDescription) for auth status change")
            if entry.authenticated || UserDefaults.sharedContainerDefaults.ignoreAuthentication {
                do {
                    try await manager.signalErrorResolved(NSFileProviderError(.notAuthenticated))
                } catch let error as NSError {
                    logger.error("❌ failed to signal authentication error resolved for \(entry.domain.prettyDescription): \(error)")
                }
            } else {
                // Notify the workingSet because FileProvider needs to save the new unauthenticated state.
                do {
                    try await manager.signalEnumerator(for: .workingSet)
                } catch let error as NSError {
                    logger.error("❌ failed to signal working set for \(entry.domain.prettyDescription): \(error)")
                }
            }
        }
    }

}

@NSApplicationMain
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSXPCListenerDelegate {

    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "app")

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var domainTable: NSTableView!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @objc dynamic var domainEntries = [DomainEntry]()
    @objc dynamic var userDefaultsController = NSUserDefaultsController(defaults: UserDefaults.sharedContainerDefaults, initialValues: nil)
    @objc dynamic var itemCount: Int = 0
    private var contentBasedChunkStore: ContentBasedChunkStore!
    let queue = DispatchQueue(label: "notify queue")
    private let notifier = Notifier()
    let accountConnection = DomainConnection.accountConnection(hostname: UserDefaults.sharedContainerDefaults.hostname, port: defaultPort)

    func setupDomainPipe() async {
        await setupDomainPipeAsync(notification: NotificationCenter.default.notifications(named: .fileProviderDomainDidChange))
        await setupDomainPipeAsync(notification: DistributedNotificationCenter.default().notifications(named: .accountsDidChange, object: nil))
    }

    func setupDomainPipeAsync(notification: NotificationCenter.Notifications) async {
        let domainAccounts = notification.map { _ -> ([NSFileProviderDomain], [AccountService.Account]) in
            let domains: [NSFileProviderDomain] = try await NSFileProviderManager.domains()
            let accounts: [AccountService.Account] = try await self.accountConnection.makeJSONCall(AccountService.ListAccountParameter()).accounts
            return (domains, accounts)
        }
        async {
            do {
                for try await value in domainAccounts {
                    await self.updateDomains(value)
                }
            } catch {
                handleDomainPipeError(error)
            }
        }
    }

    func handleDomainPipeError(_ error: Error) {
        let retry = {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(3))) {
                async {
                    await self.setupDomainPipe()
                }
            }
        }
        switch error {
        case NSFileProviderError.providerNotFound:
            logger.error("couldn't find embedded provider")
            retry()
        case URLError.cannotConnectToHost:
            logger.error("couldn't connect to host")
            retry()
        default:
            self.presentError(error)
        }
    }

    var versionString: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString").map { "\($0)" } ?? "unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String).map { "\($0)" } ?? "unknown"
        return "\(shortVersion) (\(version))"
    }

    let notifyThrottle: Throttle

    let databaseURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent("files.db")
    let builtinServer: StandaloneServer

    @MainActor
    override init() {
        notifyThrottle = Throttle(timeout: .milliseconds(500), "notify throttle")
        self.contentBasedChunkStore = try! LocalContentBasedChunkStore()
        builtinServer = StandaloneServer(databaseURL, contentBasedChunkStore: self.contentBasedChunkStore)

        super.init()

        do {
            try builtinServer.run()
        } catch let error {
            presentError(error)
        }

        notifyThrottle.handler = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            async {
                await strongSelf.serverChangeReceived()
            }
        }
        notifyThrottle.resume()

        DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.itemsChanged(_:)),
                                                            name: .itemsChanged, object: nil, suspensionBehavior: .deliverImmediately)

        async {
            await setupDomainPipe()
            NotificationCenter.default.post(Notification(name: NSNotification.Name.fileProviderDomainDidChange))
            DistributedNotificationCenter.default().post(Notification(name: .accountsDidChange))
        }
    }

    @objc
    func itemsChanged(_ notification: Notification) {
        guard let object = notification.object as? String,
              let id = Int64(object) else { return }
        async { await notifier.notify(for: DomainService.ItemIdentifier(id)) }
        notifyThrottle.signal()
    }

    func updateItemCount() async {
        do {
            let res = try await accountConnection.makeJSONCall(AccountService.InfoParameter())
            DispatchQueue.main.async {
                self.itemCount = res.itemCount
            }
        } catch let error as NSError {
            logger.error("Error updating item count: \(error)")
        }
    }

    @MainActor
    override func awakeFromNib() {
        super.awakeFromNib()
        window.representedURL = databaseURL
        window.standardWindowButton(.documentIconButton)?.image = nil
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.isExcludedFromWindowsMenu = true
        logger.info("🌅  FruitBasket \(self.versionString) started")
    }

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		if let mainWindow = window {
			mainWindow.makeKeyAndOrderFront(self)
		}
		return false
	}

    func applicationWillTerminate(_ aNotification: Notification) {
        logger.info("🌃  FruitBasket \(self.versionString) terminating")
        self.contentBasedChunkStore.close()
        logger.info("🌃  FruitBasket \(self.versionString) terminated")
    }

    func serverChangeReceived() async {
        await updateItemCount()
        let entries = domainEntries
        async { await notifier.serverChangeReceived(entries) }
    }

    @IBAction func toggleAuthenticationIgnoreStatus(_ sender: AnyObject) {
        let entries = domainEntries
        // Assign to force an update on the table.
        domainEntries = entries
        async { await notifier.signalItems(entries) }
     }

    @IBAction func changeAccountQuota(_ sender: AnyObject) {
        // The quota is general for all domains so signaling the resolved error for all domains.
        for entry in domainEntries {
            guard let manager = NSFileProviderManager(for: entry.domain) else { return }
            self.logger.info(
"""
🔆 notifying \(entry.domain.prettyDescription) for account quota change, \
now: \(String(describing: UserDefaults.sharedContainerDefaults.accountQuota))
""")
            async {
                do {
                    try await manager.signalErrorResolved(NSFileProviderError(.insufficientQuota))
                    self.logger.info("✅ succeeded to signal insufficientQuota error as resolved for \(entry.domain.prettyDescription)")
                } catch  let error as NSError {
                    self.logger.error("❌ failed to signal insufficientQuota error as resolved for \(entry.domain.prettyDescription): \(error)")
                }
            }
        }
    }

    var knownDomains = [NSFileProviderDomain]()
    var knownAccounts = [AccountService.Account]()

    @MainActor
    func updateDomains(_ domains: ([NSFileProviderDomain], [AccountService.Account])) async {
        knownDomains = domains.0
        knownAccounts = domains.1

        await updateItemCount()
        updateListeners()
    }

    func findNextFruit() -> String {
        let fruitNames = ["🥑", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍍", "🍑",
                          "🍏", "🍅", "🥥", "🥝", "🥦", "🥬", "🌶", "🥕", "🍆", "🥐", "🍄"]
        func fruitName(_ num: Int) -> String {
            let index = num % fruitNames.count
            if num > fruitNames.count {
                return "\(fruitNames[index]) - \((index / fruitNames.count) + 1)"
            }
            return fruitNames[index]
        }
        var num = 0
        while domainEntries.contains(where: { $0.displayName == fruitName(num) }) {
            num += 1
        }
        return fruitName(num)
    }

    @IBOutlet var domainArrayController: NSArrayController!
    @IBAction func addDomain(_ sender: AnyObject?) {
        let new = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: NSUUID().uuidString), displayName: findNextFruit())

        let controller = EditDomainWindowController(new, accountConnection, knownDomains, knownAccounts)
        guard let window = controller.window else { fatalError() }
        controller.delegate = self

        self.window.beginSheet(window) { modalResponse in
            _ = controller
        }
    }

    @IBAction func removeDomain(_ sender: AnyObject?) {
        guard let domains = domainArrayController.selectedObjects as? [DomainEntry] else { return }
        guard let domain = domains.first else { fatalError() }
        let controller = RemoveDomainWindowController(domain.domain, accountConnection, spinner: spinner)

        guard let window = controller.window else { fatalError() }
        controller.delegate = self

        self.window.beginSheet(window) { modalResponse in
            _ = controller
        }
    }

    @IBAction func blockedProcessesClicked(_ sender: NSButton) {
        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: BlockedProcessesEditorView())
        popover.behavior = .transient
        popover.show(relativeTo: NSRect(), of: sender, preferredEdge: .maxX)
    }

    @IBAction func editDomain(_ sender: Any) {
        guard let domains = domainArrayController.selectedObjects as? [DomainEntry] else { fatalError() }
        guard let domain = domains.first else { fatalError() }
        let controller = EditDomainWindowController(domain.domain, accountConnection, knownDomains, knownAccounts)
        guard let window = controller.window else { fatalError() }
        controller.delegate = self

        self.window.beginSheet(window) { modalResponse in
            _ = controller
        }
    }

    @IBAction func toggleDomainConnection(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        let manager = NSFileProviderManager(for: domain)!

        async {
            if domain.isDisconnected {
                do {
                    try await manager.reconnect()
                } catch let error as NSError {
                    self.logger.error("❌ failed to reconnect \(entry.domain.prettyDescription): \(error)")
                }
            } else {
                do {
                    try await manager.disconnect(reason: "Disconnected in UI", options: .temporary)
                } catch let error as NSError {
                    self.logger.error("❌ failed to disconnect \(entry.domain.prettyDescription): \(error)")
                }
            }
        }
    }

    @IBAction func toggleDomainHidden(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        domain.isHidden.toggle()

        async {
            do {
                try await NSFileProviderManager.add(domain)
            } catch {

            }
        }
    }

    @IBAction func toggleShouldWarnOnImportingToFolder(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else {
            return
        }

        let domain = entry.domain
        UserDefaults.sharedContainerDefaults.toggleFeatureFlag(for: domain.identifier, featureFlag: FeatureFlags.shouldWarnOnImportingToFolder)
        self.signalWorkingSet(domain: domain)
    }

    @IBAction func togglePinnedFeatureEnabled(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else {
            return
        }

        let domain = entry.domain
        UserDefaults.sharedContainerDefaults.toggleFeatureFlag(for: domain.identifier, featureFlag: FeatureFlags.pinnedFeatureFlag)
        self.signalWorkingSet(domain: domain)
    }

    private func signalWorkingSet(domain: NSFileProviderDomain) {
        let seconds = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            guard let manager = NSFileProviderManager(for: domain) else {
                return
            }

            async {
                do {
                    try await manager.signalEnumerator(for: .workingSet)
                } catch let error as NSError {
                    self.logger.error("❌ failed to signal working set for \(domain.prettyDescription): \(error)")
                }
            }
        }
    }

    @IBAction func toggleDomainAuthenticated(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        async {
            do {
                let resp = try await self.accountConnection.makeJSONCall(AccountService.ListAccountParameter())
                guard let account = resp.accounts.first(where: { $0.identifier == domain.identifier.rawValue }) else {
                    throw CommonError.internalError
                }
                let secret = account.secret

                let defaults = UserDefaults.sharedContainerDefaults
                if defaults.secret(for: domain.identifier) != secret {
                    defaults.set(secret: secret, for: domain.identifier)
                } else {
                    defaults.set(secret: nil, for: domain.identifier)
                }

                guard let manager = NSFileProviderManager(for: entry.domain) else {
                    return
                }
                self.logger.info("🔆 notifying \(entry.domain.prettyDescription) for auth status change")
                if entry.authenticated {
                    do {
                        try await manager.signalErrorResolved(NSFileProviderError(.notAuthenticated))
                    } catch let error as NSError {
                        self.logger.error("❌ failed to signal authentication error resolved for \(entry.domain.prettyDescription): \(error)")
                    }
                } else {
                    // Notify the workingSet because FileProvider needs to save the new unauthenticated state.
                    do {
                        try await manager.signalEnumerator(for: .workingSet)
                    } catch let error as NSError {
                        self.logger.error("❌ failed to signal working set for \(entry.domain.prettyDescription): \(error)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.presentError(error)
                }
            }

        }
    }

    @IBAction func resetSyncAnchor(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        async {
            do {
                _ = try await self.accountConnection.makeJSONCall(AccountService.ResetSyncAnchorParameter(identifier: domain.identifier.rawValue))
                self.logger.debug("Sync anchor has been reset")
            } catch let error as NSError {
                self.logger.error("Cannot reset sync anchor: \(error)")
            }
        }
    }

    @IBAction func toggleDomainOffline(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        async {
            do {
                let param = AccountService.SetOfflineModeParameter(identifier: domain.identifier.rawValue, enableOffline: !entry.offline)
                let resp = try await self.accountConnection.makeJSONCall(param)
                let status = resp.offline ? "Offline" : "Online"
                self.logger.debug("Domain offline status changed to \(status)")
            } catch let error as NSError {
                self.logger.error("Cannot change domain offline status\(error)")
            }
        }
    }
    
    @IBAction func showPendingItems(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        EnumerationWindowController(domain, .pending).showWindow(nil)
    }

    @IBAction func showUserInteractionSuppressions(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        let editor = UserInteractionSuppressionEditor(domainIdentifier: domain.identifier, domainDisplayName: domain.displayName)
        UserInteractionSuppressionWindowController(editor).showWindow(nil)
    }

    @IBAction func showMaterializedItems(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        EnumerationWindowController(domain, .materialized).showWindow(nil)
    }

    @IBAction func bumpDomainVersion(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain

        UserDefaults.sharedContainerDefaults.bumpDomainVersion(for: domain.identifier)

        self.signalWorkingSet(domain: domain)
    }

    @IBAction func reimportDomain(_ sender: NSMenuItem) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first,
            let manager = NSFileProviderManager(for: entry.domain) else {
                return
            }

        async {
            do {
                try await manager.reimportItems(below: .rootContainer)
            } catch let error as NSError {
                self.logger.error("❌ failed to issue reimport \(error)")
            }
        }
    }

    @IBAction func domainDoubleClick(_ sender: NSTableView) {
        guard let entries = domainArrayController.selectedObjects as? [DomainEntry],
            let entry = entries.first else { return }
        let domain = entry.domain
        guard let manager = NSFileProviderManager(for: domain) else { return }
        async {
            do {
                let url = try await manager.getUserVisibleURL(for: NSFileProviderItemIdentifier.rootContainer)
                let stop = url.startAccessingSecurityScopedResource()
                defer {
                    if stop {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                NSWorkspace().selectFile(nil, inFileViewerRootedAtPath: url.path)
            } catch let error as NSError {
                self.logger.error("❌ failed to get user-visible url \(error)")
            }
        }
    }

    @IBAction func askUserToEnable(_ sender: NSMenuItem) {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    func updateListeners() {
        domainEntries = knownDomains.compactMap { domain in
            if let port = domain.identifier.port, port != builtinServer.port {
                logger.info("domain \(String(describing: domain.identifier)) isn't running on main app port, not adding backend")
                return DomainEntry(domain: domain, account: nil, uploadProgress: nil, downloadProgress: nil)
            }
            if let associated = knownAccounts.first(where: { $0.identifier == domain.identifier.rawValue }) {
                let manager = NSFileProviderManager(for: domain)!
                manager.signalErrorResolved(NSFileProviderError(.serverUnreachable)) { _ in }

                return DomainEntry(domain: domain, account: associated, uploadProgress: manager.globalProgress(for: .uploading),
                                   downloadProgress: manager.globalProgress(for: .downloading))
            }
            logger.info("domain \(String(describing: domain.identifier)) doesn't have a corresponding account, removing domain")
            NSFileProviderManager.remove(domain) { _ in }
            return nil
        }
    }
}

class MillisecondTransformer: ValueTransformer {
    open override func transformedValue(_ value: Any?) -> Any? {
        guard let val = value as? NSNumber else { return "0 ms" }
        return "\(val.intValue) ms"
    }
}

class PercentageTransformer: ValueTransformer {
    open override func transformedValue(_ value: Any?) -> Any? {
        guard let val = value as? NSNumber else { return "0 %" }
        return "\(val.intValue) %"
    }
}

