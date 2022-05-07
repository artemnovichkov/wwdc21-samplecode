/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Domain specific implementations of the cloud file server APIs.
*/

import Foundation
import os.log
import FileProvider
import Common

public class DomainBackend: NSObject, DispatchBackend {
    private static let checksumComputer = ChecksumComputer()
    let db: ItemDatabase
    private let contentBasedChunkStore: ContentBasedChunkStore
    let defaults = UserDefaults.sharedContainerDefaults
    public let encoder = JSONEncoder()
    public let decoder = JSONDecoder()
    let identifier: String
    var account: AccountService.Account
    public let displayName: String
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "server")
    let rootItemIdentifier: DomainService.ItemIdentifier
    let trashItemIdentifier: DomainService.ItemIdentifier
    public let queue: DispatchQueue

    static let trashItemName = ".Trash"

    var lockExpiryTimerSource: DispatchSourceTimer? = nil

    public init(identifier: String,
                database: ItemDatabase,
                contentBasedChunkStore: ContentBasedChunkStore) throws {
        db = database
        self.contentBasedChunkStore = contentBasedChunkStore
        account = try db.account(for: identifier)
        self.displayName = account.displayName
        queue = DispatchQueue(label: "backend for \(displayName)")
        self.identifier = identifier
        let root = account.rootItem
        rootItemIdentifier = root.id

        if let trashId = try database.fetchItem(parent: root.id, DomainBackend.trashItemName)?.id {
            trashItemIdentifier = trashId
        } else {
            let (trashId, _) = try database.createFile(parent: root.id, DomainBackend.trashItemName, .folder, .emptyFolder, conflictStrategy: .reject)
            trashItemIdentifier = trashId
        }

        encoder.keyEncodingStrategy = .convertToSnakeCase
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder.userInfo[DomainService.rootItemCodingInfoKey] = rootItemIdentifier
        decoder.userInfo[DomainService.rootItemCodingInfoKey] = rootItemIdentifier
        encoder.userInfo[DomainService.trashItemCodingInfoKey] = trashItemIdentifier
        decoder.userInfo[DomainService.trashItemCodingInfoKey] = trashItemIdentifier
        super.init()
        armLockExpiryTimer()
        db.addUpdateHook { [weak self] operation, database, table, rowid in
            guard let strongSelf = self else { return }
            if table == "accounts" {
                do {
                    strongSelf.account.flags = try strongSelf.db.getAccountFlags(for: identifier)
                } catch let error as NSError {
                    strongSelf.logger.error("🚩 \(strongSelf.displayName): flags update failure: \(error)")
                }
            }
        }
    }

    public func checkForDomainApproval(_ headers: [String: String], _ path: String) throws {
        if !self.defaults.ignoreAuthentication && headers["x-authorization"] != account.secret {
            logger.error("✋ \(self.displayName)\(path): missing authorization")
            throw CommonError.authRequired
        }

        if account.flags.contains(.Offline) {
            logger.error("✋ \(self.displayName)\(path): offline")
            throw CommonError.timedOut
        }
    }

    public static func registerCalls(_ dispatch: BackendCallRegistration) {
        dispatch.registerBackendCall(DomainBackend.listFolder)
        dispatch.registerBackendCall(DomainBackend.create)
        dispatch.registerBackendCall(DomainBackend.modifyContents)
        dispatch.registerBackendCall(DomainBackend.createDataChunk)
        dispatch.registerBackendCall(DomainBackend.getDataChunk)
        dispatch.registerBackendCall(DomainBackend.checkChunkExists)
        dispatch.registerBackendCall(DomainBackend.fetchItemContentStorageType)
        dispatch.registerBackendCall(DomainBackend.fetchItem)
        dispatch.registerBackendCall(DomainBackend.latestRank)
        dispatch.registerBackendCall(DomainBackend.delete)
        dispatch.registerBackendCall(DomainBackend.downloadItem)
        dispatch.registerBackendCall(DomainBackend.modifyMetadata)
        dispatch.registerBackendCall(DomainBackend.fetchThumbnail)
        dispatch.registerBackendCall(DomainBackend.updateThumbnail)
        dispatch.registerBackendCall(DomainBackend.listChanges)
        dispatch.registerBackendCall(DomainBackend.mark)
        dispatch.registerBackendCall(DomainBackend.trash)
        dispatch.registerBackendCall(DomainBackend.conflictVersions)
        dispatch.registerBackendCall(DomainBackend.resolveConflicts)
        dispatch.registerBackendCall(DomainBackend.createConflict)
        dispatch.registerBackendCall(DomainBackend.pingLock)
        dispatch.registerBackendCall(DomainBackend.removeLock)
        dispatch.registerBackendCall(DomainBackend.forceLock)
        dispatch.registerBackendCall(DomainBackend.registerPush)
        dispatch.registerBackendCall(DomainBackend.setSimulateError)
        dispatch.registerBackendCall(DomainBackend.listSimulatedError)
        dispatch.registerBackendCall(DomainBackend.listLocks)
    }

    func armLockExpiryTimer() {
        if let oldSource = lockExpiryTimerSource {
            oldSource.cancel()
        }
        do {
            if let lockExpiry = try db.expireLocks() {
                let timeInterval = lockExpiry.timeIntervalSinceNow
                logger.debug("⏰ next lock expiry is in \(timeInterval)s for \(self.displayName)")
                let newSource = DispatchSource.makeTimerSource(flags: [], queue: queue)
                newSource.setEventHandler { [weak self] in
                    self?.armLockExpiryTimer()
                }
                newSource.schedule(deadline: DispatchTime.now().advanced(by: .milliseconds(Int(timeInterval * 1000.0))))
                newSource.resume()
                lockExpiryTimerSource = newSource
            } else {
                logger.debug("⏰ all locks are expired for \(self.displayName)")
                lockExpiryTimerSource = nil
            }
        } catch let error {
            fatalError("error expiring lock: \(error)")
        }

    }
}

