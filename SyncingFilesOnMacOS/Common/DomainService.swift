/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Parameter and return values for domain-related requests to the local HTTP server.
*/

import FileProvider


public enum JSONMethod: String {
    case GET
    case POST
    case DELETE
}

public protocol JSONParameter: Codable {
    associatedtype ReturnType: Codable
    static var method: JSONMethod { get }
    static var endpoint: String { get }
}

extension NSFileProviderFileSystemFlags: Codable {
    public init(from decoder: Decoder) throws {
        try self.init(rawValue: UInt(from: decoder))
    }

    public func encode(to encoder: Encoder) throws {
        return try self.rawValue.encode(to: encoder)
    }
}

public enum DomainService {
    public static let rootItemCodingInfoKey = CodingUserInfoKey(rawValue: "rootItemIdentifier")!
    public static let trashItemCodingInfoKey = CodingUserInfoKey(rawValue: "trashItemIdentifier")!

    public enum EntryType: String, Codable {
        case file
        case folder
        case root
        case symlink
        case alias
    }

    public struct Version: Codable, Equatable {
        public let content: Int64
        public let metadata: Int64

        public static let zero = Version(content: 0, metadata: 0)

        public init(content: Int64, metadata: Int64) {
            self.content = content
            self.metadata = metadata
        }
    }

    public struct ConflictVersion: Codable, Equatable {
        public let conflict: Bool
        public let originatorName: String
        public let creationDate: Date
        public let contentVersion: Int64
        public let baseVersion: Int64

        public init(conflict: Bool, originatorName: String, creationDate: Date, contentVersion: Int64, baseVersion: Int64) {
            self.conflict = conflict
            self.originatorName = originatorName
            self.creationDate = creationDate
            self.contentVersion = contentVersion
            self.baseVersion = baseVersion
        }
    }

    public struct RankToken: Codable, Equatable {
        public let rank: Int64
        public let tokenCheckNumber: Int64

        public init(rank: Int64, tokenCheckNumber: Int64) {
            self.rank = rank
            self.tokenCheckNumber = tokenCheckNumber
        }
    }

    public struct ItemIdentifier: Codable, Equatable, ExpressibleByIntegerLiteral, Hashable {
        public let id: Int64

        public init(_ id: Int64) {
            self.id = id
        }

        public init(integerLiteral value: Int64) {
            self.id = value
        }

        enum CodingKeys: CodingKey {
            case id
            case root
            case trash
        }

        // When encoding ItemIdentifiers to their wire format, encode it as
        // .root=true if the item is the encoding domain's root item. This
        // ensures that the recipient will see the item as their own local root item identifier.
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            guard let rootIdentifier = encoder.userInfo[rootItemCodingInfoKey] as? DomainService.ItemIdentifier,
                let trashIdentifier = encoder.userInfo[trashItemCodingInfoKey] as? ItemIdentifier else {
                    try container.encode(id, forKey: .id)
                    return
            }
            if self == rootIdentifier {
                try container.encode(true, forKey: .root)
            } else if self == trashIdentifier {
                try container.encode(true, forKey: .trash)
            } else {
                try container.encode(id, forKey: .id)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let root = try? container.decode(Bool.self, forKey: .root),
                root {
                guard let rootIdentifier = decoder.userInfo[rootItemCodingInfoKey] as? DomainService.ItemIdentifier else {
                    throw CommonError.internalError
                }
                self = rootIdentifier
            } else if let trash = try? container.decode(Bool.self, forKey: .trash),
                trash {
                guard let trashIdentifier = decoder.userInfo[trashItemCodingInfoKey] as? DomainService.ItemIdentifier else {
                    throw CommonError.internalError
                }
                self = trashIdentifier
            } else {
                self.id = try container.decode(Int64.self, forKey: .id)
            }
        }
    }
}

extension DomainService {
    public struct EntryMetadata: Codable {
        public struct ValidEntries: OptionSet, Codable {
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }

            public let rawValue: Int

            public static let fileSystemFlags = ValidEntries(rawValue: 1 << 0)
            public static let lastUsedDate = ValidEntries(rawValue: 1 << 1)
            public static let tagData = ValidEntries(rawValue: 1 << 2)
            public static let favoriteRank = ValidEntries(rawValue: 1 << 3)
            public static let creationDate = ValidEntries(rawValue: 1 << 4)
            public static let contentModificationDate = ValidEntries(rawValue: 1 << 5)
            public static let extendedAttributes = ValidEntries(rawValue: 1 << 6)
            public static let typeAndCreator = ValidEntries(rawValue: 1 << 7)
        }
        public struct ExtendedAttributes: Codable {
            public let values: [String: Data]

