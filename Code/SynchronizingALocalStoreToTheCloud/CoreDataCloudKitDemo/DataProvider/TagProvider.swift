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
    
    /**
     A fetched results controller for the Tag entity, sorted by name.
     */
    lazy var fetchedResultsController: NSFetchedResultsController<Tag> = {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Tag.postCount.rawValue, ascending: false)]
        
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
    
    /**
     The number of tags. Used for tag name input validation.
     */
    func numberOfTags(with tagName: String) -> Int {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(Schema.Tag.name.rawValue) == %@", tagName)
        
        let number = try? persistentContainer.viewContext.count(for: fetchRequest)
        return number ?? 0
    }
    
    /**
     Add a tag. Generate a random color to differentiate tags with the same name, which will eventually be deduplicated.
     */
    func addTag(name: String, context: NSManagedObjectContext, shouldSave: Bool = true) {
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

        context.performAndWait {
            let tag = Tag(context: context)
            tag.name = name
            tag.uuid = UUID()
            tag.color = randomColor
            
            if shouldSave {
                context.save(with: .addTag)
            }
        }
    }
    
    func deleteTag(at indexPath: IndexPath, shouldSave: Bool = true) {
        let context = fetchedResultsController.managedObjectContext
        context.performAndWait {
            context.delete(fetchedResultsController.object(at: indexPath))
            if shouldSave {
                context.save(with: .deleteTag)
            }
        }
    }
}