protocol XAttrSettable: Codable {
    var includeAsExtendedAttribute: Bool { get }
}

extension String: XAttrSettable {
    var includeAsExtendedAttribute: Bool {
        return !isEmpty
    }

}

extension Bool: XAttrSettable {
    var includeAsExtendedAttribute: Bool {
        return self
    }
}

extension DomainBackend {
    func listFolder(_ param: DomainService.ListFolderParameter) throws -> DomainService.ListFolderReturn {
        let ret = try db.listFiles(parent: param.folderIdentifier, cursor: param.startingCursor, recursive: param.recursive)
        let rank = DomainService.RankToken(rank: db.latestRank(), tokenCheckNumber: account.tokenCheckNumber)

        let files = ret.entries
        let deleted = files.compactMap { $0.deleted ? $0.id : nil }
        return DomainService.ListFolderReturn(entries: files.filter { !$0.deleted }, deletedEntries: deleted, cursor: ret.cursor, rank: rank)
    }

    func listChanges(_ param: DomainService.ListChangesParameter) throws -> DomainService.ListChangesReturn {
        guard param.startingRank.tokenCheckNumber == account.tokenCheckNumber else { throw CommonError.tokenExpired }
        let ret = try db.listChanges(parent: param.folderIdentifier, rank: param.startingRank.rank, recursive: param.recursive)

        let files = ret.entries
        let deleted = files.compactMap { $0.deleted ? $0.id : nil }
        let rank = DomainService.RankToken(rank: ret.rank, tokenCheckNumber: account.tokenCheckNumber)
        return DomainService.ListChangesReturn(entries: files.filter { !$0.deleted }, deletedEntries: deleted, rank: rank, hasMore: ret.moreComing)
    }

    func latestRank(_ param: DomainService.LatestRankParameter) throws -> DomainService.LatestRankReturn {
        return DomainService.LatestRankReturn(rank: DomainService.RankToken(rank: db.latestRank(), tokenCheckNumber: account.tokenCheckNumber))
    }

