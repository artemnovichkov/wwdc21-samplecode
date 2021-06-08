/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to set up the Core Data stack, observe Core Data notifications, process persistent history, and deduplicate tags.
*/

import Foundation
import CloudKit
import CoreData
import CoreLocation

// MARK: - Core Data Stack

/**
 Core Data stack setup including history processing.
 */
class CoreDataStack {
    private var _privatePersistentStore: NSPersistentStore?
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }

    private var _sharedPersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }
    
    /**
     A persistent container that can load cloud-backed and non-cloud stores.
     */
    lazy var persistentContainer: TestAwarePersistentContainer = {
        let container = TestAwarePersistentContainer(name: "CoreDataCloudKitDemo")
        let appDelegate = AppDelegate.sharedAppDelegate
        if appDelegate.testingEnabled {
            prepareForTesting(container)
        }
        
        let privateStoreDescription = container.persistentStoreDescriptions.first!
        let storesURL = privateStoreDescription.url!.deletingLastPathComponent()
        privateStoreDescription.url = storesURL.appendingPathComponent("private.sqlite")
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateStoreDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        //Add Shared Database
        let sharedStoreURL = storesURL.appendingPathComponent("shared.sqlite")
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreURL
        
        if appDelegate.allowCloudKitSync {
            let containerIdentifier = privateStoreDescription.cloudKitContainerOptions!.containerIdentifier
            let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            sharedStoreOptions.databaseScope = .shared
            sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        } else {
            privateStoreDescription.cloudKitContainerOptions = nil
            sharedStoreDescription.cloudKitContainerOptions = nil
        }
        
        //Load the persistent stores
        container.persistentStoreDescriptions.append(sharedStoreDescription)
        container.loadPersistentStores(completionHandler: { (loadedStoreDescription, error) in
            if let loadError = error as NSError? {
                fatalError("###\(#function): Failed to load persistent stores:\(loadError)")
            } else if let cloudKitContainerOptions = loadedStoreDescription.cloudKitContainerOptions {
                if .private == cloudKitContainerOptions.databaseScope {
                    self._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                } else if .shared == cloudKitContainerOptions.databaseScope {
                    self._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                }
            } else if appDelegate.testingEnabled {
                if loadedStoreDescription.url!.lastPathComponent.hasSuffix("private.sqlite") {
                    self._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                } else if loadedStoreDescription.url!.lastPathComponent.hasSuffix("shared.sqlite") {
                    self._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescription.url!)
                }
            }
        })
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = appTransactionAuthorName
        
        // Pin the viewContext to the current generation token and set it to keep itself up to date with local changes.
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("###\(#function): Failed to pin viewContext to the current generation:\(error)")
        }
        
        // Observe Core Data remote change notifications.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(storeRemoteChange(_:)),
                                               name: .NSPersistentStoreRemoteChange,
                                               object: container.persistentStoreCoordinator)
        
        return container
    }()

    /**
     Track the last history token processed for a store, and write its value to file.
     
     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
    */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CoreDataCloudKitDemo", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
    
    /**
     An operation queue for handling history processing tasks: watching changes, deduplicating tags, and triggering UI updates if needed.
     */
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /**
     The URL of the thumbnail folder.
     */
    static var attachmentFolder: URL = {
        var url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CoreDataCloudKitDemo", isDirectory: true)
        url = url.appendingPathComponent("attachments", isDirectory: true)
        
        // Create it if it doesn’t exist.
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

            } catch {
                print("###\(#function): Failed to create thumbnail folder URL: \(error)")
            }
        }
        return url
    }()
    
    init() {
        // Load the last token from the token file.
        if let tokenData = try? Data(contentsOf: tokenFile) {
            do {
                lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                print("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
    }
}
// MARK: - Notifications

extension CoreDataStack {
    /**
     Handle remote store change notifications (.NSPersistentStoreRemoteChange).
     */
    @objc
    func storeRemoteChange(_ notification: Notification) {
        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
}

/**
 Custom notifications in this sample.
 */
extension Notification.Name {
    static let didFindRelevantTransactions = Notification.Name("didFindRelevantTransactions")
}

// MARK: - Persistent history processing

extension CoreDataStack {
    
    /**
     Process persistent history, posting any relevant transactions to the current view.
     */
    func processPersistentHistory() {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.performAndWait {
            
            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", appTransactionAuthorName)
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest

            let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty
                else { return }

            // Post transactions relevant to the current view.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didFindRelevantTransactions, object: self, userInfo: ["transactions": transactions])
            }

            // Deduplicate the new tags.
            var newTagObjectIDs = [NSManagedObjectID]()
            let tagEntityName = Tag.entity().name

            for transaction in transactions where transaction.changes != nil {
                for change in transaction.changes!
                    where change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert {
                        newTagObjectIDs.append(change.changedObjectID)
                }
            }
            if !newTagObjectIDs.isEmpty {
                deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
            }
            
            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
}

// MARK: - Deduplicate tags

extension CoreDataStack {
    /**
     Deduplicate tags with the same name by processing the persistent history, one tag at a time, on the historyQueue.
     
     All peers should eventually reach the same result with no coordination or communication.
     */
    private func deduplicateAndWait(tagObjectIDs: [NSManagedObjectID]) {
        // Make any store changes on a background context
        let taskContext = persistentContainer.backgroundContext()
        
        // Use performAndWait because each step relies on the sequence. Since historyQueue runs in the background, waiting won’t block the main queue.
        taskContext.performAndWait {
            tagObjectIDs.forEach { tagObjectID in
                deduplicate(tagObjectID: tagObjectID, performingContext: taskContext)
            }
            // Save the background context to trigger a notification and merge the result into the viewContext.
            taskContext.save(with: .deduplicate)
        }
    }

    /**
     Deduplicate a single tag.
     */
    private func deduplicate(tagObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
        guard let tag = performingContext.object(with: tagObjectID) as? Tag,
            let tagName = tag.name else {
            fatalError("###\(#function): Failed to retrieve a valid tag with ID: \(tagObjectID)")
        }

        // Fetch all tags with the same name, sorted by uuid
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Schema.Tag.uuid.rawValue, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "\(Schema.Tag.name.rawValue) == %@", tagName)
        
        // Return if there are no duplicates.
        guard var duplicatedTags = try? performingContext.fetch(fetchRequest), duplicatedTags.count > 1 else {
            return
        }
        print("###\(#function): Deduplicating tag with name: \(tagName), count: \(duplicatedTags.count)")
        
        // Pick the first tag as the winner.
        let winner = duplicatedTags.first!
        duplicatedTags.removeFirst()
        remove(duplicatedTags: duplicatedTags, winner: winner, performingContext: performingContext)
    }
    
    /**
     Remove duplicate tags from their respective posts, replacing them with the winner.
     */
    private func remove(duplicatedTags: [Tag], winner: Tag, performingContext: NSManagedObjectContext) {
        duplicatedTags.forEach { tag in
            defer { performingContext.delete(tag) }
            guard let posts = tag.posts else { return }
            
            for case let post as Post in posts {
                if let mutableTags: NSMutableSet = post.tags?.mutableCopy() as? NSMutableSet {
                    if mutableTags.contains(tag) {
                        mutableTags.remove(tag)
                        mutableTags.add(winner)
                    }
                }
            }
        }
    }
}

// Mark - Sharing
extension CoreDataStack: SharingProvider {
    func isShared(object: NSManagedObject) -> Bool {
        return isShared(objectID: object.objectID)
    }

    func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                let container = persistentContainer
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if nil != shares.first {
                        isShared = true
                    }
                } catch let error {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }
    
    func participants(for object: NSManagedObject) -> [RenderableShareParticipant] {
        var participants = [CKShare.Participant]()
        do {
            let container = persistentContainer
            let shares = try container.fetchShares(matching: [object.objectID])
            if let share = shares[object.objectID] {
                participants = share.participants
            }
        } catch let error {
            print("Failed to fetch share for \(object): \(error)")
        }
        return participants
    }
    
    func shares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: RenderableShare] {
        return try persistentContainer.fetchShares(matching: objectIDs)
    }
    
    func canEdit(object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
        
    func canDelete(object: NSManagedObject) -> Bool {
        return persistentContainer.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
}

// MARK: Serialization of CLLocation
@objc(SecureCLLocationTransformer)
class SecureCLLocationTransformer: NSSecureUnarchiveFromDataTransformer {
    public static let transformerName = NSValueTransformerName(rawValue: "SecureCLLocationTransformer")
    override class var allowedTopLevelClasses: [AnyClass] {
        return [CLLocation.self]
    }
}
