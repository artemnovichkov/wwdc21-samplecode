/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UITableViewCell subclass for showing a post.
*/

import UIKit

class PostCell: TagCollectionCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var hasAttachmentLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        collectionView.backgroundColor = .clear
        super.setSelected(selected, animated: animated)
    }
}