            public init(values: [String: Data]) {
                self.values = values
            }
        }

        public let fileSystemFlags: NSFileProviderFileSystemFlags?
        public let lastUsedDate: Date?
        public let tagData: Data?
        public let creationDate: Date?
        public let contentModificationDate: Date?
        public let extendedAttributes: ExtendedAttributes?
        public let typeAndCreator: UInt64?
        public let validEntries: ValidEntries

        public static let empty = EntryMetadata(fileSystemFlags: nil, lastUsedDate: nil, tagData: nil, favoriteRank: nil, creationDate: nil,
                                                contentModificationDate: nil, extendedAttributes: nil, typeAndCreator: nil, validEntries: [])
        public static let emptyFolder = EntryMetadata(fileSystemFlags: [.userExecutable, .userWritable, .userReadable], lastUsedDate: nil,
                                                      tagData: nil, favoriteRank: nil, creationDate: nil, contentModificationDate: nil,
                                                      extendedAttributes: nil, typeAndCreator: nil, validEntries: [])

        public init(fileSystemFlags: NSFileProviderFileSystemFlags?, lastUsedDate: Date?, tagData: Data?, favoriteRank: Int?, creationDate: Date?,
                    contentModificationDate: Date?, extendedAttributes: ExtendedAttributes?, typeAndCreator: UInt64?, validEntries: ValidEntries?) {
            if let validEntries = validEntries {
                self.validEntries = validEntries
            } else {
                self.validEntries = [.fileSystemFlags, .lastUsedDate, .tagData, .creationDate,
                                     .contentModificationDate, .extendedAttributes, .typeAndCreator]
            }

            self.fileSystemFlags = fileSystemFlags
            self.lastUsedDate = lastUsedDate
            self.tagData = tagData
            self.creationDate = creationDate
            self.contentModificationDate = contentModificationDate
            self.extendedAttributes = extendedAttributes
            self.typeAndCreator = typeAndCreator
        }

        public func merge(_ other: EntryMetadata) -> EntryMetadata {
            let contentModDate = other.validEntries.contains(.contentModificationDate) ? other.contentModificationDate : self.contentModificationDate
            return EntryMetadata(
                fileSystemFlags: other.validEntries.contains(.fileSystemFlags) ? other.fileSystemFlags : self.fileSystemFlags,
                lastUsedDate: other.validEntries.contains(.lastUsedDate) ? other.lastUsedDate : self.lastUsedDate,
                tagData: other.validEntries.contains(.tagData) ? other.tagData : self.tagData,
                favoriteRank: nil,
                creationDate: other.validEntries.contains(.creationDate) ? other.creationDate : self.creationDate,
                contentModificationDate: contentModDate,
                extendedAttributes: other.validEntries.contains(.extendedAttributes) ? other.extendedAttributes : self.extendedAttributes,
                typeAndCreator: other.validEntries.contains(.typeAndCreator) ? other.typeAndCreator : self.typeAndCreator,
                validEntries: nil)
        }
    }

    public struct Entry: Codable {
        public struct UserInfo: Codable {
            public let conflictCount: Int?
            public let originatorName: String?
            public let symlinkTargetPath: String?
            public let implicitLockOwner: String?
            public let quotaRemaining: String?
            public let quotaTotal: String?

            public init(conflictCount: Int?, originatorName: String?, symlinkTargetPath: String?, implicitLockOwner: String?, quotaRemaining: String?,
                        quotaTotal: String?) {
                self.conflictCount = conflictCount
                self.originatorName = originatorName
                self.symlinkTargetPath = symlinkTargetPath
                self.implicitLockOwner = implicitLockOwner
                self.quotaRemaining = quotaRemaining
                self.quotaTotal = quotaTotal
            }
        }
        public let name: String
        public let id: ItemIdentifier
        public let parent: ItemIdentifier
        public let revision: Version
        public let deleted: Bool
        public let size: Int64
        public let children: Int?
        public let type: EntryType
        public let metadata: EntryMetadata
        public let userInfo: UserInfo

        public init(name: String, id: ItemIdentifier, parent: ItemIdentifier, revision: Version, deleted: Bool, size: Int64, children: Int?,
                    type: EntryType, metadata: EntryMetadata, userInfo: UserInfo) {
            self.name = name
            self.id = id
            self.parent = parent
            self.revision = revision
            self.deleted = deleted
            self.size = size
            self.children = children
            self.type = type
            self.metadata = metadata
            self.userInfo = userInfo
        }
    }
}

