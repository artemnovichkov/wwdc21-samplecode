/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Stack item view controller for displaying a simple NSCollectionView of images.
*/

import Cocoa

class CollectionViewController: BaseViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    // The image names for each collection view item.
    enum SceneImage: String {
        case scene1, scene2, scene3, scene4
    }
    
    @IBOutlet weak var collection: NSCollectionView!
    
    private static let collectionItemIdentifier = "CollectionItem"
    
    override func headerTitle() -> String { return NSLocalizedString("Images Header Title", comment: "") }

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // We want a special background color drawn for the collectionView.
        if let backgroundColor = NSColor(named: "CollectionViewBackgroundColor") {
        	collection.backgroundColors = [backgroundColor]
        }
        
        // Compute the default height of this view so later we can hide/show it later.
        let size = collection.collectionViewLayout?.collectionViewContentSize
        savedDefaultHeight = size!.height
        
        // Must register the cell we're going to use for display in the collection.
        collection.register(CollectionItem.self,
            				forItemWithIdentifier: NSUserInterfaceItemIdentifier(CollectionViewController.collectionItemIdentifier))
        collection.enclosingScrollView?.borderType = .noBorder
        
        collection.reloadData()
    }
    
    // MARK: - NSCollectionViewDataSource
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        // Determine the image to be assigned to this collection view item.
        let item =
            collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(CollectionViewController.collectionItemIdentifier),
                                    for: indexPath)
        guard let collectionViewItem = item as? CollectionItem else { return item }
        
        // Decide which image name to use for each index path.
        var imageName = ""
        switch (indexPath as NSIndexPath).item {
        case 0:
            imageName = SceneImage.scene1.rawValue
        case 1:
            imageName = SceneImage.scene2.rawValue
        case 2:
            imageName = SceneImage.scene3.rawValue
        case 3:
            imageName = SceneImage.scene4.rawValue
        default:
            break
        }
        collectionViewItem.imageView?.image = NSImage(named: imageName)
        
        return collectionViewItem
    }
    
    // MARK: - NSCollectionViewDelegate
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        debugPrint("collectionView: didSelectItemsAt: \(indexPaths)")
        // Invalidate state restoration, which will in turn eventually call "encodeRestorableState".
        invalidateRestorableState()
    }
    
}

// MARK: - State Restoration

extension CollectionViewController {
    // Restorable key for the collection view's selection.
    private static let collectionViewSelectionKey = "collectionViewSelectionKey"
    
    /// Encode state. Helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(collection.selectionIndexes, forKey: CollectionViewController.collectionViewSelectionKey)
        super.encodeRestorableState(with: coder)
    }
    
    /// Decode state. Helps restore any previously stored state of the collection view's selection.
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        
        if let decodedSelection = coder.decodeObject(forKey: CollectionViewController.collectionViewSelectionKey) as? IndexSet {
            collection.selectionIndexes = decodedSelection
        }
    }
    
}
