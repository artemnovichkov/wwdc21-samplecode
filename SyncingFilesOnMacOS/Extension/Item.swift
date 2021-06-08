/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A file system item, such as a file or directory.
*/

import FileProvider
import Common
import CoreServices
import UniformTypeIdentifiers

protocol XAttrGettable: Codable {
    var includeAsExtendedAttribute: Bool { get }
}

extension String: XAttrGettable {
    var includeAsExtendedAttribute: Bool {
        return !isEmpty
    }

}

extension Bool: XAttrGettable {
    var includeAsExtendedAttribute: Bool {
        return self
    }
}

class Item: NSObject, NSFileProviderItemProtocol, NSFileProviderItemDecorating {
    let entry: DomainService.Entry

    let itemIdentifier: NSFileProviderItemIdentifier
    let parentItemIdentifier: NSFileProviderItemIdentifier
    let itemVersion: NSFileProviderItemVersion

    init(_ entry: DomainService.Entry) {
        self.entry = entry
        itemIdentifier = NSFileProviderItemIdentifier(entry.id)
        parentItemIdentifier = NSFileProviderItemIdentifier(entry.parent)
        itemVersion = NSFileProviderItemVersion(entry.revision)
    }

    var filename: String {
        return entry.name
    }
    var contentType: UTType {
        switch entry.type {
        case .folder, .root:
            return .folder
        case .file:
            return .item
        case .symlink:
            return .symbolicLink
        case .alias:
            return .aliasFile
        }
    }
    var typeAndCreator: NSFileProviderTypeAndCreator {
        if let typeAndCreator = entry.metadata.typeAndCreator {
            return NSFileProviderTypeAndCreator(typeAndCreator)
        } else {
            return NSFileProviderTypeAndCreator(type: 0, creator: 0)
        }
    }

    var capabilities: NSFileProviderItemCapabilities {
        var result: NSFileProviderItemCapabilities = [
            .allowsAddingSubItems,
            .allowsContentEnumerating,
            .allowsDeleting,
            .allowsReading,
            .allowsRenaming,
            .allowsReparenting,
            .allowsWriting,
            .allowsEvicting,
            .allowsExcludingFromSync
        ]
        if !UserDefaults.sharedContainerDefaults.trashDisabled {
            result.insert(.allowsTrashing)
        }
        if let isPinned = self.userInfo?["pinned"] as? Bool, isPinned {
            result.remove(.allowsEvicting)
        }
        return result
    }

    var documentSize: NSNumber? {
        return entry.size as NSNumber
    }

    var childItemCount: NSNumber? {
        return entry.children as NSNumber?
    }

    var lastUsedDate: Date? {
        return entry.metadata.lastUsedDate
    }

    var tagData: Data? {
        return entry.metadata.tagData
    }

    var creationDate: Date? {
        return entry.metadata.creationDate
    }

    var contentModificationDate: Date? {
        return entry.metadata.contentModificationDate
    }

    var extendedAttributes: [String: Data] {
        return entry.metadata.extendedAttributes?.values ?? [:]
    }

