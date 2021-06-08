/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The database for managing the state of items on the cloud file server.
*/

import Foundation
import SQLite
import os.log
import Common


let itemsTable = Table("items")
let idKey = Expression<DomainService.ItemIdentifier>("id")
let nameKey = Expression<String>("name")
let revKey = Expression<Int64>("metadataVersion")
let contentRevKey = Expression<Int64>("contentVersion")
let contentStorageTypeKey = Expression<DomainService.ContentStorageType>("contentStorageType")
let parentKey = Expression<DomainService.ItemIdentifier>("parent")
let deletedKey = Expression<Bool>("deleted")
let sizeKey = Expression<Int64>("size")
let thumbnailKey = Expression<Data>("thumbnail")
let typeKey = Expression<DomainService.EntryType>("type")
let resourceForkKey = Expression<Bool>("resourceFork")
let metadataKey = Expression<DomainService.EntryMetadata>("metadata")

let contentsTable = Table("contents")
let contentsKey = Expression<Data>("contents")
let contentDateKey = Expression<Date>("date")
let conflictKey = Expression<Bool>("conflict")
let originatorNameKey = Expression<String>("originatorName")
let baseRevKey = Expression<Int64>("baseVersion")
let externalSizeKey = Expression<Int64>("externalSize")
let externalIdentifierKey = Expression<Int64>("externalIdentifier")

let accountTable = Table("accounts")
let accountKey = Expression<Int64>("account")
let rootItemKey = Expression<DomainService.ItemIdentifier>("rootItem")
let accountIdentifierKey = Expression<String>("accountIdentifier")
let accountNameKey = Expression<String>("accountName")
let accountSecretKey = Expression<String>("secret")
let tokenCheckNumberKey = Expression<Int64>("tokenCheckNumber")
let accountFlagsKey = Expression<Int>("flags")

let unlockTable = Table("unlock")
let enumerationIndexKey = Expression<Int64>("enumerationIndex")
let expiryKey = Expression<Date>("expiry")
let lockOwnerKey = Expression<String>("owner")

let simulatedErrorTable = Table("simulated_errors")
let errorDomainKey = Expression<String>("errorDomain")
let errorCodeKey = Expression<Int64>("errorCode")
let errorLocalizedDescriptionKey = Expression<String?>("errorLocalizedDescription")
let accessTypeKey = Expression<DomainService.SimulatedError.AccessType>("accessType")

let pushTokenTable = Table("push_tokens")
let pushTokenKey = Expression<String>("token")
let pushTopicKey = Expression<String>("topic")