extension DomainService {
    public enum ContentStorageType: Codable, Equatable {
        private static let InlineIdentifierKey = "inlineIdentifier"
        private static let InChunkStoreIdentifierKey = "inChunkStoreIdentifier"
        private static let ResourceForkIdentifierKey = "resourceForkIdentifier"

        case inline
        case inChunkStore(contentSha256sOfDataChunks: ContentSha256S)
        case resourceFork

        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let enumType = try values.decode(String.self, forKey: .type)
            switch enumType {
                case ContentStorageType.InlineIdentifierKey:
                    self = .inline
                case ContentStorageType.InChunkStoreIdentifierKey:
                    self = .inChunkStore(contentSha256sOfDataChunks: try values.decode(ContentSha256S.self, forKey: .chunks))
                case ContentStorageType.ResourceForkIdentifierKey:
                    self = .resourceFork
                default:
                    print("unexpected enumType \(enumType)")
                    throw CommonError.internalError
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .inline:
                try container.encode(ContentStorageType.InlineIdentifierKey, forKey: .type)
            case .inChunkStore(let contentSha256sOfDataChunks):
                try container.encode(ContentStorageType.InChunkStoreIdentifierKey, forKey: .type)
                try container.encode(contentSha256sOfDataChunks, forKey: .chunks)
            case .resourceFork:
                try container.encode(ContentStorageType.ResourceForkIdentifierKey, forKey: .type)
            }
        }

