/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UICollectionView subclass for displaying the product's data.
*/

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "reuseIdentifier"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!

    func configureCell(with product: Product) {
        imageView.image = UIImage(named: product.imageName)
        label.text = product.name
    }

}
