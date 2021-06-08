/*
See LICENSE folder for this sample’s licensing information.

Abstract:
String descriptions for common filesystem objects.
*/

import Foundation
import FileProvider

// CustomStringConvertible conformances for common objects.

extension DomainService.EntryType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .file:
            return ".file"
        case .folder:
            return ".folder"
        case .root:
            return ".root"
        case .symlink:
            return ".symlink"
        case .alias:
            return ".alias"
        }
    }
}

extension DomainService.Version: CustomStringConvertible {
    public var description: String {
        return "v(\(content), \(metadata))"
    }
}

extension DomainService.ItemIdentifier: CustomStringConvertible {
    public var description: String {
        return "#\(id)"
    }
}

extension DomainService.EntryMetadata.ValidEntries: CustomStringConvertible {
    public var description: String {
        var parts = [String]()
        var options = self
        if options.contains(.fileSystemFlags) {
            parts.append(".fileSystemFlags")
            options.remove(.fileSystemFlags)
        }
        if options.contains(.lastUsedDate) {
            parts.append(".lastUsedDate")
            options.remove(.lastUsedDate)
        }
        if options.contains(.tagData) {
            parts.append(".tagData")
            options.remove(.tagData)
        }
        if options.contains(.favoriteRank) {
            options.remove(.favoriteRank)
        }
        if options.contains(.creationDate) {
            parts.append(".creationDate")
            options.remove(.creationDate)
        }
        if options.contains(.contentModificationDate) {
            parts.append(".contentModificationDate")
            options.remove(.contentModificationDate)
        }
        if options.contains(.extendedAttributes) {
            parts.append(".extendedAttributes")
            options.remove(.extendedAttributes)
        }
        if options.contains(.typeAndCreator) {
            parts.append(".typeAndCreator")
            options.remove(.typeAndCreator)
        }
        assert(options.isEmpty, "Unhandled option")
        return "[\(parts.joined(separator: ", "))]"
    }
}

extension NSFileProviderFileSystemFlags: CustomStringConvertible {
    public var description: String {
        var options = self
        var ret = ""
        if options.contains(.userReadable) {
            ret += "r"
            options.remove(.userReadable)
        } else {
            ret += "-"
        }
        if options.contains(.userWritable) {
            ret += "w"
            options.remove(.userWritable)
        } else {
            ret += "-"
        }
        if options.contains(.userExecutable) {
            ret += "x"
            options.remove(.userExecutable)
        } else {
            ret += "-"
        }
        if options.contains(.hidden) {
            ret += "h"
            options.remove(.hidden)
        } else {
            ret += "-"
        }
        if options.contains(.pathExtensionHidden) {
            ret += "e"
            options.remove(.pathExtensionHidden)
        } else {
            ret += "-"
        }
        assert(options.isEmpty, "Unhandled option")
        return ret
    }
}

extension DomainService.EntryMetadata: CustomStringConvertible {
    public var description: String {
        var options = validEntries
        var parts = [String]()

        if options.contains(.fileSystemFlags) {
            parts.append("fileSystemFlags: \(String(describing: fileSystemFlags))")
            options.remove(.fileSystemFlags)
        }
        if options.contains(.lastUsedDate) {
            parts.append("lastUsedDate: \(String(describing: lastUsedDate))")
            options.remove(.lastUsedDate)
        }
        if options.contains(.tagData) {
            parts.append("tagData: \(String(describing: tagData))")
            options.remove(.tagData)
        }
        if options.contains(.favoriteRank) {
            options.remove(.favoriteRank)
        }
        if options.contains(.creationDate) {
            parts.append("creationDate: \(String(describing: creationDate))")
            options.remove(.creationDate)
        }
        if options.contains(.contentModificationDate) {
            parts.append("contentModificationDate: \(String(describing: contentModificationDate))")
            options.remove(.contentModificationDate)
        }
        if options.contains(.extendedAttributes) {
            parts.append("extendedAttributes: \(String(describing: extendedAttributes))")
            options.remove(.extendedAttributes)
        }
        if options.contains(.typeAndCreator) {
            parts.append("typeAndCreator: \(String(describing: typeAndCreator))")
            options.remove(.typeAndCreator)
        }
        assert(options.isEmpty, "Unhandled option")
        return "EntryMetadata(\(parts.joined(separator: ", ")))"
    }
}

extension Common.DomainService.Entry.UserInfo: CustomStringConvertible {
    public var description: String {
        var parts = [String]()
        if let conflictCount = conflictCount {
            parts.append("conflictCount: \(conflictCount)")
        }
        if let originatorName = originatorName {
            parts.append("originatorName: \(originatorName)")
        }
        if let symlinkTargetPath = symlinkTargetPath {
            parts.append("symlinkTargetPath: \(symlinkTargetPath)")
        }
        if let implicitLockOwner = implicitLockOwner {
            parts.append("implicitLockOwner: \(implicitLockOwner)")
        }
        if let quotaRemaining = quotaRemaining {
            parts.append("quotaRemaining: \(quotaRemaining)")
        }
        if let quotaTotal = quotaTotal {
            parts.append("quotaTotal: \(quotaTotal)")
        }

        return "UserInfo(\(parts.joined(separator: ", ")))"
    }
}

extension Common.DomainService.SimulatedError.AccessType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .read:
            return ".read"
        case .write:
            return ".write"
        }
    }
}

extension Common.DomainService.SimulatedError: CustomStringConvertible {
    public var description: String {
        return "(domain: \(domain), code: \(code)"
    }
}
