/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adding database-related extensions for domain service objects.
*/

import Common
import SQLite


extension DomainService.EntryMetadata: Value {
    public static func fromDatatypeValue(_ datatypeValue: Blob) -> DomainService.EntryMetadata {
        return try! JSONDecoder().decode(Self.self, from: Data.fromDatatypeValue(datatypeValue))
    }

    public var datatypeValue: Blob {
        try! JSONEncoder().encode(self).datatypeValue
    }

    public static var declaredDatatype: String {
        return Blob.declaredDatatype
    }
}

extension DomainService.EntryType: Value {
    public static func fromDatatypeValue(_ datatypeValue: String) -> DomainService.EntryType {
        return DomainService.EntryType(rawValue: datatypeValue)!
    }

    public var datatypeValue: String {
        self.rawValue
    }

    public static var declaredDatatype: String {
        return String.declaredDatatype
    }
}

extension DomainService.ItemIdentifier: Value {
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> DomainService.ItemIdentifier {
        return DomainService.ItemIdentifier(datatypeValue)
    }

    public var datatypeValue: Int64 {
        return self.id
    }

    public static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
}

extension DomainService.ContentSha256S: Value {
    public static func fromDatatypeValue(_ datatypeValue: SQLite.Blob) -> DomainService.ContentSha256S {
        let decoder = JSONDecoder()
        let encodedBytes = Data(datatypeValue.bytes)
        return try! decoder.decode(DomainService.ContentSha256S.self, from: encodedBytes)
    }

    public var datatypeValue: SQLite.Blob {
        let encoder = JSONEncoder()
        let encodedBytes = try! encoder.encode(self)
        return SQLite.Blob(bytes: [UInt8](encodedBytes))
    }

    public static var declaredDatatype: String {
        return SQLite.Blob.declaredDatatype
    }
}

extension DomainService.ContentStorageType: Value {
    public static func fromDatatypeValue(_ datatypeValue: SQLite.Blob) -> DomainService.ContentStorageType {
        let decoder = JSONDecoder()
        let encodedBytes = Data(datatypeValue.bytes)
        return try! decoder.decode(DomainService.ContentStorageType.self, from: encodedBytes)
    }

    public var datatypeValue: SQLite.Blob {
        let encoder = JSONEncoder()
        let encodedBytes = try! encoder.encode(self)
        return SQLite.Blob(bytes: [UInt8](encodedBytes))
    }

    public static var declaredDatatype: String {
        return SQLite.Blob.declaredDatatype
    }
}

extension DomainService.SimulatedError.AccessType: Value {
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> DomainService.SimulatedError.AccessType {
        switch datatypeValue {
        case 0:
            return .read
        case 1:
            return .write
        default:
            fatalError()
        }
    }

    public var datatypeValue: Int64 {
        switch self {
        case .read:
            return 0
        case .write:
            return 1
        }
    }

    public static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
}

let rankKey = Expression<Int64>("rank")

extension DomainService.Version {
    init(_ row: ExpressionSubscriptable) {
        self.init(content: row[contentRevKey], metadata: row[revKey])
    }
}

extension String {
    func filenameWithIncrementedBounce() -> String {
        let possibleDoubleExtensions = [
            "gz",
            "bz2",
            "pkgf"
        ]

        let ext = (self as NSString).pathExtension
        let name = (self as NSString).deletingPathExtension

        if possibleDoubleExtensions.contains(ext) {
            return "\(name.filenameWithIncrementedBounce()).\(ext)"
        }

        let number: Int
        let prefix: String
        if let idx = name.lastIndex(where: { $0 == " " }),
            let parsedNumber = Int(name[name.index(after: idx)...]) {
            number = parsedNumber
            prefix = String(name[..<idx])
        } else {
            number = 1
            prefix = name
        }
        if ext.isEmpty {
            return prefix.appending(" \(number + 1)")
        }
        return prefix.appending(" \(number + 1).\(ext)")
    }
}

