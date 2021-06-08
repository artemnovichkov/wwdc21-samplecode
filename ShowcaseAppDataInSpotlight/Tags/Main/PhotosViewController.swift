/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller class that shows a list of photos.
*/

import UIKit
import CoreData
import CoreSpotlight

class PhotosViewController: UICollectionViewController {
    @IBOutlet var generateDefaultPhotosItem: UIBarButtonItem!
    @IBOutlet var deleteSpotlightIndexItem: UIBarButtonItem!
    @IBOutlet var startStopIndexingItem: UIBarButtonItem!
    
    private var isTagging = false
    private var spotlightFoundItems = [CSSearchableItem]()
    private static let defaultSectionNumber = 0
    private var searchQuery: CSSearchQuery?
    var spotlightUpdateObserver: NSObjectProtocol?

    private lazy var spotlightIndexer: TagsSpotlightDelegate = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate!.coreDataStack.spotlightIndexer!
    }()

    private lazy var dataProvider: PhotoProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = PhotoProvider(persistentContainer: appDelegate!.coreDataStack.persistentContainer,
                                    fetchedResultsControllerDelegate: self)
        return provider
    }()

    private lazy var plusCircleItem: ImageItem = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 40)
        let image = UIImage(systemName: "plus.circle", withConfiguration: configuration)!
        return ImageItem(uniqueName: "plus.circle", thumbnail: image)
    }()

    private lazy var diffableImageSource: DiffableImageSource = {
        return DiffableImageSource(collectionView: collectionView) { (collectionView, indexPath, imageItem) -> TagsImageCell? in
            let cvCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCVCell", for: indexPath)
            guard let cell = cvCell as? TagsImageCell else {
                fatalError("Failed to dequeue ImageCVCell. Check the cell reusable identifier in Main.storyboard.")
            }
            cell.delegate = self
            cell.imageView.image = imageItem.thumbnail
            if indexPath.item == collectionView.numberOfItems(inSection: 0) - 1, self.isEditing {
                cell.backgroundColor = .systemGray6
                cell.imageView.alpha = 1
                cell.deleteButton.alpha = 0
                cell.tagButton.alpha = 0
            } else {
                cell.imageView.alpha = self.isEditing || self.isTagging ? 0.6 : 1
                cell.deleteButton.alpha = self.isEditing ? 1 : 0
                cell.tagButton.alpha = self.isTagging ? 1 : 0
            }
            return cell
        }
    }()
    
    private func reloadCollectionView() {
        let photos: [Photo] = dataProvider.fetchedResultsController.fetchedObjects ?? []
        
        let imageItems: [ImageItem] = photos.compactMap { photo in
            guard let data = photo.thumbnail?.data, let thumbnail = UIImage(data: data),
                  let uniqueName = photo.uniqueName else {
                print("Failed to retrieve the name and thumbnail for \(photo).")
                return nil
            }
            return ImageItem(uniqueName: uniqueName, thumbnail: thumbnail)
        }

        // Apply a new snapshot. The collection view has only one section in this sample.
        var snapshot = DiffableImageSourceSnapshot()
        snapshot.appendSections([PhotosViewController.defaultSectionNumber])
        snapshot.appendItems(imageItems)
        if isEditing {
            snapshot.appendItems([plusCircleItem])
        }
        diffableImageSource.apply(snapshot)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem

        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexible, generateDefaultPhotosItem, flexible, startStopIndexingItem, flexible, deleteSpotlightIndexItem, flexible]
        navigationController?.isToolbarHidden = false
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        reloadCollectionView()

        toggleSpotlightIndexing(enabled: true)
    }
    
    /**
     Edit session management.
     editing == true: In an editing session, show plusCircleItem and the delete button.
     editing == false: The editing is done.
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        var snapshot = diffableImageSource.snapshot()
        editing ? snapshot.appendItems([plusCircleItem]) : snapshot.deleteItems([plusCircleItem])
        diffableImageSource.apply(snapshot)
        snapshot.reloadSections([PhotosViewController.defaultSectionNumber])
        diffableImageSource.apply(snapshot)
    }

    @IBAction func tag(_ sender: Any) {
        isTagging = !isTagging
        navigationItem.leftBarButtonItem?.isEnabled = !isTagging
        
        let imageName = isTagging ? "tag.slash" : "tag"
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: imageName)
        
        var snapshot = diffableImageSource.snapshot()
        snapshot.reloadSections([PhotosViewController.defaultSectionNumber])
        diffableImageSource.apply(snapshot)
    }
    
    @IBAction func generateDefaultPhotos(_ sender: Any) {
        dataProvider.generateDefaultPhotos()
    }

    @IBAction func deleteSpotlightIndex(_ sender: Any) {
        toggleSpotlightIndexing(enabled: false)

        spotlightIndexer.deleteSpotlightIndex(completionHandler: { (error) in
            DispatchQueue.main.async {
                if let err = error {
                    let newAlert = UIAlertController(title: "Deletion Failed",
                                                     message: "Error deleting Spotlight index data: \(err.localizedDescription).",
                                                     preferredStyle: .alert)
                    newAlert.addAction(UIAlertAction(title: "OK",
                                                     style: .default))
                    self.present(newAlert, animated: true)
                    print("Encountered error while deleting Spotlight index data, \(err.localizedDescription)")
                } else {
                    let newAlert = UIAlertController(title: "Deletion Successful",
                                                     message: "The spotlight index was successfully deleted.",
                                                     preferredStyle: .alert)
                    newAlert.addAction(UIAlertAction(title: "OK",
                                                     style: .default))
                    self.present(newAlert, animated: true)
                }
            }
        })
    }

    @IBAction func toggleSpotlightIndexingEnabled(_ sender: Any) {
        if spotlightIndexer.isIndexingEnabled == true {
            toggleSpotlightIndexing(enabled: false)

            let newAlert = UIAlertController(title: "Disabled Indexing",
                                             message: "Spotlight indexing is disabled.",
                                             preferredStyle: .alert)
            newAlert.addAction(UIAlertAction(title: "OK",
                                             style: .default))
            self.present(newAlert, animated: true)
        } else {
            toggleSpotlightIndexing(enabled: true)

            let newAlert = UIAlertController(title: "Enabled Indexing",
                                             message: "Spotlight indexing is enabled.",
                                             preferredStyle: .alert)
            newAlert.addAction(UIAlertAction(title: "OK",
                                             style: .default))
            self.present(newAlert, animated: true)
        }
    }

    private func toggleSpotlightIndexing(enabled: Bool) {
        if enabled {
            spotlightIndexer.startSpotlightIndexing()
            startStopIndexingItem.image = UIImage(systemName: "pause")
        } else {
            spotlightIndexer.stopSpotlightIndexing()
            startStopIndexingItem.image = UIImage(systemName: "play")
        }

        let center = NotificationCenter.default
        if spotlightIndexer.isIndexingEnabled && spotlightUpdateObserver == nil {
            let queue = OperationQueue.main
            spotlightUpdateObserver = center.addObserver(forName: NSCoreDataCoreSpotlightDelegate.indexDidUpdateNotification,
                                                         object: nil,
                                                         queue: queue) { (notification) in
                let userInfo = notification.userInfo
                let storeID = userInfo?[NSStoreUUIDKey] as? String
                let token = userInfo?[NSPersistentHistoryTokenKey] as? NSPersistentHistoryToken
                if let storeID = storeID, let token = token {
                    print("Store with identifier \(storeID) has completed ",
                          "indexing and has processed history token up through \(String(describing: token)).")
                }
            }
        } else {
            if spotlightUpdateObserver == nil {
                return
            }
            center.removeObserver(spotlightUpdateObserver as Any)
        }
    }
}

extension PhotosViewController: TagsImageCellDelegate {
    func deleteCell(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        let photo = dataProvider.fetchedResultsController.object(at: indexPath)
        dataProvider.delete(photo: photo)
    }
    
    func tagCell(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        presentTagViewController(itemIndexPath: indexPath)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
//
extension PhotosViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reloadCollectionView()
    }
}

// MARK: - UICollectionViewDelegate
//
extension PhotosViewController {
    /**
     If the user is editing and tapping the last cell, present an image picker.
     Otherwise, present the full image, or the tag view controller if isTagging is true.
     */
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if isEditing && indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 {
            presentImagePicker()
            return
        }
        if isTagging {
            presentTagViewController(itemIndexPath: indexPath)
        } else {
            presentImageViewController(itemIndexPath: indexPath)
        }
    }
    
    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    private func presentTagViewController(itemIndexPath: IndexPath) {
        let photo = dataProvider.fetchedResultsController.object(at: itemIndexPath)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "TagNC")
        guard let navController = viewController as? UINavigationController,
              let tagViewController = navController.topViewController as? TagViewController else {
                return
        }
        navController.presentationController?.delegate = tagViewController
        tagViewController.selectedPhoto = photo
        present(navController, animated: true)
    }
    
    private func presentImageViewController(itemIndexPath: IndexPath) {
        let photo = dataProvider.fetchedResultsController.object(at: itemIndexPath)
        guard let photoData = photo.photoData?.data, let image = UIImage(data: photoData) else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageNC")
        guard let navController = viewController as? UINavigationController,
              let imageViewController = navController.topViewController as? FullImageViewController else {
                return
        }
        imageViewController.fullImage = image
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
//
extension PhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /**
      UIKit calls this method when the user finishes picking an item with UIImagePickerController.
      image.jpegData may fail for unsupported image formats. This sample doesn't
      handle unsupported formats because that isn't the focus.
     */
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 1),
            let imageURL = info[.imageURL] as? URL else {
                print("Failed to get JPG data and URL of the picked image.")
                return
        }
        guard let thumbnailData = imageData.thumbnail()?.jpegData(compressionQuality: 1) else {
            print("Failed to create a thumbnail for \(imageURL).")
            return
        }
        let userSpecifiedName = imageURL.lastPathComponent
        let taskContext = dataProvider.persistentContainer.newBackgroundContext()
        dataProvider.addPhoto(userSpecifiedName: userSpecifiedName, photoData: imageData, thumbnailData: thumbnailData, context: taskContext)
        
        dismiss(animated: true)
    }
    
    /**
      UIKit calls the UIImagePickerControllerDelegate method when the user taps the cancel button in UIImagePickerController.
     */
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

// MARK: - UISearchResultsUpdating
//
extension PhotosViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let userInput = searchController.searchBar.text, !userInput.isEmpty else {
            dataProvider.performFetch(predicate: nil)
            reloadCollectionView()
            return
        }
        
        let escapedString = userInput.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(keywords == \"" + escapedString + "*\"cwdt)"
        
        searchQuery = CSSearchQuery(queryString: queryString, attributes: ["displayName", "keywords"])

        // Set a handler for results. This will be a called 0 or more times.
        searchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundItems += items
            }
        }
        
        // Set a completion handler. This will be called once.
        searchQuery?.completionHandler = { error in
            guard error == nil else {
                print("CSSearchQuery completed with error: \(error!).")
                return
            }

            DispatchQueue.main.async {
                self.dataProvider.performFetch(searchableItems: self.spotlightFoundItems)
                self.reloadCollectionView()
                self.spotlightFoundItems.removeAll()
            }
        }

        // Start the query.
        searchQuery?.start()
    }
}
