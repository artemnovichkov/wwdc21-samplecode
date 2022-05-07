/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The database extension for creating and updating items on the cloud file server.
*/

import Foundation
import SQLite
import os.log
import Common

extension ItemDatabase {
    // Create a dataless file (or folder) entry.
    func createFile(parent: ItemIdentifier, _ name: String, _ type: DomainService.EntryType = .file, _ metadata: EntryMetadata = .empty,
                    conflictStrategy forcedConflictStrategy: ConflictResolutionStrategy = .reject) throws -> (ItemIdentifier, Version) {
        try checkSimulatedError(for: parent, .write)
        return try conn.transaction {
            // Check that the name is valid.
            guard !name.isEmpty else { throw CommonError.parameterError }

            // Check that the parent exists.
            guard let parentRow = try conn.pluck(itemsTable.filter(parent == idKey)),
                parentRow[deletedKey] == false else {
                    throw CommonError.itemNotFound(parent)
            }
            // Check that no item of the same name already exists.
            let item = itemsTable.filter(name == nameKey && parent == parentKey && deletedKey == false && typeKey != .root)
            if let row = try conn.pluck(item) {
                switch forcedConflictStrategy {
                case .reject:
                    throw CommonError.itemExists(Entry(row, self))
                case .merge:
                    let entry = Entry(row, self)
                    return (entry.id, entry.revision)
                case .bounce:
                    // Rename the existing file by appending a unique number to the end of its name.
                    // This way, if a swap is synced, e.g. a->b + b->a, the following operations will be performed:
                    // 1. b -> b2, a -> b
                    // 2. b2 -> a
                    // which makes everything come out correctly.
                    // A nicer database representation would be to keep the bounce number and the filename separate, then only apply the
                    // bounce if necessary. That would have the advantage of bouncing the newer file, which is closer to
                    // the user's expectations in case of a real bounce.
                    let bounceName = try bounceFileIfNecessary(parent, name)
                    try conn.run(itemsTable.where(idKey == row[idKey]).update(nameKey <- bounceName))
                }
            }

            try updateAndSignal(itemIds: [parent], signal: .item)
            let id = try conn.run(itemsTable.insert(nameKey <- name, parentKey <- parent, rankKey <- allocateNewRank(),
                                                    typeKey <- type, metadataKey <- metadata))
            return (ItemIdentifier(id), .zero)
        }
    }