func contentSizeForContentRow(contentRow: Row) -> Int64 {
    return contentRow[externalSizeKey]
}

extension DomainService.Entry {
    init(_ row: ExpressionSubscriptable, _ db: ItemDatabase) {
        let conn = db.conn
        let id = row[idKey]
        let type = row[typeKey]

        let children: Int?
        if type == .folder, let childCount = try? conn.scalar(itemsTable.filter(parentKey == id && deletedKey == false).count) {
            children = childCount
        } else {
            children = nil
        }

        var quotaRemaining: String? = nil
        var quotaTotal: String? = nil

        if type == .root {
            if let total = UserDefaults.sharedContainerDefaults.accountQuota {
                quotaTotal = "\(total)"
                quotaRemaining = "\(total - db.usedQuota)"
            }
        }

        var userInfo = Self.UserInfo(conflictCount: nil, originatorName: nil, symlinkTargetPath: nil, implicitLockOwner: nil,
                                     quotaRemaining: quotaRemaining, quotaTotal: quotaTotal)

        let (size, userInfoOptional) = Self.computeSizeInline(conn: conn, row: row, id: id, type: type, db: db, quotaRemaining: quotaRemaining,
                                                              quotaTotal: quotaTotal)

        if let userInfo1 = userInfoOptional {
            userInfo = userInfo1
        }

        self.init(name: row[nameKey], id: row[idKey], parent: row[parentKey], revision: DomainService.Version(row), deleted: row[deletedKey],
                  size: size, children: children, type: type, metadata: row[metadataKey], userInfo: userInfo)
    }

    private static func computeSizeInline(conn: Connection,
                                          row: ExpressionSubscriptable,
                                          id: DomainService.ItemIdentifier,
                                          type: DomainService.EntryType,
                                          db: ItemDatabase,
                                          quotaRemaining: String?,
                                          quotaTotal: String?) -> (Int64, DomainService.Entry.UserInfo?) {
        if let contentRow = try? conn.pluck(contentsTable.filter(idKey == id && conflictKey == false)) {
            let size: Int64 = contentSizeForContentRow(contentRow: contentRow)

            let conflictCount = try! conn.scalar(contentsTable.filter(idKey == id && conflictKey == true).select(conflictKey.count))
            let symlinkTargetPath: String?
            if type == .symlink &&
                !row[deletedKey] {
                // Return the symlink target path inline with the item so that
                // symlinks can be materialized as they are enumerated.
                do {
                    symlinkTargetPath = String(data: try db.contentsFromRow(contentRow), encoding: .utf8)
                } catch let error {
                    fatalError("failed to get contents for symlink: \(error)")
                }
            } else {
                symlinkTargetPath = nil
            }

            // If there are entries for locks in the database for this item,
            // tag it with the oldest entry's owner.
            let lock = try! conn.pluck(unlockTable.filter(idKey == id).order(expiryKey.asc))
            let lockOwner = lock?[lockOwnerKey]

            let userInfo: DomainService.Entry.UserInfo?
            if conflictCount > 0 || symlinkTargetPath != nil || lockOwner != nil || quotaTotal != nil || quotaRemaining != nil {
                userInfo = DomainService.Entry.UserInfo(conflictCount: conflictCount, originatorName: contentRow[originatorNameKey],
                                                        symlinkTargetPath: symlinkTargetPath, implicitLockOwner: lockOwner,
                                                        quotaRemaining: quotaRemaining, quotaTotal: quotaTotal)
            } else {
                userInfo = nil
            }
            return (size, userInfo)
        } else {
            return (0, nil)
        }
    }
}

extension DomainService.ConflictVersion {
    init(_ row: ExpressionSubscriptable) {
        self.init(conflict: row[conflictKey], originatorName: row[originatorNameKey], creationDate: row[contentDateKey],
                  contentVersion: row[contentRevKey], baseVersion: row[baseRevKey])
    }
}
