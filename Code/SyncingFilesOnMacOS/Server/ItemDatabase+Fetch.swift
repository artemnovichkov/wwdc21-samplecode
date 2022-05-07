/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The database extension for fetching items on the cloud file server.
*/

import Foundation
import SQLite
import os.log
import Common

extension ItemDatabase {
    func fetchItem(_ identifier: ItemIdentifier) throws -> Entry {
        try checkSimulatedError(for: identifier, .read)
        guard let row = try conn.pluck(itemsTable.filter(identifier == idKey && deletedKey == false && contentStorageTypeKey != .resourceFork)) else {
            throw CommonError.itemNotFound(identifier)
        }
        return Entry(row, self)
    }

    func fetchItem(parent: ItemIdentifier, _ name: String) throws -> Entry? {
        guard let row = try conn.pluck(itemsTable.filter(parentKey == parent && deletedKey == false &&
                                                         nameKey == name && contentStorageTypeKey != .resourceFork)) else { return nil }
        return Entry(row, self)
    }
    
    func contentsFromRow(_ contentsRow: ExpressionSubscriptable, externalIdentifier: Int64? = nil) throws -> Data {
        switch contentsRow[contentStorageTypeKey] {
        case .inline, .resourceFork:
            if let contentLocation = contentLocation {
                return try Data(contentsOf: contentLocation.appendingPathComponent("\(contentsRow[externalIdentifierKey])"))
            }
            return contentsRow[contentsKey]
        case .inChunkStore:
            logger.error("Called contentsFromRow but the row was stored in chunk store")
            throw CommonError.internalError
        }
    }

    func fetchItemContents(identifier: ItemIdentifier, contentRevision: Int64) throws -> Data {
        guard let contentsRow = try conn.pluck(contentsTable.filter(identifier == idKey && contentRevision == contentRevKey &&
                                                                    .resourceFork != contentStorageTypeKey)) else {
            logger.fault("Could not find data for contentRevKey, identifier == \(identifier), revision == \(contentRevision), contentStorageTypeKey != .resourceFork")
            throw CommonError.internalError
        }
        return try contentsFromRow(contentsRow)
    }

    func hasResourceFork(identifier: ItemIdentifier) throws -> Bool {
        guard let itemRow = try conn.pluck(itemsTable.filter(identifier == idKey && deletedKey == false)) else {
            logger.fault("Could not find undeleted item for identifier == \(identifier)")
            throw CommonError.internalError
        }
        return itemRow[resourceForkKey]
    }

    // Returns the item's resource fork, if present. Otherwise, it return an empty data object.
    func fetchItemResourceFork(identifier: ItemIdentifier, contentRevision: Int64) throws -> Data {
        if try !hasResourceFork(identifier: identifier) {
            return Data()
        }

        guard let contentsRow = try conn.pluck(contentsTable.filter(identifier == idKey && contentRevision == contentRevKey &&
                                                                    .resourceFork == contentStorageTypeKey)) else {
            logger.fault("Could not find data for contentRevKey, identifier == \(identifier), revision == \(contentRevision), contentStorageTypeKey != .resourceFork")
            throw CommonError.internalError
        }
        return try contentsFromRow(contentsRow)
    }

    func fetchItemStorageType(identifier: ItemIdentifier, contentRevision: Int64) throws -> DomainService.ContentStorageType {
        guard let contentsRow = try conn.pluck(contentsTable.filter(identifier == idKey && contentRevision == contentRevKey &&
                                                                    .resourceFork != contentStorageTypeKey)) else {
            logger.fault("Could not find storage type for contentRevKey, identifier == \(identifier), revision == \(contentRevision), contentStorageTypeKey != .resourceFork")
            throw CommonError.internalError
        }
        return contentsRow[contentStorageTypeKey]
    }

    func fetchThumbnail(_ identifier: ItemIdentifier) throws -> Data {
        guard let row = try conn.pluck(itemsTable.filter(identifier == idKey && deletedKey == false)) else {
            throw CommonError.itemNotFound(identifier)
        }
        return row[thumbnailKey]
    }
}