    // Update a file's data.
    func updateFile(identifier: ItemIdentifier,
                    revision: Version,
                    contentStorageTypeParameter: DomainService.ContentStorageTypeParameter,
                    originatorName: String,
                    conflict: Bool = false,
                    forcedConflictStrategy: ConflictResolutionStrategy? = nil,
                    isResourceFork: Bool = false) throws -> Entry {
        let item = itemsTable.filter(identifier == idKey)
        try checkSimulatedError(for: identifier, .write)
        return try conn.transaction {
            guard let oldItem = try conn.pluck(item) else { throw CommonError.itemNotFound(identifier) }
            guard oldItem[deletedKey] == false else { throw CommonError.itemNotFound(identifier) }
            // Check that the revision has the same version as the old item.
            guard revision.content == Version(oldItem).content else { throw CommonError.wrongRevision(Entry(oldItem, self)) }
            // Check that the new size won't go over the user's quota.
            let newQuotaUsed = try computeNewQuotaUsed(identifier: identifier, oldVersion: oldItem[contentRevKey],
                                                       newSize: contentStorageTypeParameter.contentLength())
            // A quota of 0 means unlimited.
            if let accountQuota = UserDefaults.sharedContainerDefaults.accountQuota {
                guard newQuotaUsed <= accountQuota else {
                    throw CommonError.insufficientQuota }
            }
            let rank = allocateNewRank()

            let contentStorageType: DomainService.ContentStorageType
            switch contentStorageTypeParameter {
            case .inline:
                contentStorageType = .inline
            case .inChunkStore(let contentSha256sOfDataChunks):
                contentStorageType = .inChunkStore(contentSha256sOfDataChunks: contentSha256sOfDataChunks)
            }

            let contentRev = try conn.scalar(itemsTable.filter(identifier == idKey).select(contentRevKey.max))!
            let newContentRev = contentRev + 1

            switch contentStorageTypeParameter {
            case .inline(let data):
                if let contentLocation = contentLocation {
                    // Use the content location, if available.
                    if !isResourceFork {
                        let externalIdentifier = try conn.run(contentsTable.insert(idKey <- identifier, contentStorageTypeKey <- contentStorageType,
                                                                                   contentRevKey <- newContentRev,
                                                                                   originatorNameKey <- originatorName, contentDateKey <- Date(),
                                                                                   baseRevKey <- revision.content,
                                                                                   externalSizeKey <- Int64(data.count)))
                        try data.write(to: contentLocation.appendingPathComponent("\(externalIdentifier)"))
                    } else {
                        let externalIdentifier = try conn.run(contentsTable.insert(idKey <- identifier, contentStorageTypeKey <- .resourceFork,
                                                                                   contentRevKey <- contentRev, originatorNameKey <- originatorName,
                                                                                   contentDateKey <- Date(), baseRevKey <- revision.content,
                                                                                   externalSizeKey <- Int64(data.count)))
                        try data.write(to: contentLocation.appendingPathComponent("\(externalIdentifier)"))
                    }
                } else {
                    if !isResourceFork {
                        try conn.run(contentsTable.insert(idKey <- identifier, contentStorageTypeKey <- contentStorageType,
                                                          contentRevKey <- newContentRev, contentsKey <- data, originatorNameKey <- originatorName,
                                                          contentDateKey <- Date(), baseRevKey <- revision.content,
                                                          externalSizeKey <- Int64(data.count)))
                    } else {
                        try conn.run(contentsTable.insert(idKey <- identifier, contentStorageTypeKey <- .resourceFork, contentRevKey <- contentRev,
                                                          contentsKey <- data, originatorNameKey <- originatorName, contentDateKey <- Date(),
                                                          baseRevKey <- revision.content, externalSizeKey <- Int64(data.count)))
                    }
                }
            case .inChunkStore(let sha256s):
                try conn.run(contentsTable.insert(idKey <- identifier, contentStorageTypeKey <- contentStorageType, contentRevKey <- newContentRev,
                                                  originatorNameKey <- originatorName, contentDateKey <- Date(), baseRevKey <- revision.content,
                                                  externalSizeKey <- sha256s.contentLength))
            }

            if !isResourceFork {
                try conn.run(item.update(contentRevKey <- newContentRev, rankKey <- rank))
            } else {
                try conn.run(item.update(resourceForkKey <- true))
            }
            usedQuota = newQuotaUsed
            if !conflict {
                // Delete all non-conflicts other than this one.
                let oldContents: Table
                if !isResourceFork {
                    oldContents = contentsTable.filter(idKey == identifier && conflictKey != true &&
                                                       contentRevKey != newContentRev && contentStorageTypeKey != .resourceFork)
                } else {
                    oldContents = contentsTable.filter(idKey == identifier && conflictKey != true &&
                                                       contentRevKey != contentRev && contentStorageTypeKey == .resourceFork)
                }
                if let contentLocation = contentLocation {
                    for row in try conn.prepare(oldContents) where row[contentStorageTypeKey] == .inline {
                        try? FileManager().removeItem(at: contentLocation.appendingPathComponent("\(row[externalIdentifierKey])"))
                    }
                }

                try conn.run(oldContents.delete())
                if !isResourceFork {
                    // Delete the thumbnail of the old version.
                    try conn.run(item.update(thumbnailKey <- Data()))
                }
            } else {
                // Mark all previous versions as conflicts.
                try conn
                    .run(contentsTable.filter(idKey == identifier && contentRevKey != newContentRev && contentStorageTypeKey != .resourceFork)
                    .update(conflictKey <- true))
            }

            guard let row = try conn.pluck(item) else {
                throw CommonError.internalError
            }
            notifyChangeListeners(row[parentKey])
            return Entry(row, self)
        }
    }

    internal func parentQueryWithFilter(_ child: ItemIdentifier) throws -> Statement {
        let statement = try conn.prepare("""
            WITH RECURSIVE parent_of(id) AS (
            SELECT \(parentKey.asSQL()) FROM items WHERE (\(idKey.asSQL()) = (?))
            UNION
            SELECT \(parentKey.asSQL()) FROM items, parent_of
            WHERE items.\(idKey.asSQL()) = parent_of.id
            )
            SELECT * FROM items WHERE \(idKey.asSQL()) IN parent_of ORDER BY id
            """, child.id)
        return statement
    }

