/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to wrap everything related to fetching, creating, and deleting posts.
*/

import UIKit
import CoreData

class PostProvider {
    private(set) var persistentContainer: NSPersistentContainer
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    /**
     Date formatter for recording the timestamp in the default post title.
     */
    private lazy var mediumTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
    
    init(with persistentContainer: NSPersistentContainer,
         fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }
    
    /**
     A fetched results controller for the Post entity, sorted by title.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<Post> = {
        let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Post.title.rawValue, ascending: true)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate
        
        do {
            try controller.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        
        return controller
    }()
    
    func addPost(in context: NSManagedObjectContext, shouldSave: Bool = true, completionHandler: ((_ newPost: Post) -> Void)? = nil) {
        context.perform {
            let post = Post(context: context)
            post.title = "Untitled " + self.mediumTimeFormatter.string(from: Date())
            
            let appDelegate = AppDelegate.sharedAppDelegate
            if appDelegate.locationAuthorized {
                post.location = appDelegate.locationManager.location
            }
            
            if shouldSave {
                context.save(with: .addPost)
            }
            completionHandler?(post)
        }
    }
    
    func delete(post: Post, shouldSave: Bool = true, completionHandler: (() -> Void)? = nil) {
        guard let context = post.managedObjectContext else {
            fatalError("###\(#function): Failed to retrieve the context from: \(post)")
        }
        context.perform {
            context.delete(post)
            
            if shouldSave {
                context.save(with: .deletePost)
            }
            completionHandler?()
        }
    }
    
    /**
     Generate a specified number of template posts with random tags.
     */
    func generateTemplatePosts(number numberOfPosts: Int, completionHandler: (() -> Void)? = nil) {
        let taskContext = persistentContainer.backgroundContext()
        taskContext.perform {
            let title = "Untitled \(self.mediumTimeFormatter.string(from: Date()))"
            
            let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Tag.name.rawValue, ascending: true)]

            let tags = try? taskContext.fetch(fetchRequest)
            let numberOfTags = UInt32(tags?.count ?? 0)
            
            for index in 0..<numberOfPosts {
                let post = Post(context: taskContext)
                post.title = "\(title) - \(index)"
                
                guard numberOfTags > 0, let tags = tags else { continue }
                
                // Add up to four random tags to each post
                for _ in 1...4 {
                    let random = Int(arc4random_uniform(numberOfTags))
                    post.addToTags(tags[random])
                }
            }
            taskContext.save(with: .batchAddPosts)
            taskContext.reset()
            completionHandler?()
        }
    }
    
    /**
     Delete all posts and their attachments in the background using a batch delete request. Leave tags.
     */
    func batchDeleteAllPosts(completionHandler: (() -> Void)? = nil) {
        let taskContext = persistentContainer.backgroundContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Post.entity().name!)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            do {
                let batchDeleteResult = try taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
                print("###\(#function): Batch deleted post count: \(String(describing: batchDeleteResult?.result))")
            } catch {
                print("###\(#function): Failed to batch delete existing records: \(error)")
            }
            completionHandler?()
        }
        
        // Delete the attachment folder and its files.
        // Coordinate deletion because Core Data with CloudKit can be adding or deleting an attachment in the background.
        let folderURL = CoreDataStack.attachmentFolder
        var nsError: NSError?
        NSFileCoordinator().coordinate(
            writingItemAt: folderURL, options: .forDeleting, error: &nsError,
            byAccessor: { (newURL: URL) -> Void in
                do {
                    try FileManager.default.removeItem(atPath: newURL.path)
                } catch {
                    print("###\(#function): Failed to delete \(folderURL)\n\(error)")
                }
            }
        )
        if let nsError = nsError {
            print("###\(#function): \(nsError.localizedDescription)")
        }
        
        // Recreate the folder for future use.
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("###\(#function): Failed to create thumbnail folder URL: \(error)")
        }
    }
}
