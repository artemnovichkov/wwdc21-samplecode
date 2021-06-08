/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Parameter and return values for account-related requests to the local HTTP server.
*/

import Foundation
import os.log
import FileProvider


public enum AccountService {
    public struct Account: Codable {
        public struct AccountFlags: OptionSet, Codable {
            public let rawValue: Int

            public static let Offline = AccountFlags(rawValue: 1 << 0)

            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
        }

        public let identifier: String
        public let secret: String
        public let displayName: String
        public let rootItem: DomainService.Entry
        // This is a random number assigned at account creation which is used to test rank expiration.
        public let tokenCheckNumber: Int64
        public var flags: AccountFlags

        public init(identifier: String, secret: String, displayName: String, rootItem: DomainService.Entry, tokenCheckNumber: Int64,
                    flags: Account.AccountFlags) {
            self.identifier = identifier
            self.secret = secret
            self.displayName = displayName
            self.rootItem = rootItem
            self.tokenCheckNumber = tokenCheckNumber
            self.flags = flags
        }
    }

    public struct InfoParameter: JSONParameter {
        public typealias ReturnType = InfoReturn
        public static let endpoint = "account/info"
        public static let method = JSONMethod.POST

        public init() { }
    }

    public struct InfoReturn: Codable {
        public let standalone: Bool
        public let itemCount: Int

        public init(standalone: Bool, itemCount: Int) {
            self.standalone = standalone
            self.itemCount = itemCount
        }
    }

    public struct ListAccountParameter: JSONParameter {
        public typealias ReturnType = ListAccountReturn
        public static let endpoint = "account/list"
        public static let method = JSONMethod.POST

        public init() { }
    }

    public struct ListAccountReturn: Codable {
        public let accounts: [Account]

        public init(accounts: [Account]) {
            self.accounts = accounts
        }
    }

    public struct CreateAccountParameter: JSONParameter {
        public typealias ReturnType = CreateAccountReturn
        public static let endpoint = "account/create"
        public static let method = JSONMethod.POST

        public let displayName: String
        public let identifier: String
        public let mirroringAccount: String?
        public let remoteOnly: Bool

        public init(displayName: String, identifier: String, mirroringAccount: String?, remoteOnly: Bool) {
            self.displayName = displayName
            self.identifier = identifier
            self.mirroringAccount = mirroringAccount
            self.remoteOnly = remoteOnly
        }
    }
    public struct CreateAccountReturn: Codable {
        public let account: Account

        public init(account: Account) {
            self.account = account
        }
    }

    public struct RemoveAccountParameter: JSONParameter {
        public typealias ReturnType = RemoveAccountReturn
        public static let endpoint = "account/remove"
        public static let method = JSONMethod.POST

        public let identifiers: [String]
        public let remoteOnly: Bool

        public init(identifiers: [String], remoteOnly: Bool) {
            self.identifiers = identifiers
            self.remoteOnly = remoteOnly
        }
    }
    public struct RemoveAccountReturn: Codable {
        public init() { }
    }

    public struct SetOfflineModeParameter: JSONParameter {
        public typealias ReturnType = SetOfflineModeReturn
        public static let endpoint = "account/offline/set"
        public static let method = JSONMethod.POST

        public let identifier: String
        public let enableOffline: Bool

        public init(identifier: String, enableOffline: Bool) {
            self.identifier = identifier
            self.enableOffline = enableOffline
        }
    }
    public struct SetOfflineModeReturn: Codable {
        public let offline: Bool

        public init(offline: Bool) {
            self.offline = offline
        }
    }

    public struct GetOfflineModeParameter: JSONParameter {
        public typealias ReturnType = GetOfflineModeReturn
        public static let endpoint = "account/offline/get"
        public static let method = JSONMethod.GET

        public let identifier: String

        public init(identifier: String) {
            self.identifier = identifier
        }
    }
    public struct GetOfflineModeReturn: Codable {
        public let offline: Bool

        public init(offline: Bool) {
            self.offline = offline
        }
    }

    public struct ResetSyncAnchorParameter: JSONParameter {
        public typealias ReturnType = ResetSyncAnchorReturn
        public static let endpoint = "account/anchor/reset"
        public static let method = JSONMethod.GET

        public let identifier: String

        public init(identifier: String) {
            self.identifier = identifier
        }
    }
    public struct ResetSyncAnchorReturn: Codable {
        public init() { }
    }
}