    // Pass the content storage type in the HTTP call, and convert it to a content
    // storage type parameter to avoid the need to serialize and deserialize
    // the buffer in the JSON payload.
    private func convertStorageTypeToParameter(
        contentStorageType: DomainService.ContentStorageType?, data: Data) throws -> DomainService.ContentStorageTypeParameter? {
        let contentStorageTypeParameter: DomainService.ContentStorageTypeParameter?
        switch contentStorageType {
        case .inline?:
            contentStorageTypeParameter = .inline(data: data)
        case .inChunkStore(let sha256s)?:
            guard data.isEmpty else {
                logger.error("received inChunkStore storage type, but data.count was not 0 but \(data.count)")
                throw CommonError.internalError
            }
            contentStorageTypeParameter = .inChunkStore(contentSha256sOfDataChunks: sha256s)
        case .resourceFork?:
            contentStorageTypeParameter = .inline(data: data)
        case nil:
            contentStorageTypeParameter = nil
        }
        return contentStorageTypeParameter
    }

    func create(_ param: DomainService.CreateParameter, _ data: Data) throws -> DomainService.CreateReturn {
        let contentStorageTypeParameter = try convertStorageTypeToParameter(contentStorageType: param.contentStorageType, data: data)
        let identifier: DomainService.ItemIdentifier
        let version: DomainService.Version
        do {
            (identifier, version) = try db.createFile(parent: param.parent, param.name, param.type, conflictStrategy: .reject)
        } catch CommonError.itemExists(let entry) {
            if param.type != entry.type ||
                param.conflictStrategy == .failOnExisting {
                throw CommonError.itemExists(entry)
            }
            if param.conflictStrategy == .updateAlreadyExisting {
                identifier = entry.id
                version = entry.revision
            } else {
                let strategy: ItemDatabase.ConflictResolutionStrategy
                let contentLength = contentStorageTypeParameter == nil ? 0 : contentStorageTypeParameter?.contentLength()
                if entry.size == contentLength {
                    strategy = .merge
                } else {
                    strategy = try db.conflictStrategy(for: entry, param.type, .create)
                }
                (identifier, version) = try db.createFile(parent: param.parent, param.name, param.type, conflictStrategy: strategy)
            }
        }
        let file: DomainService.Entry
        do {
            if param.type == .folder || param.type == .root {
                file = try db.updateFile(identifier: identifier, revision: version, metadata: param.metadata)
            } else {
                // If caller didn't pass a contentStorageTypeParameter, there is
                // nothing to persist in data side. This can occur, for example,
                // when createItem is called without .contents in the fields parameter.
                if let contentStorageTypeParameter = contentStorageTypeParameter {
                    let temp = try db.updateFile(identifier: identifier, revision: version,
                                                 contentStorageTypeParameter: contentStorageTypeParameter,
                                                 originatorName: displayName)
                    file = try db.updateFile(identifier: identifier, revision: temp.revision, metadata: param.metadata)
                } else {
                    file = try db.updateFile(identifier: identifier, revision: version, metadata: param.metadata)
                }
            }
            return DomainService.CreateReturn(item: file)
        } catch let error {
            // If creating the file's content fails, delete the file entry
            // that was created in the database.
            try db.delete(item: identifier, revision: version, recursive: true)
            throw error
        }
    }

    func modifyContents(_ param: DomainService.ModifyContentsParameter, _ data: Data) throws -> DomainService.ModifyContentsReturn {
        let contentStorageTypeParameterOptional = try convertStorageTypeToParameter(contentStorageType: param.contentStorageType, data: data)
        guard let contentStorageTypeParameter: DomainService.ContentStorageTypeParameter = contentStorageTypeParameterOptional else {
            self.logger.error("Expected non-nil content storage type when modifying contents")
            throw CommonError.internalError
        }
        do {
            let file = try db.updateFile(identifier: param.identifier, revision: param.existingRevision,
                                         contentStorageTypeParameter: contentStorageTypeParameter,
                                         originatorName: displayName, conflict: param.updateResourceForkOnConflictedItem,
                                         isResourceFork: param.contentStorageType == .resourceFork)
            return DomainService.ModifyContentsReturn(item: file, contentAccepted: true)
        } catch CommonError.wrongRevision(let entry) {
            if param.contentStorageType != .resourceFork {
                let conflict = try db.updateFile(identifier: param.identifier, revision: entry.revision,
                                                 contentStorageTypeParameter: contentStorageTypeParameter,
                                                 originatorName: displayName, conflict: true)
                return DomainService.ModifyContentsReturn(item: conflict, contentAccepted: false)
            } else {
                throw CommonError.wrongRevision(entry)
            }
        }
    }