        enum CodingKeys: String, CodingKey {
            case type
            case chunks
        }
    }

    public struct ContentSha256S: Codable, Equatable {
        public let hashList: [String]
        public let contentLength: Int64

        public init(contentSha256List: [String], contentLength: Int64) {
            self.hashList = contentSha256List
            self.contentLength = contentLength
        }
    }

    public enum ContentStorageTypeParameter: Equatable {
        case inline(data: Data)
        case inChunkStore(contentSha256sOfDataChunks: ContentSha256S)

        public func contentLength() -> Int64 {
            switch self {
            case .inline(let data):
                return Int64(data.count)
            case .inChunkStore(let contentSha256sOfDataChunks):
                return contentSha256sOfDataChunks.contentLength
            }
        }
    }

    public struct ListFolderParameter: JSONParameter {
        public typealias ReturnType = ListFolderReturn
        public static let endpoint = "list_folder"
        public static let method = JSONMethod.POST
        public let folderIdentifier: ItemIdentifier
        public let recursive: Bool
        public let startingCursor: Int64

        public init(folderIdentifier: ItemIdentifier, recursive: Bool, startingCursor: Int64? = nil) {
            self.folderIdentifier = folderIdentifier
            self.recursive = recursive
            self.startingCursor = startingCursor ?? 0
        }
    }

    public struct ListFolderReturn: Codable {
        public let entries: [Entry]
        public let deletedEntries: [ItemIdentifier]?
        public let cursor: Int64?
        public let rank: RankToken

        public init(entries: [Entry], deletedEntries: [ItemIdentifier]?, cursor: Int64?, rank: RankToken) {
            self.entries = entries
            self.deletedEntries = deletedEntries
            self.cursor = cursor
            self.rank = rank
        }
    }

    public struct ListChangesParameter: JSONParameter {
        public typealias ReturnType = ListChangesReturn
        public static let endpoint = "list_changes"
        public static let method = JSONMethod.POST
        public let folderIdentifier: ItemIdentifier
        public let recursive: Bool
        public let startingRank: RankToken

        public init(folderIdentifier: ItemIdentifier, recursive: Bool, startingRank: RankToken) {
            self.folderIdentifier = folderIdentifier
            self.recursive = recursive
            self.startingRank = startingRank
        }
    }
    public struct ListChangesReturn: Codable {
        public let entries: [Entry]
        public let deletedEntries: [ItemIdentifier]?
        public let rank: RankToken
        public let hasMore: Bool

        public init(entries: [Entry], deletedEntries: [ItemIdentifier]?, rank: RankToken, hasMore: Bool) {
            self.entries = entries
            self.deletedEntries = deletedEntries
            self.rank = rank
            self.hasMore = hasMore
        }
    }

    public struct LatestRankParameter: JSONParameter {
        public typealias ReturnType = LatestRankReturn
        public static let endpoint = "rank"
        public static let method = JSONMethod.POST
        public let folderIdentifier: ItemIdentifier

        public init(folderIdentifier: ItemIdentifier) {
            self.folderIdentifier = folderIdentifier
        }
    }

    public struct LatestRankReturn: Codable {
        public let rank: RankToken

        public init(rank: RankToken) {
            self.rank = rank
        }
    }

    public struct CreateParameter: JSONParameter {
        public typealias ReturnType = CreateReturn
        public static let endpoint = "create"
        public static let method = JSONMethod.POST
        public enum ConflictStrategy: String, Codable {
            case failOnExisting
            case updateAlreadyExisting
        }

        public let parent: ItemIdentifier
        public let name: String
        public let type: EntryType
        public let metadata: EntryMetadata
        public let conflictStrategy: ConflictStrategy
        public let contentStorageType: ContentStorageType?

        public init(parent: ItemIdentifier,
                    name: String,
                    type: EntryType,
                    metadata: EntryMetadata,
                    conflict: ConflictStrategy,
                    contentStorageType: ContentStorageType?) {
            self.parent = parent
            self.name = name
            self.type = type
            self.metadata = metadata
            self.conflictStrategy = conflict
            self.contentStorageType = contentStorageType
        }
    }

    public struct CreateReturn: Codable {
        public let item: Entry

        public init(item: Entry) {
            self.item = item
        }
    }

    // This does not include metadata to simulate a provider that does not do metadata
    // and content modifications together. However, it does break out initial upload
    // from subsequent updates.
    public struct ModifyContentsParameter: JSONParameter {
        public typealias ReturnType = ModifyContentsReturn
        public static let endpoint = "modifyContents"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier
        public let existingRevision: Version
        public let contentStorageType: ContentStorageType
        public let updateResourceForkOnConflictedItem: Bool

        public init(identifier: ItemIdentifier,
                    existingRevision: Version,
                    contentStorageType: ContentStorageType,
                    updateResourceForkOnConflictedItem: Bool = false) {
            self.identifier = identifier
            self.existingRevision = existingRevision
            self.contentStorageType = contentStorageType
            self.updateResourceForkOnConflictedItem = updateResourceForkOnConflictedItem
        }
    }

    public struct ModifyContentsReturn: Codable {
        public let item: Entry
        public let contentAccepted: Bool

        public init(item: Entry, contentAccepted: Bool) {
            self.item = item
            self.contentAccepted = contentAccepted
        }
    }

    public struct CreateDataChunkParameter: JSONParameter {
        public typealias ReturnType = CreateDataChunkReturn
        public static let endpoint = "createDataChunk"
        public static let method = JSONMethod.POST
        public let hexEncodedSha256OfData: String

        public init(hexEncodedSha256OfData: String) {
            self.hexEncodedSha256OfData = hexEncodedSha256OfData
        }
    }

    public struct CreateDataChunkReturn: Codable {
        public init() { }
    }

    public struct GetDataChunkParameter: JSONParameter {
        public typealias ReturnType = GetDataChunkReturn
        public static let endpoint = "getDataChunk"
        public static let method = JSONMethod.GET
        public let hexEncodedSha256OfData: String

        public init(hexEncodedSha256OfData: String) {
            self.hexEncodedSha256OfData = hexEncodedSha256OfData
        }
    }

    public struct GetDataChunkReturn: Codable {
        public init() { }
    }

    public struct CheckChunkExistsParameter: JSONParameter {
        public typealias ReturnType = CheckChunkExistsReturn
        public static let endpoint = "checkChunkExists"
        public static let method = JSONMethod.GET
        public let hexEncodedSha256OfChunksToCheck: Set<String>

        public init(hexEncodedSha256OfChunksToCheck: Set<String>) {
            self.hexEncodedSha256OfChunksToCheck = hexEncodedSha256OfChunksToCheck
        }
    }

    public struct CheckChunkExistsReturn: Codable {
        public let chunksThatExist: Set<String>
        public let chunksThatDoNotExist: Set<String>

        public init(chunksThatExist: Set<String>, chunksThatDoNotExist: Set<String>) {
            self.chunksThatExist = chunksThatExist
            self.chunksThatDoNotExist = chunksThatDoNotExist
        }
    }

    public struct ModifyMetadataParameter: JSONParameter {
        public typealias ReturnType = ModifyMetadataReturn
        public static let endpoint = "modifyMetadata"
        public static let method = JSONMethod.POST
        public let itemIdentifier: ItemIdentifier
        public let existingRevision: Version
        public let filename: String?
        public let parent: ItemIdentifier?
        public let metadata: EntryMetadata

        public init(itemIdentifier: ItemIdentifier, existingRevision: Version, filename: String?, parent: ItemIdentifier?, metadata: EntryMetadata) {
            self.itemIdentifier = itemIdentifier
            self.existingRevision = existingRevision
            self.filename = filename
            self.parent = parent
            self.metadata = metadata
        }
    }

    public struct ModifyMetadataReturn: Codable {
        public let item: Entry
        public let metadataWasRolledBack: Bool

        public init(item: Entry, metadataWasRolledBack: Bool) {
            self.item = item
            self.metadataWasRolledBack = metadataWasRolledBack
        }
    }

    public struct FetchItemParameter: JSONParameter {
        public typealias ReturnType = FetchItemReturn
        public static let endpoint = "info"
        public static let method = JSONMethod.POST
        public let itemIdentifier: ItemIdentifier

        public init(itemIdentifier: ItemIdentifier) {
            self.itemIdentifier = itemIdentifier
        }
    }

    public struct FetchItemReturn: Codable {
        public let item: Entry

        public init(item: Entry) {
            self.item = item
        }
    }

    public struct DownloadItemParameter: JSONParameter {
        public typealias ReturnType = DownloadItemReturn
        public static let endpoint = "download"
        public static let method = JSONMethod.GET
        public let itemIdentifier: ItemIdentifier
        public let requestedRevision: Version?
        public let resourceFork: Bool

        public init(itemIdentifier: ItemIdentifier, requestedRevision: Version?, resourceFork: Bool = false) {
            self.itemIdentifier = itemIdentifier
            self.requestedRevision = requestedRevision
            self.resourceFork = resourceFork
        }
    }

    public struct DownloadItemReturn: Codable {
        public let item: Entry

        public init(item: Entry) {
            self.item = item
        }
    }

    public struct FetchItemContentStorageTypeParameter: JSONParameter {
        public typealias ReturnType = FetchItemContentStorageTypeReturn
        public static let endpoint = "fetchItemContentStorageType"
        public static let method = JSONMethod.GET
        public let itemIdentifier: ItemIdentifier
        public let requestedRevision: Version

        public init(itemIdentifier: ItemIdentifier, requestedRevision: Version) {
            self.itemIdentifier = itemIdentifier
            self.requestedRevision = requestedRevision
        }
    }

    public struct FetchItemContentStorageTypeReturn: Codable {
        public let contentStorageType: ContentStorageType

        public init(contentStorageType: ContentStorageType) {
            self.contentStorageType = contentStorageType
        }
    }

    public struct DeleteItemParameter: JSONParameter {
        public typealias ReturnType = DeleteItemReturn
        public static let endpoint = "delete"
        public static let method = JSONMethod.DELETE
        public let itemIdentifier: ItemIdentifier
        public let existingRevision: Version
        public let recursiveDelete: Bool
        public init(itemIdentifier: ItemIdentifier, existingRevision: Version, recursiveDelete: Bool) {
            self.itemIdentifier = itemIdentifier
            self.existingRevision = existingRevision
            self.recursiveDelete = recursiveDelete
        }
    }
    public struct DeleteItemReturn: Codable {
        public init() { }
    }

    public struct TrashItemParameter: JSONParameter {
        public typealias ReturnType = TrashItemReturn
        public static let endpoint = "trash"
        public static let method = JSONMethod.POST
        public let itemIdentifier: ItemIdentifier
        public let existingRevision: Version

        public init(itemIdentifier: ItemIdentifier, existingRevision: Version) {
            self.itemIdentifier = itemIdentifier
            self.existingRevision = existingRevision
        }
    }
    public struct TrashItemReturn: Codable {
        public let item: Entry
        public let metadataWasRolledBack: Bool

        public init(item: Entry, metadataWasRolledBack: Bool) {
            self.item = item
            self.metadataWasRolledBack = metadataWasRolledBack
        }
    }

    public struct UpdateThumbnailParameter: JSONParameter {
        public typealias ReturnType = UpdateThumbnailReturn
        public static let endpoint = "updateThumbnail"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier
        public let existingRevision: Version

        public init(identifier: ItemIdentifier, existingRevision: Version) {
            self.identifier = identifier
            self.existingRevision = existingRevision
        }
    }

    public struct UpdateThumbnailReturn: Codable {
        public let item: Entry

        public init(item: Entry) {
            self.item = item
        }
    }

    public struct FetchThumbnailParameter: JSONParameter {
        public typealias ReturnType = FetchThumbnailReturn
        public static let endpoint = "thumbnail"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier
        public let requestedRevision: Version?

        public init(identifier: ItemIdentifier, requestedRevision: Version?) {
            self.identifier = identifier
            self.requestedRevision = requestedRevision
        }
    }

    public struct FetchThumbnailReturn: Codable {
        public let item: Entry

        public init(item: Entry) {
            self.item = item
        }
    }

    public struct ConflictVersionsParameter: JSONParameter {
        public typealias ReturnType = ConflictVersionsReturn
        public static let endpoint = "conflicts/list"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier

        public init(identifier: ItemIdentifier) {
            self.identifier = identifier
        }
    }
    public struct ConflictVersionsReturn: Codable {
        public let versions: [ConflictVersion]
        public let currentVersion: Version

        public init(versions: [ConflictVersion], currentVersion: Version) {
            self.versions = versions
            self.currentVersion = currentVersion
        }
    }

    public struct ResolveConflictVersionsParameter: JSONParameter {
        public typealias ReturnType = ResolveConflictVersionsReturn
        public static let endpoint = "conflicts/resolve"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier
        public let versionsToKeep: [Int64]
        public let baseVersion: Version

        public init(identifier: ItemIdentifier, versionsToKeep: [Int64], baseVersion: Version) {
            self.identifier = identifier
            self.versionsToKeep = versionsToKeep
            self.baseVersion = baseVersion
        }
    }
    public struct ResolveConflictVersionsReturn: Codable {
        public init() { }
    }

    public struct CreateConflictParameter: JSONParameter {
        public typealias ReturnType = CreateConflictReturn
        public static let endpoint = "conflicts/create"
        public static let method = JSONMethod.POST
        public let identifier: ItemIdentifier
        public let originator: String

        public init(identifier: ItemIdentifier, originator: String) {
            self.identifier = identifier
            self.originator = originator
        }
    }

    public struct CreateConflictReturn: Codable {
        public let entry: Entry

        public init(entry: Entry) {
            self.entry = entry
        }
    }

    public struct MarkParameter: JSONParameter {
        public typealias ReturnType = MarkReturn
        public static let endpoint = "mark"
        public static let method = JSONMethod.POST
        public static let heartXattr: String = {
            let base = "com.example.fruitbasket.heart"
            return String(cString: xattr_name_with_flags(base, XATTR_FLAG_SYNCABLE | XATTR_FLAG_NO_EXPORT))
        }()
        public static let pinnedXattr: String = {
            // Pinning state is stored as an xattr and syncs across domains,
            // which is quite unrealistic
            let base = "com.example.fruitbasket.pinned"
            return String(cString: xattr_name_with_flags(base, XATTR_FLAG_SYNCABLE | XATTR_FLAG_NO_EXPORT))
        }()
        public static let isSharedXattr: String = {
            let base = "com.example.fruitbasket.isShared"
            return String(cString: xattr_name_with_flags(base, XATTR_FLAG_SYNCABLE | XATTR_FLAG_NO_EXPORT))
        }()

        public let identifiers: [ItemIdentifier]
        public let heart: Bool?
        public let inUse: String?
        public let pinned: Bool?
        public let isShared: Bool?

        public init(identifiers: [ItemIdentifier], heart: Bool? = nil, inUse: String? = nil, pinned: Bool? = nil, isShared: Bool? = nil) {
            self.identifiers = identifiers
            self.heart = heart
            self.inUse = inUse
            self.pinned = pinned
            self.isShared = isShared
        }
    }

    public struct MarkReturn: Codable {
        public init() { }
    }

    public struct PingLockParameter: JSONParameter {
        public typealias ReturnType = PingLockReturn
        public static let endpoint = "lock/ping"
        public static let method = JSONMethod.POST

        // The file gets unlocked automatically if we don't hear from the client for this long
        public static let unlockInterval = TimeInterval(30)
        // The interval for client pings
        public static let pingInterval = unlockInterval * (2.0 / 3.0)

        public let identifier: ItemIdentifier
        public let owner: String
        public let enumerationIndex: Int64

        public init(identifier: ItemIdentifier, owner: String, enumerationIndex: Int64) {
            self.identifier = identifier
            self.owner = owner
            self.enumerationIndex = enumerationIndex
        }
    }
    public struct PingLockReturn: Codable {
        public init() { }
    }

    public struct RemoveLockParameter: JSONParameter {
        public typealias ReturnType = RemoveLockReturn
        public static let endpoint = "lock/remove"
        public static let method = JSONMethod.POST

        public let identifier: ItemIdentifier
        public let enumerationIndex: Int64

        public init(identifier: ItemIdentifier, enumerationIndex: Int64) {
            self.identifier = identifier
            self.enumerationIndex = enumerationIndex
        }
    }

    public struct RemoveLockReturn: Codable {
        public init() { }
    }

    public struct ForceLockParameter: JSONParameter {
        public typealias ReturnType = ForceLockReturn
        public static let endpoint = "lock/force"
        public static let method = JSONMethod.POST

        public let identifier: ItemIdentifier

        public init(identifier: ItemIdentifier) {
            self.identifier = identifier
        }
    }

    public struct ForceLockReturn: Codable {
        public init() { }
    }
}

