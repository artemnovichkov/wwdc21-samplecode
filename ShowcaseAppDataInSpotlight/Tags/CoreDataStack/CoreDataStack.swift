/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that sets up the Core Data stack.
*/

import Foundation
import CoreData

class CoreDataStack {
    private (set) var spotlightIndexer: TagsSpotlightDelegate?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tags")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }

        // Enable history tracking and remote notifications.
        description.type = NSSQLiteStoreType
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                
        container.loadPersistentStores(completionHandler: { (_, error) in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent stores:\(error)")
        })
        
        spotlightIndexer = TagsSpotlightDelegate(forStoreWith: description,
                                                 coordinator: container.persistentStoreCoordinator)

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Keep viewContext itself up to date with local changes and pin to the current query generation.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }
        
        return container
    }()
}