    func createDataChunk(_ param: DomainService.CreateDataChunkParameter, _ data: Data) throws -> DomainService.CreateDataChunkReturn {
        let sha256OfChunk = try DomainBackend.checksumComputer.convertHexSha256ToData(hexSha256: param.hexEncodedSha256OfData,
                                                                                      description: "createDataChunk")
        try self.contentBasedChunkStore.createChunk(sha256OfChunk: sha256OfChunk, chunkData: data)
        return DomainService.CreateDataChunkReturn()
    }

    func getDataChunk(_ param: DomainService.GetDataChunkParameter) throws -> (DomainService.GetDataChunkReturn, Data) {
        let sha256OfChunk = try DomainBackend.checksumComputer.convertHexSha256ToData(hexSha256: param.hexEncodedSha256OfData,
                                                                                      description: "getDataChunk")
        let chunkDataOptional = try self.contentBasedChunkStore.retrieveChunk(sha256OfChunk: sha256OfChunk)
        guard let chunkData = chunkDataOptional else {
            logger.error("No data chunk found for sha: \(param.hexEncodedSha256OfData)")
            throw CommonError.internalError
        }
        return (DomainService.GetDataChunkReturn(), chunkData)
    }

    func checkChunkExists(_ param: DomainService.CheckChunkExistsParameter) throws -> DomainService.CheckChunkExistsReturn {
        var chunksThatExist: Set<String> = Set()
        var chunksThatDoNotExist: Set<String> = Set()

        try param.hexEncodedSha256OfChunksToCheck.forEach { hexEncodedSha256 in
            let sha256OfChunk = try DomainBackend.checksumComputer.convertHexSha256ToData(hexSha256: hexEncodedSha256,
                                                                                          description: "checkChunkExists")

            let exists = self.contentBasedChunkStore.chunkExists(sha256OfChunk: sha256OfChunk)
            if exists {
                chunksThatExist.insert(hexEncodedSha256)
            } else {
                chunksThatDoNotExist.insert(hexEncodedSha256)
            }
        }

        assert((chunksThatExist.count + chunksThatDoNotExist.count) == param.hexEncodedSha256OfChunksToCheck.count)

        return DomainService.CheckChunkExistsReturn(chunksThatExist: chunksThatExist, chunksThatDoNotExist: chunksThatDoNotExist)
    }

    func modifyMetadata(_ param: DomainService.ModifyMetadataParameter) throws -> DomainService.ModifyMetadataReturn {
        do {
            let entry = try db.updateFile(identifier: param.itemIdentifier, revision: param.existingRevision, metadata: param.metadata,
                                          parent: param.parent, itemName: param.filename)
            return DomainService.ModifyMetadataReturn(item: entry, metadataWasRolledBack: false)
        } catch CommonError.wrongRevision(let entry) {
            return DomainService.ModifyMetadataReturn(item: entry, metadataWasRolledBack: true)
        }
    }

    func fetchItem(_ param: DomainService.FetchItemParameter) throws -> DomainService.FetchItemReturn {
        return DomainService.FetchItemReturn(item: try db.fetchItem(param.itemIdentifier))
    }

    func downloadItem(_ param: DomainService.DownloadItemParameter) throws -> (DomainService.DownloadItemReturn, Data) {
        let item = try db.fetchItem(param.itemIdentifier)
        if let version = param.requestedRevision {
            guard item.revision.content == version.content else {
                throw CommonError.wrongRevision(item)
            }
        }

        let data: Data
        if !param.resourceFork {
            data = try db.fetchItemContents(identifier: item.id, contentRevision: item.revision.content)
        } else {
            data = try db.fetchItemResourceFork(identifier: item.id, contentRevision: item.revision.content)
        }
        return (DomainService.DownloadItemReturn(item: item), data)
    }

