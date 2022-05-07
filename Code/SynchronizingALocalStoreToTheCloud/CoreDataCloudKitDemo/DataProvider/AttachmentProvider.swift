/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to wrap everything related to creating and deleting attachments, and saving and deleting image data.
*/

import UIKit
import CoreData

class AttachmentProvider {
    private(set) var persistentContainer: NSPersistentContainer
    
    init(with persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    /**
     Create an Attachment. Note that ".thumbnail" is a transient attribute and is not persisted to the store.
     */
    func addAttachment(imageData: Data, imageURL: URL, post: Post?, taskContext: NSManagedObjectContext,
                       shouldSave: Bool = true) {
        let thumbnailImage = Attachment.thumbnail(from: imageData, thumbnailPixelSize: 80)
        var destinationURL: URL? // to hold the attachment.imageURL for later use
        
        taskContext.performAndWait {
            let attachment = Attachment(context: taskContext)
            attachment.post = post
            attachment.uuid = UUID()
            attachment.thumbnail = thumbnailImage // transient
            if shouldSave {
                taskContext.save(with: .addAttachment)
            }
            destinationURL = attachment.imageURL()
        }

        // Save the full image to the attachment folder and use it as a cache.
        // Added attachments can only be discarded when the DetailViewController is done, so don’t keep the full images in memory before that.
        // When presenting the FullImageViewController, load the image from this file if it is not in the Core Data store yet.
        DispatchQueue.global().async {
            var nsError: NSError?
            NSFileCoordinator().coordinate(writingItemAt: destinationURL!, options: .forReplacing, error: &nsError,
                                           byAccessor: { (newURL: URL) -> Void in
                do {
                    try imageData.write(to: newURL, options: .atomic)
                } catch {
                    print("###\(#function): Failed to save an image file: \(destinationURL!)")
                }
            })
            if let nsError = nsError {
                print("###\(#function): \(nsError.localizedDescription)")
            }
        }
    }
    
    /**
     Delete an attachment, including its .imageData since the delete rule is set to cascade. Use performAndWait to update the UI immediately.
     */
    func deleteAttachment(_ attachment: Attachment, shouldSave: Bool = true) {
        guard let context = attachment.managedObjectContext else {
            fatalError("###\(#function): Failed to retrieve the context from: \(attachment)")
        }
        context.performAndWait {
            attachment.post?.removeFromAttachments(attachment)
            attachment.thumbnail = nil // discard the thumbnail data
            context.delete(attachment)
            if shouldSave {
                context.save(with: .deleteAttachment)
            }
        }
    }
    
    /**
     Cache the image data of the newly-created attachment in a local file.
     
     Save to the store for synchronization only when the post is saved.
     */
    func saveImageDataIfNeeded(for attachments: NSSet, taskContext: NSManagedObjectContext,
                               completionHandler: (() -> Void)? = nil) {
        guard let attachments = attachments.allObjects as? [Attachment] else {
            completionHandler?()
            return
        }
        // Filter out attachments from previous editing sessions
        let newAttachments = attachments.filter { return $0.imageData == nil }
        
        guard !newAttachments.isEmpty else {
            completionHandler?()
            return
        }
        
        var newAttachmentCount = newAttachments.count
        for attachment in newAttachments {
            
            let fileURL = attachment.imageURL()
            var data: Data?
            
            var nsError: NSError?
            NSFileCoordinator().coordinate(
                readingItemAt: fileURL, options: .withoutChanges, error: &nsError, byAccessor: { (newURL: URL) -> Void in
                    data = UIImage(contentsOfFile: newURL.path)?.jpegData(compressionQuality: 1)
                }
            )
            
            if let nsError = nsError {
                print("###\(#function): \(nsError.localizedDescription)")
            }

            guard data != nil else {
                fatalError("###\(#function): Failed to read full image data for attachment: \(attachment)")
            }

            // Load image data using a taskContext. Reset the context after saving each image.
            let attachmentObjectID = attachment.objectID
            taskContext.perform {
                guard let attachment = taskContext.object(with: attachmentObjectID) as? Attachment else { return }
                    
                let imageData = ImageData(context: taskContext)
                imageData.data = data
                imageData.attachment = attachment
                
                print("###\(#function): Saving an ImageData entity and then resetting the context.")
                taskContext.save(with: .saveFullImage)
                taskContext.reset() // lower the memory footprint
                
                newAttachmentCount -= 1
                if newAttachmentCount == 0 {
                    completionHandler?()
                }
            }
        }
    }
}
