/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A subclass of NSCoreDataCoreSpotlightDelegate.
*/

import Foundation
import CoreData
import CoreSpotlight

class TagsSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func domainIdentifier() -> String {
        return "com.example.apple-samplecode.tags"
    }

    override func indexName() -> String? {
        return "tags-index"
    }
    
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        if let photo = object as? Photo {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .image)
            attributeSet.identifier = photo.uniqueName
            attributeSet.displayName = photo.userSpecifiedName
            attributeSet.thumbnailData = photo.thumbnail?.data

            for case let tag as Tag in photo.tags ?? [] {
                if let name = tag.name {
                    if attributeSet.keywords != nil {
                        attributeSet.keywords?.append(name)
                    } else {
                        attributeSet.keywords = [name]
                    }
                }
            }

            return attributeSet
        } else if let tag = object as? Tag {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.displayName = tag.name
            return attributeSet
        }

        return nil
    }
}