extension Connection {
    public var userVersion: Int {
        get { return Int(try! scalar("PRAGMA user_version") as! Int64) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}

@propertyWrapper
struct Synchronized<T> {
    class Lock {
    }
    let lock = Lock()
    private var innerValue: T

    init(wrappedValue value: T) {
        innerValue = value
    }
    var wrappedValue: T {
        set {
            synchronized(lock) {
                innerValue = newValue
            }
        }
        get {
            synchronized(lock) {
                return innerValue
            }
        }
    }
}

public class ItemDatabase {
    enum ConflictResolutionStrategy {
        case reject
        case bounce
        case merge
    }

    enum SignalStrategy {
        case item
        case parent
    }

    public typealias Version = DomainService.Version
    public typealias Entry = DomainService.Entry
    public typealias EntryMetadata = DomainService.EntryMetadata
    public typealias ItemIdentifier = DomainService.ItemIdentifier
    public typealias ConflictVersion = DomainService.ConflictVersion
    public typealias Account = AccountService.Account

    let conn: Connection
    public typealias ChangeListener = (ItemIdentifier) -> Void
    public typealias AccountListener = ([AccountService.Account]) -> Void

    internal var currentMaximumRank: Int64 = 0

    internal class ListenerWrapper<Listener>: Equatable {
        static func == (lhs: ItemDatabase.ListenerWrapper<Listener>, rhs: ItemDatabase.ListenerWrapper<Listener>) -> Bool {
            lhs === rhs
        }

        let listener: Listener
        init(_ listener: Listener) {
            self.listener = listener
        }
    }
    internal var changeListeners = [ListenerWrapper<ChangeListener>]()
    internal var accountListeners = [ListenerWrapper<AccountListener>]()
    internal var updateHooks:[((_ operation: Connection.Operation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?] = []

    internal let dbVersion = 38
    internal let reservedItemCount = 10
    internal let contentLocation: URL?
    @Synchronized internal var usedQuota: Int64 = 0

    let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "db")

    func notifyChangeListeners(_ id: ItemIdentifier) {
        changeListeners.forEach { wrapper in
            wrapper.listener(id)
        }
    }

    public init(location: URL? = nil, changeListener: @escaping ChangeListener, accountListener: @escaping AccountListener = { _ in }) throws {
        changeListeners.append(ListenerWrapper(changeListener))
        accountListeners.append(ListenerWrapper(accountListener))
        if let location = location {
            if UserDefaults.sharedContainerDefaults.contentStoredInline {
                contentLocation = nil
            } else {
                contentLocation = location.deletingLastPathComponent().appendingPathComponent("contents", isDirectory: true)
            }
            conn = try Connection(.uri(location.absoluteString))
        } else {
            conn = try Connection(.temporary)
            contentLocation = nil
        }

        if dbVersion != conn.userVersion {
            logger.info("db version changed (\(self.conn.userVersion) to \(self.dbVersion), dropping database")
            _ = try? conn.run(contentsTable.dropIndex(idKey, ifExists: true))
            _ = try? conn.run(itemsTable.dropIndex(nameKey, parentKey, ifExists: true))
            _ = try? conn.run(itemsTable.dropIndex(rankKey, ifExists: true))
            _ = try? conn.run(itemsTable.drop())
            _ = try? conn.run(accountTable.drop())
            _ = try? conn.run(contentsTable.drop())
            _ = try? conn.run(unlockTable.drop())
            _ = try? conn.run(simulatedErrorTable.drop())
            _ = try? conn.run(pushTokenTable.drop())

            if let contentLocation = contentLocation {
                try? FileManager().removeItem(at: contentLocation)
            }

            try conn.run(itemsTable.create {
                $0.column(idKey, primaryKey: true)
                $0.column(nameKey, collate: .binary)
                $0.column(parentKey)
                $0.column(revKey, defaultValue: 0)
                $0.column(contentRevKey, defaultValue: 0)
                $0.column(deletedKey, defaultValue: false)
                $0.column(thumbnailKey, defaultValue: Data())
                $0.column(rankKey)
                $0.column(typeKey)
                $0.column(resourceForkKey, defaultValue: false)
                $0.column(metadataKey, defaultValue: EntryMetadata.empty)
            })

            try conn.run(contentsTable.create {
                $0.column(externalIdentifierKey, primaryKey: true)
                $0.column(idKey, references: itemsTable, idKey)
                $0.column(contentStorageTypeKey, defaultValue: DomainService.ContentStorageType.inline)
                $0.column(contentRevKey, defaultValue: 0)
                $0.column(baseRevKey)
                $0.column(contentsKey, defaultValue: Data())
                $0.column(externalSizeKey, defaultValue: 0)
                $0.column(conflictKey, defaultValue: false)
                $0.column(contentDateKey)
                $0.column(originatorNameKey)
            })

            try conn.run(accountTable.create {
                $0.column(accountKey, primaryKey: true)
                $0.column(rootItemKey, references: itemsTable, idKey)
                $0.column(accountIdentifierKey, unique: true)
                $0.column(accountNameKey)
                $0.column(accountSecretKey, collate: .binary)
                $0.column(tokenCheckNumberKey)
                $0.column(accountFlagsKey)
            })

            try conn.run(unlockTable.create {
                $0.column(idKey, references: itemsTable, idKey)
                $0.column(expiryKey)
                $0.column(enumerationIndexKey, unique: true)
                $0.column(lockOwnerKey, collate: .binary)
            })

            try conn.run(simulatedErrorTable.create {
                $0.column(idKey)
                $0.column(errorDomainKey, collate: .binary)
                $0.column(errorCodeKey)
                $0.column(errorLocalizedDescriptionKey)
                $0.column(accessTypeKey)
            })

            try conn.run(pushTokenTable.create {
                $0.column(pushTokenKey)
                $0.column(pushTopicKey)
                $0.column(expiryKey)
            })

            conn.userVersion = dbVersion

            // Reserve some item ids. These item ids should never be handed out
            // to a provider, but are used on the provider side (0 is the root,
            // 1 is the trash). The provider's ids are translated during encoding
            // and decoding.
            for i in 0..<reservedItemCount {
                try conn.run(itemsTable.insert(idKey <- ItemIdentifier(Int64(i)), nameKey <- "reserved", parentKey <- 0, rankKey <- allocateNewRank(),
                                               typeKey <- .file, deletedKey <- true))
            }
        }

        try conn.run(itemsTable.createIndex(nameKey, parentKey, ifNotExists: true))
        try conn.run(itemsTable.createIndex(rankKey, ifNotExists: true))
        try conn.run(contentsTable.createIndex(idKey, ifNotExists: true))

        if let contentLocation = contentLocation {
            try FileManager().createDirectory(at: contentLocation, withIntermediateDirectories: true, attributes: nil)
        }
        usedQuota = try computeUsedQuota(from: 0)
        currentMaximumRank = try conn.scalar(itemsTable.select(rankKey.max))!

        conn.updateHook { [weak self] operation, db, table, rowid in
            guard let strongSelf = self else { return }
            strongSelf.updateHooks.forEach { hook in
                if let hook = hook {
                    hook(operation, db, table, rowid)
                }
            }
        }
    }
    
    func allocateNewRank() -> Int64 {
        synchronized(self) {
            currentMaximumRank += 1
            return currentMaximumRank
        }
    }

    func latestRank() -> Int64 {
        synchronized(self) {
            return currentMaximumRank
        }
    }

    public func allRoots() throws -> [Entry] {
        let roots = itemsTable.filter(typeKey == .root && deletedKey == false)
        return try conn.prepare(roots).compactMap({ Entry($0, self) })
    }
    
    func conflictVersions(item: ItemIdentifier) throws -> [ConflictVersion] {
        let rows = try conn.prepare(contentsTable.filter(idKey == item))

        return rows.map(ConflictVersion.init)
    }

    func keep(versions: [Int64], of item: ItemIdentifier, baseVersion: Version) throws {
        try conn.transaction {
            guard let baseItem = try conn.pluck(itemsTable.where(idKey == item && deletedKey == false)) else {
                throw CommonError.itemNotFound(item)
            }
            let entry = Entry(baseItem, self)
            guard entry.revision == baseVersion else {
                throw CommonError.wrongRevision(entry)
            }
            let originalName = (baseItem[nameKey] as NSString).deletingPathExtension
            let pathExtension = (baseItem[nameKey] as NSString).pathExtension

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium

            for revision in versions {
                if revision == baseItem[contentRevKey] {
                    // On currently alive item, update the rank and metadata revision.
                    try conn.run(itemsTable.where(idKey == item).update(rankKey <- allocateNewRank(), revKey++))
                    continue
                }
                let filter = contentsTable.filter(idKey == item && contentRevKey == revision)
                guard let versionEntry = try conn.pluck(filter) else {
                    continue
                }
                // Make a new item name.
                let name: String
                if versions.count == 1 {
                    // If only one version is being kept, use original name.
                    name = baseItem[nameKey]
                } else {
                    // When keeping multiple versions, name them according to their origin.
                    name = "\(originalName) (\(versionEntry[originatorNameKey]))" +
                        " at \(dateFormatter.string(from: versionEntry[contentDateKey])).\(pathExtension)"
                }
                // Insert a new item with a copy of the existing item's properties.
                let newItem = ItemIdentifier(try conn.run(itemsTable.insert(parentKey <- baseItem[parentKey], typeKey <- baseItem[typeKey],
                                                                            nameKey <- name, metadataKey <- baseItem[metadataKey],
                                                                            contentRevKey <- revision, rankKey <- allocateNewRank() )))
                // Associate the existing content version with it.
                try conn.run(filter.update(idKey <- newItem, conflictKey <- false))
            }

            // If the array of versions does not contain the alive item's version, remove it.
            if !versions.contains(where: { (revision) -> Bool in
                revision == baseItem[contentRevKey]
            }) {
                try delete(item: item, revision: nil, recursive: true, transaction: false)
            }
            // Remove all remaining conflicts.
            try conn.run(contentsTable.filter(idKey == item && conflictKey == true).delete())
            // Finally, signal the parent.
            notifyChangeListeners(baseItem[parentKey])
        }
    }

    static var batchSize: Int {
        UserDefaults.sharedContainerDefaults.batchSize
    }

    internal func recursiveQueryWithFilter<T>(_ parent: ItemIdentifier, filter: Expression<Bool>, limit: Int,
                                              order: Expression<T>) throws -> Statement {
        let statement = try conn.prepare("""
            SELECT *
            FROM items
            WHERE \(filter.asSQL())
            AND (?) IN (WITH RECURSIVE parent(n) AS (
                                                SELECT items.parent
                                                UNION ALL
                                                SELECT items.parent
                                                FROM parent
                                                INNER JOIN  items ON items.id = parent.n
                                                WHERE items.id != items.parent)
                                         SELECT n FROM parent)
            ORDER BY \(order.asSQL()) ASC LIMIT ?
            """, parent.id, limit)
        return statement
    }

    internal func simpleQueryWithFilter<T>(_ parent: ItemIdentifier, filter: Expression<Bool>, limit: Int, order: Expression<T>) throws -> Statement {
        let statement = try conn.prepare("""
            SELECT * FROM items WHERE (\(parentKey.asSQL()) = (?)) AND \(filter.asSQL()) ORDER BY \(order.asSQL()) ASC LIMIT (?)
            """, parent.id, limit)
        return statement
    }

    func listFiles(parent: ItemIdentifier, cursor: Int64, recursive: Bool,
                   batchSize: Int = ItemDatabase.batchSize) throws -> (entries: [Entry], cursor: Int64?) {
        try checkSimulatedError(for: parent, .read)
        return try conn.transaction {
            let expr = deletedKey == false && rowid > cursor
            let statement: Statement
            if recursive {
                statement = try recursiveQueryWithFilter(parent, filter: expr, limit: batchSize, order: rowid)
            } else {
                statement = try simpleQueryWithFilter(parent, filter: expr, limit: batchSize, order: rowid)
            }
            let ret = statement.map({ RowWrapper(statement.columnNames, $0) })
            let newCursor = ret.reduce(Int64(0)) { res, row in
                let id = row[idKey].id
                return res > id ? res : id
            }
            return (ret.map({ Entry($0, self) }), !ret.isEmpty ? newCursor : nil)
        }
    }

    func listChanges(parent: ItemIdentifier, rank: Int64, recursive: Bool,
                     batchSize: Int = ItemDatabase.batchSize) throws -> (entries: [Entry], moreComing: Bool, rank: Int64) {
        try checkSimulatedError(for: parent, .read)
        return try conn.transaction {
            let expr = rankKey > rank
            let statement: Statement
            if recursive {
                statement = try recursiveQueryWithFilter(parent, filter: expr, limit: batchSize, order: rankKey)
            } else {
                statement = try simpleQueryWithFilter(parent, filter: expr, limit: batchSize, order: rankKey)
            }
            let ret = statement.map({ RowWrapper(statement.columnNames, $0) })
            let newRank: Int64
            if ret.isEmpty {
                newRank = latestRank()
            } else {
                newRank = ret.reduce(Int64(0)) { res, row in
                    let rank = row[rankKey]
                    return res > rank ? res : rank
                }
            }
            return (ret.map({ Entry($0, self) }), !ret.isEmpty, newRank)
        }
    }

    func delete(item identifier: ItemIdentifier, revision: Version?, recursive: Bool) throws {
        try delete(item: identifier, revision: revision, recursive: recursive, transaction: true)
    }

    fileprivate func delete(item identifier: ItemIdentifier, revision: Version?, recursive: Bool, transaction: Bool) throws {
        var externalIdentifiers = [Int64]()
        var sizeToBeDeleted: Int64 = 0
        func delete(_ item: ItemIdentifier, _ parent: ItemIdentifier) throws {
            if contentLocation != nil {
                for row in try conn.prepare(contentsTable.filter(idKey == item)) {
                    externalIdentifiers.append(row[externalIdentifierKey])
                }
            }
            try checkSimulatedError(for: item, .write)
            try checkSimulatedError(for: parent, .write)
            sizeToBeDeleted += try (conn.scalar(contentsTable.filter(idKey == item).select(externalSizeKey.sum)) ?? 0)

            try conn.run(contentsTable.filter(idKey == item).update(contentStorageTypeKey <- .inline, contentsKey <- Data(),
                                                                    externalSizeKey <- 0, originatorNameKey <- ""))
            try conn.run(itemsTable.filter(idKey == item).update(thumbnailKey <- Data(), nameKey <- "", metadataKey <- EntryMetadata.empty,
                                                                 deletedKey <- true, revKey++, contentRevKey++, rankKey <- allocateNewRank()))
            try conn.run(simulatedErrorTable.filter(idKey == item).delete())
            try updateAndSignal(itemIds: [parent], signal: .item)
        }

        func recursiveDeleteChildren(item identifier: ItemIdentifier) throws {
            let filter = itemsTable.filter(parentKey == identifier && deletedKey == false)
            let rows = try conn.prepare(filter)

            for row in rows {
                if row[idKey] == identifier {
                    continue
                }
                try recursiveDeleteChildren(item: row[idKey])
                try delete(row[idKey], row[parentKey])
            }
        }

        let block = {
            let item = itemsTable.filter(identifier == idKey && deletedKey == false)

            guard let row = try self.conn.pluck(item) else { throw CommonError.itemNotFound(identifier) }
            if let revision = revision {
                if !UserDefaults.sharedContainerDefaults.ignoreContentVersionOnDeletion {
                    // Always ignore the metadata version here; if a file is deleted, and then renamed somewhere else, the deletion wins.
                    guard revision.content == Version(row).content else { throw CommonError.deletionRejected(Entry(row, self)) }
                }
            }
            self.notifyChangeListeners(row[parentKey])
            if recursive {
                try recursiveDeleteChildren(item: identifier)
            }

            try delete(identifier, row[parentKey])
        }

        if transaction {
            try conn.transaction(block: block)
        } else {
            try block()
        }
        if let contentLocation = contentLocation {
            for ext in externalIdentifiers {
                do {
                    try FileManager().removeItem(at: contentLocation.appendingPathComponent("\(ext)"))
                } catch let error as NSError {
                    logger.error("failed to remove contents of item \(ext): \(error)")
                }
            }
            usedQuota = max(usedQuota - sizeToBeDeleted, 0)
        }
    }

    func computeUsedQuota(from root: ItemIdentifier) throws -> Int64 {
        let joinedTable = contentsTable.join(itemsTable,
                                             on: (itemsTable[idKey] == contentsTable[idKey]) &&
                                             (itemsTable[contentRevKey] == contentsTable[contentRevKey]))
        if let totalSize = try conn.scalar(joinedTable.select(externalSizeKey.sum)) {
            return totalSize
        } else {
            logger.error("failed to compute total size, initializing used quota to 0")
            return 0
        }
    }

    public var itemCount: Int {
        return try! conn.scalar(itemsTable.filter(deletedKey == false).count)
    }

    // Recursively select all path components of an item identifier.
    internal func pathQuery(_ ident: ItemIdentifier) throws -> Statement {
        let statement = try conn.prepare("""
            WITH RECURSIVE parent_of(n) AS (
            SELECT \(parentKey.asSQL()) FROM items WHERE (\(idKey.asSQL()) = (?))
            UNION
            SELECT \(parentKey.asSQL()) FROM items, parent_of
            WHERE items.\(idKey.asSQL()) = parent_of.n
            )
            SELECT * FROM items WHERE \(idKey.asSQL()) IN parent_of
            UNION
            SELECT * FROM items WHERE id = (?)
            """, ident.id, ident.id)
        return statement
    }

    enum ChangeType {
        case create
        case modifyMetadata
        case modifyContent
    }

    func conflictStrategy(for existingItem: Entry, _ type: DomainService.EntryType, _ changeType: ChangeType) throws -> ConflictResolutionStrategy {
        if existingItem.type != type {
            return .bounce
        }

        switch type {
        case .folder:
            if changeType == .create {
                return .merge
            } else {
                return .reject
            }
        case .alias, .symlink:
            if changeType == .create {
                return .merge
            }
            return .bounce
        case .file:
            let statement = try pathQuery(existingItem.id)
            let rows = statement.map({ RowWrapper(statement.columnNames, $0) })

            if rows.count >= 2,
                rows[1][nameKey] == ".Trash" {
                // The trash always bounces.
                return .bounce
            }
            if changeType == .create {
                for row in rows {
                    if row[nameKey].hasPrefix(".") {
                        // Creating a new item inside a hidden subfolder result in a merge.
                        return .merge
                    }
                }
            }
                // Moves always bounce (even in hidden subfolders).
            return .bounce
        case .root:
            fatalError("shouldn't happen")
        }
    }

    // Update the lock for the specified index.
    func updateLock(for identifier: ItemIdentifier, _ expiry: Date, _ enumerationIndex: Int64, owner: String) throws {
        try conn.run(unlockTable.insert(or: .replace, enumerationIndexKey <- enumerationIndex, expiryKey <- expiry,
                                        idKey <- identifier, lockOwnerKey <- owner))
        try updateAndSignal(itemIds: [identifier], signal: .parent)
    }

    // Remove a lock for the specified index. If no index is given, remove all locks.
    func removeLock(for identifier: ItemIdentifier, _ enumerationIndex: Int64?) throws {
        if let index = enumerationIndex {
            try conn.run(unlockTable.where(enumerationIndexKey == index && idKey == identifier).delete())
        } else {
            try conn.run(unlockTable.where(idKey == identifier).delete())
        }
        try updateAndSignal(itemIds: [identifier], signal: .parent)
    }

    func allLocks() throws -> [DomainService.ListLocksReturn.Lock] {
        return try conn.prepare(unlockTable.selectStar()).map { row in
            let id = row[idKey]
            let en = row[enumerationIndexKey]
            let ti = row[expiryKey]
            let ow = row[lockOwnerKey]
            return DomainService.ListLocksReturn.Lock(itemIdentifier: id, enumerationIndex: en, timeout: ti, owner: ow)
        }
    }

    // Bump the rank on the specified items.
    internal func updateAndSignal(itemIds: [ItemIdentifier], signal strategy: SignalStrategy) throws {
        for itemId in itemIds {
            let item = itemsTable.filter(itemId == idKey)

            let updated = try conn.run(item.update(rankKey <- allocateNewRank()))

            guard updated == 1 else {
                throw CommonError.itemNotFound(itemId)
            }

            guard let entry = try conn.pluck(item) else { continue }
            switch strategy {
            case .item:
                notifyChangeListeners(entry[idKey])
            case .parent:
                notifyChangeListeners(entry[parentKey])
            }
        }
    }

    // Remove all locks before a specified date, signal all corresponding items, and return the date for the next check.
    func expireLocks(before expiry: Date = Date()) throws -> Date? {
        try conn.transaction {
            let expired = unlockTable.filter(expiryKey < expiry)
            let expiredIds = expired.select(distinct: idKey)
            let itemIds = try conn.prepare(expiredIds).map({ $0[idKey] })
            try conn.run(expired.delete())
            if !itemIds.isEmpty {
                logger.info("🗝 locks on \(itemIds) expired, signalling")
                try updateAndSignal(itemIds: itemIds, signal: .parent)
            }

            guard let oldest = try conn.scalar(unlockTable.select(expiryKey.min)) else {
                return nil
            }
            return oldest
        }
    }

    typealias SimulatedError = DomainService.SimulatedError

    func checkSimulatedError(for item: ItemIdentifier, _ accessType: SimulatedError.AccessType) throws {
        if let error = try conn.pluck(simulatedErrorTable.filter(idKey == item && accessType == accessTypeKey)) {
            throw CommonError.simulatedError(error[errorDomainKey], Int(error[errorCodeKey]), error[errorLocalizedDescriptionKey])
        }
    }

    func simulatedErrors() throws -> [ItemIdentifier: [SimulatedError.AccessType: SimulatedError]] {
        var ret = [ItemIdentifier: [SimulatedError.AccessType: SimulatedError]]()
        for err in try conn.prepare(simulatedErrorTable.selectStar()) {
            let error = SimulatedError(domain: err[errorDomainKey], code: Int(err[errorCodeKey]),
                                       localizedDescription: err[errorLocalizedDescriptionKey])
            var entry = ret[err[idKey]] ?? [:]
            entry[err[accessTypeKey]] = error
            ret[err[idKey]] = entry
        }
        return ret
    }

    func setSimulatedError(_ identifier: ItemIdentifier, _ error: SimulatedError?, _ accessType: SimulatedError.AccessType) throws {
        if let error = error {
            try conn.transaction {
                try conn.run(simulatedErrorTable.filter(idKey == identifier && accessTypeKey == accessType).delete())
                try conn.run(simulatedErrorTable.insert(idKey <- identifier,
                                                        errorDomainKey <- error.domain,
                                                        errorCodeKey <- Int64(error.code),
                                                        errorLocalizedDescriptionKey <- error.localizedDescription,
                                                        accessTypeKey <- accessType))
            }
        } else {
            try conn.run(simulatedErrorTable.filter(idKey == identifier).delete())
        }
    }

    func addUpdateHook(_ callback: ((_ operation: Connection.Operation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?) {
        updateHooks.append(callback)
    }

    func refreshPushToken(_ token: DomainService.PushDevice.Token, _ topic: DomainService.PushDevice.PushTopic) throws {
        try conn.transaction {
            try conn.run(pushTokenTable.filter(pushTokenKey == token && pushTopicKey == topic).delete())
            try conn.run(pushTokenTable.insert(pushTokenKey <- token, pushTopicKey <- topic, expiryKey <- Date()))
        }
    }

    func allPushTokens() throws -> [DomainService.PushDevice] {
        try conn.transaction {
            try conn.run(
                pushTokenTable.filter(expiryKey < Date(timeIntervalSinceNow: -DomainService.PushRegistrationParameter.refreshInterval)).delete())

            return try conn.prepare(pushTokenTable.select(*)).map({ DomainService.PushDevice(token: $0[pushTokenKey], topic: $0[pushTopicKey])
            })
        }
    }
}

extension Connection {
    public func transaction<T>(_ mode: TransactionMode = .deferred, block: () throws -> T) throws -> T {
        var ret: T?
        try transaction(.deferred, block: { ret = try block() })
        return ret!
    }
}

extension SQLite.SchemaType {
    func selectStar() -> Self {
        return select(Expression<Void>(literal: "*"))
    }
}
