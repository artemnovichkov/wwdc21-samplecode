/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The interaction protocol between DetailViewController, AttachmentCollectionCell, and AttachmentCVCell.
*/

import UIKit

protocol AttachmentInteractionDelegate: AnyObject {
    /**
     Presents the full image.
     
     When the user taps a cell, the cell calls this method to notify the delegate (the detail view controller) to present the the associated image.
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    
    /**
     Deletes the attachment.
     
     When the user deletes a cell, the cell calls this method to notify the delegate (the detail view controller) to delete the attachment.
     */
    func delete(attachment: Attachment, at indexPath: IndexPath)
}
