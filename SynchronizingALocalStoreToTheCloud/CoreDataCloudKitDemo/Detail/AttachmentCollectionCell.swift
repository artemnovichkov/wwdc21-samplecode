/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UITableViewCell subclass that implements UICollectionViewDelegate and UICollectionViewDataSource to present the current post’s attachments.
*/

import UIKit

class AttachmentCollectionCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    weak var delegate: AttachmentInteractionDelegate?
    var post: Post?
    
    /**
     An array of valid attachments. Use this to filter out attachments that don’t have valid image data and thumbnail.
     
     To avoid unnecessarily loading image data into memory, each Attachment has a one-to-one relationship with an ImageData.
     
     The attachment and image data are not guaranteed to sync atomically, so there may be an attachment that doesn’t have the real image data.
     */
    private var validAttachments = [Attachment]()

    /**
     Reload collectionView to change the editing status of the cells.
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        guard isEditing != editing else { return }
        
        super.setEditing(editing, animated: animated)
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    
    /**
     Filter the list of valid attachments every time the UICollectionView reloads data.
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let post = post, let attachments = post.attachments?.allObjects as? [Attachment] else { return 0 }

        // A newly added attachment by this peer doesn’t have imageData, but getThumbnail() should immediately return with the .thumbnail.
        validAttachments = attachments.filter { return !($0.imageData == nil && $0.getThumbnail() == nil) }
        return validAttachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cvCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "attachmentCVCell", for: indexPath) as? AttachmentCVCell else {
            fatalError("###\(#function): Failed to dequeue AttachmentCVCell! Check the cell reusable identifier in Main.storyboard.")
        }
        let attachment = validAttachments[indexPath.row]
        
        cvCell.attachment = attachment
        cvCell.delegate = delegate
        cvCell.indexPath = indexPath
        
        if let thumnail = attachment.getThumbnail() {
            cvCell.imageView.image = thumnail
        }
        cvCell.imageView.alpha = isEditing ? 0.4 : 1
        cvCell.deleteButton.alpha = isEditing ? 1 : 0
        return cvCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView(collectionView, didSelectItemAt: indexPath)
    }
}