    func fetchItemContentStorageType(
        _ param: DomainService.FetchItemContentStorageTypeParameter) throws -> (DomainService.FetchItemContentStorageTypeReturn) {
        let contentStorageType = try db.fetchItemStorageType(identifier: param.itemIdentifier, contentRevision: param.requestedRevision.content)
        return (DomainService.FetchItemContentStorageTypeReturn(contentStorageType: contentStorageType))
    }

    func delete(_ param: DomainService.DeleteItemParameter) throws -> DomainService.DeleteItemReturn {
        try db.delete(item: param.itemIdentifier, revision: param.existingRevision, recursive: param.recursiveDelete)

        return DomainService.DeleteItemReturn()
    }

    func trash(_ param: DomainService.TrashItemParameter) throws -> DomainService.TrashItemReturn {
        do {
            let entry = try db.updateFile(identifier: param.itemIdentifier, revision: param.existingRevision, parent: trashItemIdentifier)
            return DomainService.TrashItemReturn(item: entry, metadataWasRolledBack: false)
        } catch CommonError.wrongRevision(let entry) {
            return DomainService.TrashItemReturn(item: entry, metadataWasRolledBack: true)
        }
    }

    func updateThumbnail(_ param: DomainService.UpdateThumbnailParameter, _ data: Data) throws -> DomainService.UpdateThumbnailReturn {
        let file = try db.updateFile(identifier: param.identifier, revision: param.existingRevision, thumbnail: data)
        return DomainService.UpdateThumbnailReturn(item: file)
    }

    func fetchThumbnail(_ param: DomainService.FetchThumbnailParameter) throws -> (DomainService.FetchThumbnailReturn, Data) {
        let item = try db.fetchItem(param.identifier)
        if let version = param.requestedRevision {
            guard item.revision == version else {
                throw CommonError.wrongRevision(item)
            }
        }
        let thumbnail = try db.fetchThumbnail(param.identifier)
        return (DomainService.FetchThumbnailReturn(item: item), thumbnail)
    }

    func conflictVersions(_ param: DomainService.ConflictVersionsParameter) throws -> DomainService.ConflictVersionsReturn {
        let versions = try db.conflictVersions(item: param.identifier)
        let item = try db.fetchItem(param.identifier)
        return DomainService.ConflictVersionsReturn(versions: versions, currentVersion: item.revision)
    }

    func resolveConflicts(_ param: DomainService.ResolveConflictVersionsParameter) throws -> DomainService.ResolveConflictVersionsReturn {
        try db.keep(versions: param.versionsToKeep, of: param.identifier, baseVersion: param.baseVersion)
        return DomainService.ResolveConflictVersionsReturn()
    }

    func createConflict(_ param: DomainService.CreateConflictParameter) throws -> DomainService.CreateConflictReturn {
        let item = try db.fetchItem(param.identifier)
        let contentStorageTypeParameter: DomainService.ContentStorageTypeParameter
        let contentStorageType = try db.fetchItemStorageType(identifier: item.id, contentRevision: item.revision.content)
        switch contentStorageType {
        case .inline:
            let itemContents = try db.fetchItemContents(identifier: item.id, contentRevision: item.revision.content)
            contentStorageTypeParameter = .inline(data: itemContents)
        case .inChunkStore(let contentSha256sOfDataChunks):
            contentStorageTypeParameter = .inChunkStore(contentSha256sOfDataChunks: contentSha256sOfDataChunks)
        case .resourceFork:
            fatalError("Should not happen")
        }
        let entry = try db.updateFile(identifier: param.identifier, revision: item.revision, contentStorageTypeParameter: contentStorageTypeParameter,
                                      originatorName: param.originator, conflict: true)

        return DomainService.CreateConflictReturn(entry: entry)
    }

