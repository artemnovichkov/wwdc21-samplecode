/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that wraps everything related to fetching, creating, and deleting photos.
*/

import Foundation
import CoreData
import CoreSpotlight

class PhotoProvider {
    private(set) var persistentContainer: NSPersistentContainer
    private weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
        
    init(persistentContainer: NSPersistentContainer, fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?) {
        self.persistentContainer = persistentContainer
        self.fetchedResultsControllerDelegate = fetchedResultsControllerDelegate
    }

    // A fetched results controller for the Photo entity.
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: TagsSchema.Photo.uniqueName.rawValue, ascending: true)]
        
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
}

// MARK: - Generate Photo objects.
//
extension PhotoProvider {
    func generateDefaultPhotos() {
        let baseURL = Bundle.main.resourceURL!.appendingPathComponent("Photos", isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else {
            print("No content in \(baseURL).")
            return
        }

        let resourceKeys = [URLResourceKey.isDirectoryKey, .isPackageKey]
        let subfolderURLs = contents.filter { url in
            let resourceValues = try? (url as NSURL).resourceValues(forKeys: resourceKeys)
            let isDirectory = resourceValues?[URLResourceKey.isDirectoryKey] as? Bool ?? false
            let isPackage = resourceValues?[URLResourceKey.isPackageKey] as? Bool ?? false

            return isDirectory && !isPackage
        }
        
        for subfolderURL in subfolderURLs {
            generateDefaultPhotos(folderURL: subfolderURL)
        }
    }
    
    private func generateDefaultPhotos(folderURL: URL) {
        guard let contentURLs = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil ) else {
            print("No photo in \(folderURL).")
            return
        }

        let photoURLs = contentURLs.filter { url in
            guard let resourceValues = try? (url as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey]),
                let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? Bool else {
                return false
            }
            return !isDirectory
        }

        for photoURL in photoURLs {
            generateOneDefaultPhoto(photoURL: photoURL, paraentFolderURL: folderURL)
        }
    }
    
    private func generateOneDefaultPhoto(photoURL: URL, paraentFolderURL: URL) {
        guard let photoData = try? Data(contentsOf: photoURL) else {
            print("Failed to load image data for \(photoURL).")
            return
        }
        guard let thumbnailData = photoData.thumbnail()?.jpegData(compressionQuality: 1) else {
            print("Failed to create a thumbnail for \(photoURL).")
            return
        }
        
        let userSpecifiedName = photoURL.lastPathComponent
        let tagNames = [paraentFolderURL.lastPathComponent]
        
        let taskContext = persistentContainer.newBackgroundContext()
        addPhoto(userSpecifiedName: userSpecifiedName,
                 photoData: photoData,
                 thumbnailData: thumbnailData,
                 tagNames: tagNames,
                 context: taskContext)
    }
}

// MARK: - Convenient methods for adding and deleting a photo, and performing a fetch.
//
extension PhotoProvider {
    func addPhoto(userSpecifiedName: String,
                  photoData: Data,
                  thumbnailData: Data,
                  tagNames: [String] = [],
                  context: NSManagedObjectContext,
                  shouldSave: Bool = true,
                  completionHandler: ((_ newPhoto: Photo) -> Void)? = nil) {
        context.perform {
            let photo = Photo(context: context)
            photo.uniqueName = UUID().uuidString
            photo.userSpecifiedName = userSpecifiedName
            
            let thumbnail = Thumbnail(context: context)
            thumbnail.data = thumbnailData
            thumbnail.photo = photo
            
            let photoDataObject = PhotoData(context: context)
            photoDataObject.data = photoData
            photoDataObject.photo = photo
            
            for tagName in tagNames {
                let existingTag = Tag.tagIfExists(with: tagName, context: context)
                let tag = existingTag ?? Tag(context: context)
                tag.name = tagName
                tag.addToPhotos(photo)
            }

            if shouldSave {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
            completionHandler?(photo)
        }
    }
    
    func delete(photo: Photo, shouldSave: Bool = true, completionHandler: (() -> Void)? = nil) {
        guard let context = photo.managedObjectContext else {
            fatalError("###\(#function): Failed to retrieve the context from: \(photo)")
        }
        context.perform {
            context.delete(photo)
            if shouldSave {
                do {
                    try context.save()
                } catch {
                    print("Failed to save Core Data context: \(error)")
                }
            }
            completionHandler?()
        }
    }
    
    func performFetch(searchableItems: [CSSearchableItem]) {
        let photoObjectIDs: [NSManagedObjectID] = searchableItems.compactMap { item in
            guard let uri = URL(string: item.uniqueIdentifier),
                  let objectID = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri),
                  persistentContainer.viewContext.object(with: objectID) is Photo else {
                return nil
            }
            return objectID
        }
        let predicate = NSPredicate(format: "self IN %@", photoObjectIDs)
        performFetch(predicate: predicate)
    }

    func performFetch(predicate: NSPredicate?) {
        fetchedResultsController.fetchRequest.predicate = predicate
        try? fetchedResultsController.performFetch()
    }
}
