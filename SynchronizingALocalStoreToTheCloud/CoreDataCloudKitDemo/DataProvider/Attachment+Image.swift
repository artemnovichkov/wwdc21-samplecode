/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension of the Attachment class to handle the thumbnail file when the object is saved, and provide a method for clients to load the image.
*/

import UIKit
import CoreData

extension Attachment {
    /**
     Create the thumbnail image from image data.
     */
    static func thumbnail(from imageData: Data, thumbnailPixelSize: Int) -> UIImage? {
        let options = [kCGImageSourceCreateThumbnailWithTransform: true,
                       kCGImageSourceCreateThumbnailFromImageAlways: true,
                       kCGImageSourceThumbnailMaxPixelSize: thumbnailPixelSize] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let imageReference = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)!
        return UIImage(cgImage: imageReference)
    }
    
    /**
     Create the thumbnail URL for the current attachment.
     */
    private func thumbnailURL() -> URL {
        let fileName = uuid!.uuidString + ".thumbnail"
        return CoreDataStack.attachmentFolder.appendingPathComponent(fileName)
    }
    
    /**
     Coordinate deletion of attachments.
     
     For attachments created by Core Data with CloudKit, if file doesn’t exist, return silently.
     */
    private func coordinateDeleting(fileURL: URL) {
        // fileExists is light so use it to avoid coordinate if the file doesn’t exist.
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        var nsError: NSError?
        NSFileCoordinator().coordinate(
            writingItemAt: fileURL, options: .forDeleting, error: &nsError, byAccessor: { (newURL: URL) -> Void in
                do {
                    try FileManager.default.removeItem(atPath: newURL.path)
                } catch {
                    print("###\(#function): Failed to delete file at: \(fileURL)\n\(error)")
                }
            }
        )
        if let nsError = nsError {
            print("###\(#function): \(nsError.localizedDescription)")
        }
    }

    /**
     Cache the attachment image by saving it to a local file. Core Data does not persist the transient .thumbnail attribute.
     
     Note that Core Data with CloudKit can delete an attachment anytime, triggering this override.
     */
    override public func didSave() {
        super.didSave()
        guard hasChanges else { return }
        
        let thumbnailFileURL = thumbnailURL()
        let imageFileURL = imageURL()

        // If the attachment was marked as deleted, remove its files.
        if isDeleted {
            // Coordinate deletion because a peer can remove and sync the same attachment in the background.
            coordinateDeleting(fileURL: thumbnailFileURL)
            coordinateDeleting(fileURL: imageFileURL)
            return
        }
        
        // An attachment created by Core Data with CloudKit doesn’t have a thumbnail if it hasn’t been presented in this launch session.
        guard let image = thumbnail else { return }

        // The attachment is valid, save the thumbnail jpeg data to a file asynchronously.
        DispatchQueue.global().async {
            guard let thumbnailData = image.jpegData(compressionQuality: 1) else {
                return
            }
            var nsError: NSError?
            NSFileCoordinator().coordinate(
                writingItemAt: thumbnailFileURL, options: .forReplacing, error: &nsError,
                byAccessor: { (newURL: URL) -> Void in
                    do {
                        try thumbnailData.write(to: newURL, options: .atomic)
                    } catch {
                        fatalError("###\(#function): Failed to save thumbnail file: \(newURL)")
                    }
                }
            )
            if let nsError = nsError {
                print("###\(#function): \(nsError.localizedDescription)")
            }
        }
    }
    
    /**
     Create the image file URL for the current attachment.
     */
    func imageURL() -> URL {
        let fileName = uuid!.uuidString + ".jpg"
        return CoreDataStack.attachmentFolder.appendingPathComponent(fileName)
    }
    
    /**
     Load the thumbnail data from the cached file, or from the imageData if the file doesn’t exist.
     
     Clients should always use this method to access the thumbnail.
     The thumbnail property is there for Xcode to generate the attribute for holding the reference.
     */
    func getThumbnail() -> UIImage? {
        // Return the thumbnail image if it is already loaded.
        guard thumbnail == nil else { return thumbnail }
        
        var nsError: NSError?
        NSFileCoordinator().coordinate(
            readingItemAt: thumbnailURL(), options: .withoutChanges, error: &nsError,
            byAccessor: { (newURL: URL) -> Void in
                thumbnail = UIImage(contentsOfFile: newURL.path)
            }
        )
        if let nsError = nsError {
            print("###\(#function): \(nsError.localizedDescription)")
        }

        // Return the thumbnail image if it is ready.
        guard thumbnail == nil else { return thumbnail }

        // If the thumbnail doesn’t exist yet, try to create it from the full image data.
        // For attachments created by Core Data with CloudKit, imageData can be nil.
        guard let fullImageData = imageData?.data else {
            print("###\(#function): Full image data is not there yet.")
            return nil
        }
        thumbnail = Attachment.thumbnail(from: fullImageData, thumbnailPixelSize: 80)
        return thumbnail
    }
    
    /**
     Load the image from the cached file if it exists, otherwise from the attachment’s imageData.
     
     Attachments created by Core Data with CloudKit don’t have cached files.
     Provide a new task context to load the image data, and release it after the image finishes loading.
     */
    func getImage(with taskContext: NSManagedObjectContext) -> UIImage? {
        // Load the image from the cached file if the file exists.
        var image: UIImage?
        
        var nsError: NSError?
        NSFileCoordinator().coordinate(
            readingItemAt: imageURL(), options: .withoutChanges, error: &nsError,
            byAccessor: { (newURL: URL) -> Void in
                if let data = try? Data(contentsOf: newURL) {
                    image = UIImage(data: data, scale: UIScreen.main.scale)
                }
            }
        )
        if let nsError = nsError {
            print("###\(#function): \(nsError.localizedDescription)")
        }

        // Return the image if it was read from the cached file.
        guard image == nil else { return image }

        // If the cache file doesn’t exist, load the image data from the store.
        let attachmentObjectID = objectID
        taskContext.performAndWait {
            if let attachment = taskContext.object(with: attachmentObjectID) as? Attachment,
                let data = attachment.imageData?.data {
                image = UIImage(data: data, scale: UIScreen.main.scale)
            }
        }
        return image
    }
}