    func mark(_ param: DomainService.MarkParameter) throws -> DomainService.MarkReturn {
        for id in param.identifiers {
            let old = try db.fetchItem(id)
            var xattr: [String: Data] = old.metadata.extendedAttributes?.values ?? [String: Data]()
            func updateXattr<T: XAttrSettable>(_ value: T?, attrName: String) throws {
                if let value = value {
                    if value.includeAsExtendedAttribute {
                        xattr[attrName] = try JSONEncoder().encode(value)
                    } else {
                        xattr.removeValue(forKey: attrName)
                    }
                }
            }
            try updateXattr(param.heart, attrName: DomainService.MarkParameter.heartXattr)
            try updateXattr(param.pinned, attrName: DomainService.MarkParameter.pinnedXattr)
            try updateXattr(param.isShared, attrName: DomainService.MarkParameter.isSharedXattr)

            let updateMeta: DomainService.EntryMetadata
            if !xattr.isEmpty {
                updateMeta = DomainService.EntryMetadata(fileSystemFlags: nil, lastUsedDate: nil, tagData: nil, favoriteRank: nil, creationDate: nil,
                                                         contentModificationDate: nil,
                                                         extendedAttributes: DomainService.EntryMetadata.ExtendedAttributes(values: xattr),
                                                         typeAndCreator: nil, validEntries: [.extendedAttributes])
            } else {
                updateMeta = DomainService.EntryMetadata(fileSystemFlags: nil, lastUsedDate: nil, tagData: nil, favoriteRank: nil, creationDate: nil,
                                                         contentModificationDate: nil, extendedAttributes: nil, typeAndCreator: nil,
                                                         validEntries: [.extendedAttributes])
            }
            let meta = old.metadata.merge(updateMeta)

            _ = try db.updateFile(identifier: id, revision: old.revision, metadata: meta)
        }
        return DomainService.MarkReturn()
    }

    func pingLock(_ param: DomainService.PingLockParameter) throws -> DomainService.PingLockReturn {
        try db.updateLock(for: param.identifier, Date(timeIntervalSinceNow: DomainService.PingLockParameter.unlockInterval), param.enumerationIndex,
                          owner: param.owner)
        armLockExpiryTimer()
        return DomainService.PingLockReturn()
    }

    func removeLock(_ param: DomainService.RemoveLockParameter) throws -> DomainService.RemoveLockReturn {
        try db.removeLock(for: param.identifier, param.enumerationIndex)
        return DomainService.RemoveLockReturn()
    }

    func forceLock(_ param: DomainService.ForceLockParameter) throws -> DomainService.ForceLockReturn {
        try db.removeLock(for: param.identifier, nil)
        return DomainService.ForceLockReturn()
    }
}

extension DomainBackend {
    func registerPush(_ param: DomainService.PushRegistrationParameter) throws -> DomainService.PushRegistrationReturn {
        let deviceToken = "\(param.token.map({ String(format: "%02hhx", $0) }).joined() )"

        let providerSuffix = ".Provider"
        let bundleId = param.bundleIdentifier
        guard bundleId.hasSuffix(providerSuffix) else {
            // Only accept registration from the provider.
            throw CommonError.parameterError
        }
        let topic = bundleId.prefix(bundleId.count - providerSuffix.count).appending(".pushkit.fileprovider")
        
        try db.refreshPushToken(deviceToken, topic)
        logger.info("registered push token \(deviceToken) for topic \(topic)")

        return DomainService.PushRegistrationReturn()
    }
    
    public var registeredDevices: [DomainService.PushDevice] {
        (try? db.allPushTokens()) ?? [DomainService.PushDevice]()
    }
}

extension DomainBackend {
    func setSimulateError(_ param: DomainService.SimulateErrorParameter) throws -> DomainService.SimulateErrorReturn {
        try db.setSimulatedError(param.identifier, param.error, param.accessType)
        return DomainService.SimulateErrorReturn()
    }

    func listSimulatedError(_ param: DomainService.SimulateErrorListParameter) throws -> DomainService.SimulateErrorListReturn {
        return DomainService.SimulateErrorListReturn(errors: try db.simulatedErrors())
    }

    func listLocks(_ param: DomainService.ListLocksParameter) throws -> DomainService.ListLocksReturn {
        return DomainService.ListLocksReturn(locks: try db.allLocks())
    }
}
