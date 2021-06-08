/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A database implementation for accounts.
*/

import Foundation
import SQLite
import os.log
import Common

extension AccountService.Account {
    fileprivate init(_ row: ExpressionSubscriptable, _ db: ItemDatabase) throws {
        guard let contentRow = try db.conn.pluck(itemsTable.filter(idKey == row[rootItemKey])) else {
            throw CommonError.itemNotFound(row[rootItemKey])
        }
        self.init(identifier: row[accountIdentifierKey], secret: row[accountSecretKey], displayName: row[accountNameKey],
                  rootItem: DomainService.Entry(contentRow, db), tokenCheckNumber: row[tokenCheckNumberKey],
                  flags: AccountFlags(rawValue: row[accountFlagsKey]))
    }
}

extension ItemDatabase {
    public func allAccounts() throws -> [Account] {
        return try conn.prepare(accountTable.selectStar()).compactMap { try? Account($0, self) }
    }

    public func account(for domainIdentifier: String) throws -> Account {
        let account = accountTable.filter(domainIdentifier == accountIdentifierKey)
        guard let accountRow = try conn.pluck(account) else { throw CommonError.domainNotFound }
        return try Account(accountRow, self)
    }

    // Create or update an account with the passed identifier, and set or create a root item for it.
    @discardableResult
    public func setAccountRoot(for domainIdentifier: String, displayName: String, root: ItemIdentifier?) throws -> Entry {
        try conn.transaction {
            let realRoot: ItemIdentifier
            if let root = root {
                realRoot = root
            } else {
                let now = Date()
                let metadata = EntryMetadata(fileSystemFlags: [.userExecutable, .userWritable, .userReadable], lastUsedDate: nil, tagData: nil,
                                             favoriteRank: nil, creationDate: now, contentModificationDate: now, extendedAttributes: nil,
                                             typeAndCreator: nil, validEntries: nil)
                realRoot = ItemIdentifier(try conn.run(itemsTable.insert(nameKey <- String(domainIdentifier.suffix(12)), parentKey <- 0,
                                                                         rankKey <- allocateNewRank(), typeKey <- .root, metadataKey <- metadata)))
                let item = itemsTable.filter(idKey == realRoot)
                try conn.run(item.update(parentKey <- realRoot))
            }

            let secret = String(UUID().uuidString.suffix(12))
            let tokenCheckNumber = Int64.random(in: 0...Int64.max)
            _ = try conn.run(accountTable.insert(or: .replace, accountIdentifierKey <- domainIdentifier, rootItemKey <- realRoot,
                                                 accountSecretKey <- secret, tokenCheckNumberKey <- tokenCheckNumber, accountNameKey <- displayName,
                                                 accountFlagsKey <- Int(0)))
            guard let entryRow = try conn.pluck(itemsTable.filter(idKey == realRoot)) else { throw CommonError.internalError }
            notifyAccountListeners()
            return Entry(entryRow, self)
        }
    }

    public func removeAccount(for domainIdentifier: String) throws {
        var rootItem: ItemIdentifier?
        try conn.transaction {
            let filter = accountTable.filter(accountIdentifierKey == domainIdentifier)
            guard let row = try conn.pluck(filter) else { return }
            rootItem = row[rootItemKey]
            try conn.run(filter.delete())
        }

        if let foundRoot = rootItem,
            try conn.scalar(accountTable.filter(rootItemKey == foundRoot).count) == 0 {
            try delete(item: foundRoot, revision: nil, recursive: true)
        }
        notifyAccountListeners()
    }

    public func getAccountFlags(for domainIdentifier: String) throws -> Account.AccountFlags {
        let filter = accountTable.filter(accountIdentifierKey == domainIdentifier)
        guard let row = try conn.pluck(filter) else { return [] }
        return Account.AccountFlags(rawValue: row[accountFlagsKey])
    }

    public func setAccountFlags(for domainIdentifier: String, _ flags: Account.AccountFlags) throws {
        try conn.run(accountTable.where(accountIdentifierKey == domainIdentifier).update(accountFlagsKey <- flags.rawValue))
    }

    private func notifyAccountListeners() {
        do {
            let accounts = try self.allAccounts()
            accountListeners.forEach { wrapper in
                wrapper.listener(accounts)
            }
        } catch let error as NSError {
            logger.error("accounts changed, but fetching list of new accounts failed: \(error)")
        }
    }
}
