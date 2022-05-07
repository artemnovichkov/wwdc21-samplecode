/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The diffable data source class that provides image items for a collection view.
*/

import UIKit

typealias DiffableImageSource = UICollectionViewDiffableDataSource<Int, ImageItem>
typealias DiffableImageSourceSnapshot = NSDiffableDataSourceSnapshot<Int, ImageItem>

struct ImageItem: Hashable {
    let uniqueName: String
    let thumbnail: UIImage?
    
    // Only uniqueName matters for Hashable and Equatable.
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        return lhs.uniqueName == rhs.uniqueName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueName)
    }
}