    // Update a file's metadata.
    func updateFile(identifier: ItemIdentifier, revision: Version, metadata: EntryMetadata? = nil, parent: ItemIdentifier? = nil,
                    itemName: String? = nil, thumbnail: Data? = nil, forcedConflictStrategy: ConflictResolutionStrategy? = nil) throws -> Entry {
        try checkSimulatedError(for: identifier, .write)
        if let parent = parent {
            try checkSimulatedError(for: parent, .write)
        }
        return try conn.transaction {
            let item = itemsTable.filter(identifier == idKey)

            // Check that the item exists.
            guard let oldItem = try conn.pluck(item) else { throw CommonError.itemNotFound(identifier) }
            guard oldItem[deletedKey] == false else { throw CommonError.itemNotFound(identifier) }
            // Check that it has the correct version.
            guard revision.metadata == Version(oldItem).metadata else { throw CommonError.wrongRevision(Entry(oldItem, self)) }

            let newName = itemName ?? oldItem[nameKey]
            guard !newName.isEmpty else { throw CommonError.parameterError }
            let newParent = parent ?? oldItem[parentKey]
            // Check whether the new parent still exists.
            guard let parentRow = try conn.pluck(itemsTable.filter(newParent == idKey)),
                parentRow[deletedKey] == false else {
                    throw CommonError.itemNotFound(newParent)
            }
            // Check that it can be renamed or moved to this location.
            let existingItem = itemsTable.filter(newName == nameKey && newParent == parentKey && deletedKey == false &&
                                                 idKey != identifier && typeKey != .root)
            if let row = try conn.pluck(existingItem) {
                let strategy = try conflictStrategy(for: Entry(row, self), oldItem[typeKey], .modifyMetadata)
                switch forcedConflictStrategy ?? strategy {
                case .reject:
                    throw CommonError.itemExists(Entry(row, self))
                case .bounce:
                    let bounceName = try bounceFileIfNecessary(newParent, newName)
                    try conn.run(itemsTable.where(idKey == row[idKey]).update(nameKey <- bounceName))
                case .merge:
                    fatalError("shouldn't happen")
                }
            }

            // To avoid cycles, fetch all parents for the new location.
            let statement = try parentQueryWithFilter(newParent)
            let parentIdentifiers = statement.map({ RowWrapper(statement.columnNames, $0) }).map({ $0[idKey] })
            // Confirm that the item is not one of the parents of the new location.
            if oldItem[typeKey] != .root {
                if parentIdentifiers.contains(where: { $0 == identifier }) {
                    throw CommonError.parameterError
                }
            }

            // Perform all updates.
            let rank = allocateNewRank()
            notifyChangeListeners(oldItem[parentKey])
            if let parent = parent {
                notifyChangeListeners(parent)
                try conn.run(item.update(parentKey <- parent))
            }
            if let itemName = itemName {
                try conn.run(item.update(nameKey <- itemName))
            }
            if let thumbnail = thumbnail {
                try conn.run(item.update(thumbnailKey <- thumbnail))
            }
            if let metadata = metadata {
                let modifiedMetadata = oldItem[metadataKey].merge(metadata)
                try conn.run(item.update(metadataKey <- modifiedMetadata))
            }

            try conn.run(item.update(rankKey <- rank))
            try conn.run(item.update(revKey++))

            guard let row = try conn.pluck(item) else { throw CommonError.internalError }
            return Entry(row, self)
        }
    }
    
    func computeNewQuotaUsed(identifier: ItemIdentifier, oldVersion: Int64, newSize: Int64) throws -> Int64 {
        let oldContentRow = contentsTable.filter(identifier == idKey && oldVersion == contentRevKey)
        let oldContentSize: Int64
        if let oldContent = try conn.pluck(oldContentRow) {
            oldContentSize = contentSizeForContentRow(contentRow: oldContent)
        } else {
            oldContentSize = 0
        }

        let newContentSizeMinusOldContentSize = newSize - oldContentSize

        return usedQuota + newContentSizeMinusOldContentSize
    }
    
    func bounceFileIfNecessary(_ parent: ItemIdentifier, _ name: String) throws -> String {
        func _bounceFileIfNecessary(_ parent: ItemIdentifier, _ name: String) throws -> (name: String, didBounce: Bool) {
            let item = itemsTable.filter(name == nameKey && parent == parentKey && deletedKey == false && typeKey != .root)
            if try conn.pluck(item) != nil {
                return (try bounceFileIfNecessary(parent, name.filenameWithIncrementedBounce()), true)
            } else {
                return (name, false)
            }
        }

        let ret = try _bounceFileIfNecessary(parent, name)
        if ret.didBounce {
            logger.debug("🏀 bouncing item \(name) to \(ret.name)")
        }
        return ret.name
    }
}