extension DomainService {
    public struct PushRegistrationParameter: JSONParameter {
        public typealias ReturnType = PushRegistrationReturn
        public static let endpoint = "push/register"
        public static let method = JSONMethod.POST
        public static let refreshInterval = TimeInterval(60 * 60 * 6)

        public let token: Data
        public let bundleIdentifier: String

        public init(token: Data, bundleIdentifier: String) {
            self.token = token
            self.bundleIdentifier = bundleIdentifier
        }
    }
    public struct PushRegistrationReturn: Codable {
        public init() { }
    }

    public struct PushDevice: Hashable {
        public typealias Token = String
        public typealias PushTopic = String
        public let token: Token
        public let topic: PushTopic

        public init(token: Token, topic: PushTopic) {
            self.token = token
            self.topic = topic
        }
    }
}

extension DomainService {
    public struct SimulatedError: Codable {
        public enum AccessType: String, Codable {
            case read
            case write
        }

        public let domain: String
        public let code: Int
        public let localizedDescription: String?

        public init(domain: String, code: Int, localizedDescription: String?) {
            self.domain = domain
            self.code = code
            self.localizedDescription = localizedDescription
        }
    }

    public struct SimulateErrorParameter: JSONParameter {
        public typealias ReturnType = SimulateErrorReturn
        public static let endpoint = "error/debug/set"
        public static let method = JSONMethod.POST

