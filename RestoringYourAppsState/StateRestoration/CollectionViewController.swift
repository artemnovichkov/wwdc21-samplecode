/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's main collection view for displaying a grid of products.
*/

import UIKit

class CollectionViewController: UICollectionViewController {
    
    private let sectionInset =
        UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // This collection view supports dragging items out to spwan new scenes.
        collectionView.dragDelegate = self
        
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumLineSpacing = sectionInset.left
            flowLayout.minimumInteritemSpacing = sectionInset.left
            flowLayout.sectionInset = sectionInset
            flowLayout.itemSize = CGSize(width: 110.0, height: 110.0)
        }
        
        /** You want to know when this view controller returns so you can reset the userActivity for state restoration.
            In this view controller, you don't restore anything.
        */
        navigationController!.delegate = self
    }

    // The user has tapped a collection view item, navigate to the detail parent view controller.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailParentViewController = segue.destination as? DetailParentViewController,
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
                let selectedItemPath = selectedIndexPaths.first

                let selectedProduct = DataModelManager.sharedInstance.products()[(selectedItemPath?.item)!]
                detailParentViewController.product = selectedProduct
            }
    }

}

// MARK: - UICollectionViewDataSource

extension CollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DataModelManager.sharedInstance.products().count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.reuseIdentifier, for: indexPath)
        if let itemCell = cell as? CollectionViewCell {
            itemCell.configureCell(with: DataModelManager.sharedInstance.products()[indexPath.item])
        }
        return cell
    }
    
}

// MARK: - UICollectionViewDragDelegate

extension CollectionViewController: UICollectionViewDragDelegate {
        
    // Provide items to begin a drag for a specified indexPath. If an empty array returns, a drag session doesn't begin.
    public func collectionView(_ collectionView: UICollectionView,
                               itemsForBeginning session: UIDragSession,
                               at indexPath: IndexPath) -> [UIDragItem] {
        let product = DataModelManager.sharedInstance.products()[indexPath.item]

        let image = UIImage(named: product.imageName)
        let itemProvider = NSItemProvider(object: image! as NSItemProviderWriting)
        
        if #available(iOS 13.0, *) {
            // Register the product user activity as part of the drag to create a new scene if dropped to the left or right of the screen.
            let userActivity = ImageSceneDelegate.activity(for: product)
            itemProvider.registerObject(userActivity, visibility: .all)
        }
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = product
        
        return [dragItem]
    }
    
    /** Call to request items to add to an existing drag session in response to the add item gesture.
        You can use the provided point (in the collection view's coordinate space) to do additional hit testing.
        If you don't implement this, or if an empty array returns, the system doesn't add items to the drag. It handles the gesture normally.
     */
    func collectionView(_ collectionView: UICollectionView,
                        itemsForAddingTo session: UIDragSession,
                        at indexPath: IndexPath,
                        point: CGPoint) -> [UIDragItem] {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: cell.imageView.image!))
            dragItem.localObject = true // Hint that makes it faster to drag and drop content within the same app.
            return [dragItem]
        } else {
            return []
        }
    }

}

// MARK: - UINavigationControllerDelegate

extension CollectionViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        if viewController == self && animated == true {
            /** Returning to this view controller after it popped with animation.
                Reset the userActivity for state restoration. At this view controller you don't restore anything.
            */
            if #available(iOS 13.0, *) {
                view.window?.windowScene?.session.scene!.userActivity = nil
            }
        }
    }
    
}

// MARK: - ContextMenu Support

@available(iOS 13.0, *)
extension CollectionViewController {

    // Create a new window scene for the product indexPath.
    func openNewWindowAction(indexPath: IndexPath) -> UIAction {

        let selectedProduct = DataModelManager.sharedInstance.products()[(indexPath.item)]
        
        // Create an NSUserActivity from the product to use in ImageSceneDelegate.
        let userActivity = ImageSceneDelegate.activity(for: selectedProduct)
        
        let activationOptions = UIScene.ActivationRequestOptions()
        // Informs the system of the interface instance the user interacted with to create the new interface for system navigation.
        activationOptions.requestingScene = self.view.window!.windowScene
        
        let newWindowAction = UIAction(title: NSLocalizedString("OpenNewWindowTitle", comment: ""),
                                       image: UIImage(systemName: "square.and.arrow.up.on.square")) { action in
            // Send the user activity (with the product info) to pass along for scene creation.
            UIApplication.shared.requestSceneSessionActivation(
                nil, // Pass nil to create a new scene.
                userActivity: userActivity,
                options: activationOptions) { (error) in
                    Swift.debugPrint("\(error)")
            }
        }
        
        return newWindowAction
    }
        
    override func collectionView(_ collectionView: UICollectionView,
                                 contextMenuConfigurationForItemAt indexPath: IndexPath,
                                 point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            var actions = [UIMenuElement]()
            
            // Add the Open New Window action for iPadOS devices only.
            if UIDevice.current.userInterfaceIdiom == .pad {
                let openNewWindowAction = self.openNewWindowAction(indexPath: indexPath)
                actions.append(openNewWindowAction)
            }
            return UIMenu(title: "", children: actions)
        }
    }

}
