/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The UICollectionViewCell subclass that shows a thumbnail in UICollectionView.
*/

import UIKit

protocol TagsImageCellDelegate: AnyObject {
    func deleteCell(_ cell: UICollectionViewCell)
    func tagCell(_ cell: UICollectionViewCell)
}

class TagsImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var tagButton: UIButton!

    weak var delegate: TagsImageCellDelegate?
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegate?.deleteCell(self)
    }
    
    @IBAction func tagAction(_ sender: Any) {
        delegate?.tagCell(self)
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .systemGray : .systemGray6
        }
    }
}
