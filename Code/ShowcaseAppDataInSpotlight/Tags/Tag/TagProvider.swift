/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to wrap everything related to fetching, creating, and deleting tags.
*/

import UIKit
import CoreData

class TagProvider {
    private(set) var persistentContainer: NSPersistentContainer
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    init(with persistentContainer: NSPersistentContainer,
         fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }
    
    // A fetched results controller for the Tag entity.
    lazy var fetchedResultsController: NSFetchedResultsController<Tag> = {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: TagsSchema.Tag.photoCount.rawValue, ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate
        
        do {
            try controller.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("###\(#function): Failed to performFetch: \(nserror), \(nserror.userInfo)")
        }
        
        return controller
    }()
    
    // The number of tags. Used for tag name input validation.
    func numberOfTags(with tagName: String) -> Int {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(TagsSchema.Tag.name.rawValue) == %@", tagName)
        
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }
    
    func addTag(name: String, context: NSManagedObjectContext, shouldSave: Bool = true) {
        context.performAndWait {
            let tag = Tag(context: context)
            tag.name = name
            
            if shouldSave {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
        }
    }
    
    func deleteTag(at indexPath: IndexPath, shouldSave: Bool = true) {
        let context = fetchedResultsController.managedObjectContext
        context.performAndWait {
            context.delete(fetchedResultsController.object(at: indexPath))
            if shouldSave {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
        }
    }
}

// MARK: - An extension for Tag.
//
extension Tag {
    class func tagIfExists(with name: String, context: NSManagedObjectContext) -> Tag? {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(TagsSchema.Tag.name.rawValue) == %@", name)
        let tags = try? context.fetch(fetchRequest)
        return tags?.first
    }
}
