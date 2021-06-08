/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The detail view controller navigated to from our main and results table.
*/

import UIKit

class DetailViewController: UIViewController {
    
    // The suffix portion of the user activity type for this view controller.
    static let activitySuffix = "detailRestored"
    
    // The user activity userInfo key to the archived product data.
    private static let restoredProductKey = "restoredProduct"
    
    // MARK: - Properties

    var product: Product!
    
    @IBOutlet private weak var yearLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    // Used by our scene delegate to return an instance of this class from our storyboard.
    static func loadFromStoryboard() -> DetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    }
    
    class func detailViewControllerForProduct(_ product: Product) -> UIViewController {
        let detailViewController = loadFromStoryboard()
        detailViewController!.product = product
        return detailViewController!
    }
    
    /** Returns the NSUserActivity string for this view controller.
        The activity string comes from the Info.plist that ends with the "activitySuffix" string.
    */
    func viewControllerActivityType() -> String {
        var returnActivityType = ""
        if let definedAppUserActivities = UIApplication.userActivitiyTypes {
            for activityType in definedAppUserActivities {
                if activityType.hasSuffix(DetailViewController.activitySuffix) {
                    returnActivityType = activityType
                    break
                }
            }
        }
        return returnActivityType
    }
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        assert(product != nil, "Error: a product must be assigned.")
        // Obtain the userActivity representation of the product.
        userActivity = productUserActivity(activityType: viewControllerActivityType())
        
        // Set the title's color to match the product color.
        let color = ResultsTableController.suggestedColor(fromIndex: product.color)
        let textAttributes = [NSAttributedString.Key.foregroundColor: color]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        title = product.title

        yearLabel.text = product.formattedDate()
        priceLabel.text = product.formattedPrice()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
	
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Reset the title's color to normal label color.
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        // No longer interested in the current activity.
        view.window?.windowScene?.userActivity = nil
    }

}

// MARK: - State Restoration

extension DetailViewController {
    
    // MARK: - UIUserActivityRestoring
    
    /** Returns the activity object you can use to restore the previous contents of your scene's interface.
        Before disconnecting a scene, the system asks your delegate for an NSUserActivity object containing state information for that scene.
        If you provide that object, the system puts a copy of it in this property.
        Use the information in the user activity object to restore the scene to its previous state.
    */
    override func updateUserActivityState(_ activity: NSUserActivity) {
        super.updateUserActivityState(activity)

        if let productDataToArchive = activityUserInfoEntry() {
            userActivity!.addUserInfoEntries(from: productDataToArchive)
        }
    }
    
    /** Restores the state needed to continue the given user activity.
        Subclasses override this method to restore the responder’s state with the given user activity.
        The override should use the state data contained in the userInfo dictionary of the given user activity to restore the object.
     */
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        product = productFromUserActivity(activity)
        super.restoreUserActivityState(activity)
    }

    // MARK: - NSUserActivity Support

    func activityUserInfoEntry() -> [String: Any]? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(product.self)
            return [DetailViewController.restoredProductKey: data as Any]
        } catch {
            Swift.debugPrint("Error encoding product: \(error)")
        }
        return nil
    }
    
    // Return the NSUserActivity representation of the product.
    func productUserActivity(activityType: String) -> NSUserActivity {
        // Setup the user activity as the Product to pass to the app which product we want to open.
        
        /** Create an NSUserActivity from the product.
            Note: The activityType string below must be included in your Info.plist file under the `NSUserActivityTypes` array.
            More info: https://developer.apple.com/documentation/foundation/nsuseractivity
        */
        let userActivity = NSUserActivity(activityType: activityType)
        userActivity.title = title
        
        // Target content identifier is a structured way to represent data in your model.
        // Set a string that identifies the content of this NSUserActivity.
        // Here the userActivity's targetContentIdentifier will simply be the product's title.
        userActivity.targetContentIdentifier = title
        
        if let productDataToArchive = activityUserInfoEntry() {
            userActivity.addUserInfoEntries(from: productDataToArchive)
        }
        return userActivity
    }
    
    // Return a Product instance from a user activity, used by "restoreUserActivityState".
    func productFromUserActivity(_ activity: NSUserActivity) -> Product? {
        var product: Product!
        if let userInfo = activity.userInfo {
            if let productData = (userInfo[DetailViewController.restoredProductKey]) as? Data {
                let decoder = JSONDecoder()
                if let savedProduct = try? decoder.decode(Product.self, from: productData) as Product {
                    product = savedProduct
                }
            }
        }
        return product
    }
    
}
