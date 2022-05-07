/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for editing the product's data.
*/

import UIKit

class EditViewController: UITableViewController {
    
    static let storyboardName = "EditViewController"
    static let viewControllerIdentifier = "EditNavViewController"
        
    // MARK: - Properties

    var product: Product!
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleField: UITextField!
    @IBOutlet var yearIntroducedField: UITextField!
    @IBOutlet var introPrice: UITextField!

    var restoredTitle: String!
    var restoredPrice: String!
    var restoredYear: String!
    
    weak var doneDelegate: DoneEditDelegate?
    
    // MARK: - Storyboard Support
    
    class func loadEditViewController() -> UINavigationController? {
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
        if let navigationController =
            storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as? UINavigationController {
            return navigationController
        }
        return nil
    }
    
    // MARK: - View Life Cycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        imageView.image = UIImage(named: product.imageName)
        
        // If you are restoring, use the restored values, otherwise use the product information.
        titleField.text = restoredTitle != nil ? restoredTitle : product.name
        yearIntroducedField.text = restoredYear != nil ? restoredYear : String("\(product.year)")
        introPrice.text = restoredPrice != nil ? restoredPrice : String("\(product.price)")
        
        if #available(iOS 13.0, *) {
            updateUserActivity()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if #available(iOS 13.0, *) {
            if let currentUserActivity = view.window?.windowScene?.userActivity {
                // The system is dismissing the scene. Remove user activity-related data.
                currentUserActivity.userInfo?.removeValue(forKey: SceneDelegate.presentedEditorKey)
                currentUserActivity.userInfo?.removeValue(forKey: SceneDelegate.editorTitleKey)
                currentUserActivity.userInfo?.removeValue(forKey: SceneDelegate.editorPriceKey)
                currentUserActivity.userInfo?.removeValue(forKey: SceneDelegate.editorYearKey)
            }
        }
    }
    
    // MARK: - Actions

    func performSceneUpdates() {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            
            // Filter out the scenes that have this product's identifier for session refresh.
            let filteredScenes = scenes.filter { scene in
                var productUserInfoKey: String?
                if let userInfo = scene.session.userInfo {
                    if let mainSceneDelegate = scene.delegate as? SceneDelegate {
                        productUserInfoKey = SceneDelegate.productIdentifierKey
                        
                        mainSceneDelegate.updateScene(with: self.product)
                    } else if let imageSceneDelegate = scene.delegate as? ImageSceneDelegate {
                        productUserInfoKey = ImageSceneDelegate.productIdentifierKey

                        if let productID = userInfo[productUserInfoKey!] as? String {
                            
                            if productID == self.product.identifier.uuidString {
                                // Ask ImageSceneDelegate to update.
                                imageSceneDelegate.updateScene(with: self.product)
                            }
                        }
                    }
                    
                    guard let productIdentifier = userInfo[productUserInfoKey!] as? String,
                              productIdentifier == self.product.identifier.uuidString else { return false }
                }
                return true
            }
            
            filteredScenes.forEach { scene in
                /** This updates the UI and the snapshot in the task switcher, the state restoration acitvity, and so forth.
                    The system doesn't always fulfill this request right away.
                */
                UIApplication.shared.requestSceneSessionRefresh(scene.session)
            }
        }
    }
    
    @IBAction func doneAction(sender: Any) {
        let newProduct = Product(identifier: self.product.identifier,
                                 name: titleField.text!,
                                 imageName: self.product.imageName,
                                 year: Int(yearIntroducedField.text!)!,
                                 price: Double(introPrice.text!)!)
        
        // Replace the old product with the newly edited one.
        if let productIndexToReplace = DataModelManager.sharedInstance.dataModel.products.firstIndex(of: self.product) {
            DataModelManager.sharedInstance.dataModel.products.remove(at: productIndexToReplace)
            DataModelManager.sharedInstance.dataModel.products.insert(newProduct, at: productIndexToReplace)
            self.product = newProduct
            DataModelManager.sharedInstance.saveDataModel()
        }

        // Notify an optional delegate that the system has completed editing.
        if self.doneDelegate != nil {
            self.doneDelegate?.doneEdit(self, product: self.product)
        }
        
        // Update the rest of the app due to the change.
        if #available(iOS 13.0, *) {
            performSceneUpdates()
        } else {
            // iOS 12.x view controller updates.
            if let presentingViewController = self.presentingViewController as? UINavigationController {
                if let collectionView = presentingViewController.viewControllers[0] as? CollectionViewController {
                    // Update the collection view.
                    collectionView.collectionView.reloadData()
                }
                if let detailParentViewController = presentingViewController.topViewController as? DetailParentViewController {
                    // Update the detail view controller.
                    detailParentViewController.product = product
                }
            }
        }
        
        // The user committed the product edit. Update any scenes that use that product.
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 13.0, *)
    /** Update the user activity for this view controller's scene.
        viewDidAppear calls this upon initial presentation. The SceneDelegate stateRestorationActivity delegate also calls it.
    */
    func updateUserActivity() {
        var currentUserActivity = view.window?.windowScene?.userActivity
        if currentUserActivity == nil {
            /** Note: You must include the activityType string below in your Info.plist file under the `NSUserActivityTypes` array.
                More info: https://developer.apple.com/documentation/foundation/nsuseractivity
            */
            currentUserActivity = NSUserActivity(activityType: SceneDelegate.MainSceneActivityType())
        }
        
        // Add the presented state.
        currentUserActivity?.addUserInfoEntries(from: [SceneDelegate.presentedEditorKey: true])

        // Add the editor's edit fields values.
        let editFieldEntries = [
            SceneDelegate.editorTitleKey: titleField.text,
            SceneDelegate.editorPriceKey: introPrice.text,
            SceneDelegate.editorYearKey: yearIntroducedField.text
        ]
        currentUserActivity?.addUserInfoEntries(from: editFieldEntries as [AnyHashable: Any])
        
        view.window?.windowScene?.userActivity = currentUserActivity
    }
}

// MARK: - UITextFieldDelegate

extension EditViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }

}

// MARK: - UIStateRestoring (iOS 12.x)

// The system calls these overrides for nonscene-based versions of this app in iOS 12.x.

extension EditViewController {
    
    static let restoreEditorTitle = "editorTitle"
    static let restoreEditorIntroPrice = "editorPrice"
    static let restoreEditorYearIntroduced = "editorYear"
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        coder.encode(titleField.text, forKey: EditViewController.restoreEditorTitle)
        coder.encode(yearIntroducedField.text, forKey: EditViewController.restoreEditorYearIntroduced)
        coder.encode(introPrice.text, forKey: EditViewController.restoreEditorIntroPrice)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        if let title = coder.decodeObject(forKey: EditViewController.restoreEditorTitle) as? String {
            restoredTitle = title
        }
        if let price = coder.decodeObject(forKey: EditViewController.restoreEditorIntroPrice) as? String {
            restoredPrice = price
        }
        if let year = coder.decodeObject(forKey: EditViewController.restoreEditorYearIntroduced) as? String {
            restoredYear = year
        }
    }

}

// MARK: - DoneEditDelegate

protocol DoneEditDelegate: AnyObject {
    // Notifies the delegate that the system has completed editing the product.
    func doneEdit(_ editViewController: EditViewController, product: Product)
}
