/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility methods for restoring a collection view to a certain selection state — expanding parents of selected leaf nodes.
*/

import UIKit

extension UICollectionView {
    func deselectAll() {
        indexPathsForSelectedItems?.forEach { indexPath in
            deselectItem(at: indexPath, animated: false)
        }
    }

    /// Expands all parent sections, and select the leaf identifiers
    func expandParentsToShow<Section: Hashable, Identifier: Hashable>(
        leafItemIdentifiers: [Identifier],
        dataSource: UICollectionViewDiffableDataSource<Section, Identifier>) {
        let topSnapshot = dataSource.snapshot()
        for itemIdentifier in leafItemIdentifiers {
            let sectionIdentifiers = topSnapshot.sectionIdentifiers
            for sectionIdentifier in sectionIdentifiers {
                var sectionSnapshot = dataSource.snapshot(for: sectionIdentifier)
                let itemWasExpanded = sectionSnapshot.recursivelyExpandToShow(item: itemIdentifier)
                dataSource.apply(sectionSnapshot, to: sectionIdentifier)
                if itemWasExpanded {
                    break
                }
            }
        }
    }
}

extension NSDiffableDataSourceSectionSnapshot {
    mutating func recursivelyExpandToShow(item: ItemIdentifierType) -> Bool {
        var itemWasFound = false
        var itemsToExpand = [ItemIdentifierType]()
        var currentItem = item
        while contains(item), let parentItem = parent(of: currentItem) {
            itemWasFound = true
            itemsToExpand.append(parentItem)
            currentItem = parentItem
        }
        expand(itemsToExpand)
        return itemWasFound
    }
}