    static let decorationPrefix = Bundle.main.bundleIdentifier!
    static let conflictDecoration = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).hasConflict")
    static let lastEditDecoration = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).lastEdited")
    static let heartDecoration = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).heart")
    static let inUseDecoration = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).inUse")
    static let pictureFolder = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).pictureFolder")
    static let pinnedDecoration = NSFileProviderItemDecorationIdentifier(rawValue: "\(decorationPrefix).pinned")

    // This property demonstrates two ways of determining decorations: by an entry's
    // userInfo and by the presence of an extended attribute.
    var decorations: [NSFileProviderItemDecorationIdentifier]? {
        var decos = [NSFileProviderItemDecorationIdentifier]()

        // These attributes are set depending on keys in the entry's userInfo.
        if let conflictCount = entry.userInfo.conflictCount,
            conflictCount > 0 {
            decos.append(Item.conflictDecoration)
        }
        if entry.userInfo.originatorName != nil {
            decos.append(Item.lastEditDecoration)
        }
        if entry.userInfo.implicitLockOwner != nil {
            decos.append(Item.inUseDecoration)
        }

        // This attribute is set depending on whether a specific extended attribute is present.
        func addDecoForXattr<T: XAttrGettable>(_ deco: NSFileProviderItemDecorationIdentifier, _ type: T.Type, _ xattr: String) {
            if let fav = entry.metadata.extendedAttributes?.values[xattr] {
                if let val = try? JSONDecoder().decode(type, from: fav) {
                    if val.includeAsExtendedAttribute {
                        decos.append(deco)
                    }
                }
            }
        }
        addDecoForXattr(Item.heartDecoration, Bool.self, DomainService.MarkParameter.heartXattr)
        addDecoForXattr(Item.pinnedDecoration, Bool.self, DomainService.MarkParameter.pinnedXattr)

        let pictureFolderNames = ["Images", "Pictures", "Photos"]
        if entry.type == .folder,
            pictureFolderNames.contains(entry.name) {
            decos.append(Item.pictureFolder)
        }

        return decos
    }

    public static let injectUserInfoXattr: String = {
        let base = "com.example.fruitbasket.injectUserInfo"
        return String(cString: xattr_name_with_flags(base, XATTR_FLAG_SYNCABLE | XATTR_FLAG_NO_EXPORT))
    }()

    var userInfo: [AnyHashable: Any]? {
        var ret = [AnyHashable: Any]()
        // Expose keys in the entry's userInfo as part of the item. They are used
        // to determine eligibility of actions, for interaction predicates, and
        // as input for decoration descriptions.
        if let val = entry.userInfo.conflictCount {
            ret["conflictCount"] = val
        }
        if let val = entry.userInfo.originatorName {
            ret["originatorName"] = val
        }
        if let val = entry.userInfo.implicitLockOwner {
            ret["inUse"] = val
        }
        if let val = entry.userInfo.quotaRemaining {
            ret["quotaRemaining"] = val
        }
        if let val = entry.userInfo.quotaTotal {
            ret["quotaTotal"] = val
        }

        // This key is not part of the item's userInfo, but depends on an extended
        // attribute. It is needed to determine an action eligibility, so it must
        // be explicitly added to the item's userInfo.
        func setInfoIfXattr<T: XAttrGettable>(_ info: String, _ type: T.Type, _ xattr: String) {
            if let fav = entry.metadata.extendedAttributes?.values[xattr],
                let val = try? JSONDecoder().decode(type, from: fav),
                val.includeAsExtendedAttribute {
                ret[info] = val
            }
        }
        setInfoIfXattr("heart", Bool.self, DomainService.MarkParameter.heartXattr)
        setInfoIfXattr("pinned", Bool.self, DomainService.MarkParameter.pinnedXattr)
        setInfoIfXattr("isShared.inherited", Bool.self, DomainService.MarkParameter.isSharedXattr)

        // Read injectUserInfoXattr as a dictionary and add any entries found.
        // e.g. `xattr -w com.example.fruitbasket.injectUserInfo#PS "{ \"arbitrary\": \"value\" }" file.txt`
        if let fav = entry.metadata.extendedAttributes?.values[Self.injectUserInfoXattr],
           let values = try? JSONSerialization.jsonObject(with: fav, options: []) as? [String: Any] {
            values.forEach { (key: String, value: Any) in
                if value is NSNumber || value is String {
                    ret[key] = value
                }
            }
        }
        return ret
    }

    var symlinkTargetPath: String? {
        return entry.userInfo.symlinkTargetPath
    }

    var fileSystemFlags: NSFileProviderFileSystemFlags {
        return entry.metadata.fileSystemFlags ?? []
    }
}

extension NSFileProviderItemIdentifier {
    public init(_ id: DomainService.ItemIdentifier) {
        if id == DomainConnection.rootItemIdentifier {
            self = .rootContainer
        } else if id == DomainConnection.trashItemIdentifier {
            self = .trashContainer
        } else {
            self.init("\(id.id)")
        }
    }
}

extension DomainService.ItemIdentifier {
    public init(_ id: NSFileProviderItemIdentifier) {
        if id == .rootContainer {
            self = DomainConnection.rootItemIdentifier
        } else if id == .trashContainer {
            self = DomainConnection.trashItemIdentifier
        } else {
            guard let value = Int64(id.rawValue) else {
                fatalError("unknown item identifier \(id)")
            }
            self = DomainService.ItemIdentifier(value)
        }
    }
}