        public let identifier: ItemIdentifier
        public let accessType: SimulatedError.AccessType
        public let error: SimulatedError?

        public init(identifier: ItemIdentifier, accessType: SimulatedError.AccessType, error: SimulatedError?) {
            self.identifier = identifier
            self.error = error
            self.accessType = accessType
        }
    }
    public struct SimulateErrorReturn: Codable {
        public init() { }
    }

    public struct SimulateErrorListParameter: JSONParameter {
        public typealias ReturnType = SimulateErrorListReturn
        public static let endpoint = "error/debug/list"
        public static let method = JSONMethod.POST

        public init() { }
    }
    public struct SimulateErrorListReturn: Codable {
        public let errors: [ItemIdentifier: [SimulatedError.AccessType: SimulatedError]]

        public init(errors: [ItemIdentifier: [SimulatedError.AccessType: SimulatedError]]) {
            self.errors = errors
        }
    }

    public struct ListLocksParameter: JSONParameter {
        public typealias ReturnType = ListLocksReturn
        public static let endpoint = "lock/debug/list"
        public static let method = JSONMethod.POST

        public init() { }
    }
    public struct ListLocksReturn: Codable {
        public struct Lock: Codable {
            public let itemIdentifier: ItemIdentifier
            public let enumerationIndex: Int64
            public let timeout: Date
            public let owner: String

            public init(itemIdentifier: ItemIdentifier, enumerationIndex: Int64, timeout: Date, owner: String) {
                self.itemIdentifier = itemIdentifier
                self.enumerationIndex = enumerationIndex
                self.timeout = timeout
                self.owner = owner
            }
        }
        public let locks: [Lock]

        public init(locks: [ListLocksReturn.Lock]) {
            self.locks = locks
        }
    }
}
