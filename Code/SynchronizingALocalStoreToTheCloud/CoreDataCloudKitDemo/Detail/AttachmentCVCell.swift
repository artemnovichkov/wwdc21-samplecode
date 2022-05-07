/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UICollectionViewCell subclass to show a thumbnail in UICollectionView.
*/

import UIKit

class AttachmentCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    weak var delegate: AttachmentInteractionDelegate?
    var attachment: Attachment!
    var indexPath: IndexPath!
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegate?.delete(attachment: attachment, at: indexPath)
    }
}
