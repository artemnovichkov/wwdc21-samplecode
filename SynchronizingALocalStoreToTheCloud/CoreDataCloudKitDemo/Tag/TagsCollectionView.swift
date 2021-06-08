/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom UICollectionView and UICollectionViewFlowLayout subclass for presenting tags.
*/

import UIKit

class TagsCollectionView: UICollectionView {
    override var intrinsicContentSize: CGSize {
        return collectionViewLayout.collectionViewContentSize
    }
}

/**
 A custom flow layout to align the tags to the left and use fixed spacing between items.
 
 This tag collectionView is a simple use case that uses a specific-purpose layout to align the items quickly.
 */
class TagsFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let defaultAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        // UICollectionViewFlowLayout flows the items sequentially and should have laid out the items in the right rows.
        // Adjust the item’s originX to make it align.
        var finalLayoutAttributes = [UICollectionViewLayoutAttributes]()
        var originX = sectionInset.left, maxY = sectionInset.top
        
        for attribute in defaultAttributes {
            if let newAttribute = attribute.copy() as? UICollectionViewLayoutAttributes {
                if newAttribute.frame.origin.y >= maxY {
                    originX = sectionInset.left
                }
                newAttribute.frame.origin.x = originX
                finalLayoutAttributes.append(newAttribute)

                originX += attribute.frame.width + minimumInteritemSpacing
                maxY = max(attribute.frame.maxY, maxY)
            }
        }
        return finalLayoutAttributes
    }
}
