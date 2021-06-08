/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extensions on various objects for use throughout the project.
*/

import Foundation
import FileProvider

public extension NSFileProviderDomainIdentifier {
    var port: in_port_t? {
        if let separatorPosition = rawValue.lastIndex(of: "+"),
            let port = in_port_t(rawValue[rawValue.index(after: separatorPosition)...]) {
            return port
        }
        return nil
    }
}

// Conversions to and from Int64 used with the domain service version content.
extension Data {
    fileprivate init(_ revision: Int64) {
        self = Swift.withUnsafeBytes(of: revision) { Data($0) }
    }

    fileprivate func toInt64() -> Int64 {
        var ret: Int64 = 0
        _ = Swift.withUnsafeMutableBytes(of: &ret) { ptr in
            self.copyBytes(to: ptr)
        }
        return ret
    }
}

extension NSFileProviderItemVersion {
    public convenience init(_ version: DomainService.Version) {
        self.init(contentVersion: Data(version.content), metadataVersion: Data(version.metadata))
    }
}

extension NSFileProviderTypeAndCreator {
    public init(_ rawValue: UInt64) {
        let creator = UInt32(truncatingIfNeeded: rawValue)
        let type = UInt32(rawValue >> 32)
        self.init(type: type, creator: creator)
    }

    public func rawValue() -> UInt64 {
        var rawValue = UInt64(self.creator)
        rawValue |= UInt64(self.type) << 32
        return rawValue
    }
}

extension DomainService.Version {
    public init(_ version: NSFileProviderItemVersion) {
        self = DomainService.Version(content: version.contentVersion.toInt64(), metadata: version.metadataVersion.toInt64())
    }
}

extension DomainService.EntryMetadata {
    public init(_ itemTemplate: NSFileProviderItemProtocol, _ fields: NSFileProviderItemFields) {
        var valid: DomainService.EntryMetadata.ValidEntries = []
        if fields.contains(.lastUsedDate),
            let value = itemTemplate.lastUsedDate {
            self.lastUsedDate = value
            valid.insert(.lastUsedDate)
        } else {
            self.lastUsedDate = nil
        }

        if fields.contains(.fileSystemFlags),
            let value = itemTemplate.fileSystemFlags {
            self.fileSystemFlags = value
            valid.insert(.fileSystemFlags)
        } else {
            self.fileSystemFlags = nil
        }

        if fields.contains(.tagData),
            let value = itemTemplate.tagData {
            self.tagData = value
            valid.insert(.tagData)
        } else {
            self.tagData = nil
        }

        if fields.contains(.creationDate),
            let value = itemTemplate.creationDate {
            self.creationDate = value
            valid.insert(.creationDate)
        } else {
            self.creationDate = nil
        }

        if fields.contains(.contentModificationDate),
            let value = itemTemplate.contentModificationDate {
            self.contentModificationDate = value
            valid.insert(.contentModificationDate)
        } else {
            self.contentModificationDate = nil
        }

        if fields.contains(.extendedAttributes),
            let attrs = itemTemplate.extendedAttributes {
            self.extendedAttributes = ExtendedAttributes(values: attrs)
            valid.insert(.extendedAttributes)
        } else {
            self.extendedAttributes = nil
        }

        if fields.contains(.typeAndCreator),
            let osType = itemTemplate.typeAndCreator {
            self.typeAndCreator = osType.rawValue()
            valid.insert(.typeAndCreator)
        } else {
            self.typeAndCreator = nil
        }

        validEntries = valid
    }
}
