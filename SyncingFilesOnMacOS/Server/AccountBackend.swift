/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Account specific implementations of the cloud file server APIs.
*/

import Foundation
import os.log
import FileProvider
import Common

public extension NSNotification.Name {
    static let accountsDidChange: NSNotification.Name =
        NSNotification.Name(rawValue: Bundle(for: AccountBackend.self).bundleIdentifier!.appending(".AccountsDidChange"))
}

public class AccountBackend: DispatchBackend {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "accounts")
    public let displayName = "accounts"
    public let encoder = JSONEncoder()
    public let decoder = JSONDecoder()
    public let queue = DispatchQueue(label: "account backend")
    let db: ItemDatabase

    public func checkForDomainApproval(_ headers: [String: String], _ path: String) throws {
    }

    public static func registerCalls(_ dispatch: BackendCallRegistration) {
        dispatch.registerBackendCall(AccountBackend.info)
        dispatch.registerBackendCall(AccountBackend.listAccounts)
        dispatch.registerBackendCall(AccountBackend.createAccount)
        dispatch.registerBackendCall(AccountBackend.removeAccount)
        dispatch.registerBackendCall(AccountBackend.setOfflineMode)
        dispatch.registerBackendCall(AccountBackend.getOfflineMode)
        dispatch.registerBackendCall(AccountBackend.resetSyncAnchor)
    }

    public init(database: ItemDatabase) throws {
        db = database
        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func info(_ param: AccountService.InfoParameter) throws -> AccountService.InfoReturn {
        return AccountService.InfoReturn(standalone: false, itemCount: db.itemCount)
    }

    func listAccounts(_ param: AccountService.ListAccountParameter) throws -> AccountService.ListAccountReturn {
        return AccountService.ListAccountReturn(accounts: try db.allAccounts())
    }

    func createAccount(_ param: AccountService.CreateAccountParameter) throws -> AccountService.CreateAccountReturn {
        let mirroredRoot: DomainService.ItemIdentifier?
        if let mirror = param.mirroringAccount {
            mirroredRoot = try db.account(for: mirror).rootItem.id
        } else {
            mirroredRoot = nil
        }
        if !param.remoteOnly {
            let group = DispatchGroup()

            let domain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: param.identifier), displayName: param.displayName)

            var addError: Error? = nil
            group.enter()
            NSFileProviderManager.add(domain) { error in
                if let error = error as NSError? {
                    self.logger.error("error \(error) adding domain \(param.displayName) for identifier \(param.identifier)")
                    addError = error
                }
                group.leave()
            }
            group.wait()
            if let error = addError {
                switch error {
                case CocoaError.fileWriteFileExists:
                    throw CommonError.accountExists
                default:
                    throw addError!
                }
            }
        }

        _ = try db.setAccountRoot(for: param.identifier, displayName: param.displayName, root: mirroredRoot)
        DistributedNotificationCenter.default.post(Notification(name: NSNotification.Name.accountsDidChange))
        return AccountService.CreateAccountReturn(account: try db.account(for: param.identifier))
    }

    func removeAccount(_ param: AccountService.RemoveAccountParameter) throws -> AccountService.RemoveAccountReturn {

        for identifier in param.identifiers {
            let group = DispatchGroup()
            let domain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: identifier), displayName: "")
            if !param.remoteOnly {
                var outerError: Error? = nil
                group.enter()
                NSFileProviderManager.remove(domain) { error in
                    if let error = error as NSError? {
                        self.logger.error("error \(error) removing domain for identifier \(identifier)")
                        outerError = error
                    }
                    group.leave()
                }
                group.wait()
                if let error = outerError {
                    switch error {
                    case CocoaError.fileWriteFileExists:
                        throw CommonError.accountExists
                    default:
                        throw outerError!
                    }
                }
            }

            try db.removeAccount(for: identifier)
        }
        DistributedNotificationCenter.default().post(Notification(name: NSNotification.Name.accountsDidChange))
        return AccountService.RemoveAccountReturn()
    }

    func setOfflineMode(_ param: AccountService.SetOfflineModeParameter) throws -> AccountService.SetOfflineModeReturn {
        var flags = try db.getAccountFlags(for: param.identifier)
        if param.enableOffline {
            flags.insert(.Offline)
        } else {
            flags.remove(.Offline)
        }
        try db.setAccountFlags(for: param.identifier, flags)

        DistributedNotificationCenter.default.post(Notification(name: NSNotification.Name.accountsDidChange))
        return AccountService.SetOfflineModeReturn(offline: try db.getAccountFlags(for: param.identifier).contains(.Offline))
    }

    func getOfflineMode(_ param: AccountService.GetOfflineModeParameter) throws -> AccountService.GetOfflineModeReturn {
        return AccountService.GetOfflineModeReturn(offline: try db.getAccountFlags(for: param.identifier).contains(.Offline))
    }

    func resetSyncAnchor(_ param: AccountService.ResetSyncAnchorParameter) throws -> AccountService.ResetSyncAnchorReturn {
        let account = try db.account(for: param.identifier)
        // Set the account's root to reset the enumeration and password.
        try db.setAccountRoot(for: param.identifier, displayName: account.displayName, root: account.rootItem.id)
        return AccountService.ResetSyncAnchorReturn()
    }
}
