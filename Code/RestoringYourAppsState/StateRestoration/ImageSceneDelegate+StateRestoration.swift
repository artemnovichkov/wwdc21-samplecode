/*
See LICENSE folder for this sample’s licensing information.

Abstract:
State restoration support for this sample's secondary product image scene.
*/

import UIKit

@available(iOS 13.0, *)
extension ImageSceneDelegate {

    // Activity type for restoring (loaded from the plist).
    static let ImageSceneActivityType = { () -> String in
        // Load the activity type from the Info.plist.
        let activityTypes = Bundle.main.infoDictionary?["NSUserActivityTypes"] as? [String]
        return activityTypes![1]
    }

    /** Data key for storing in the session's userInfo.
        Mark this session's userInfo with the current product's identifier so you can use it later to update this scene if it's in the background.
    */
    static let productIdentifierKey = "productIdentifier"
    
    /** Return a Product instance from a user activity.
        Used by: scene:willConnectTo, scene:continue userActivity
    */
    class func product(for activity: NSUserActivity) -> Product? {
        var product: Product!
        if let userInfo = activity.userInfo {
            // Decode the user activity product identifier from the userInfo.
            if let productIdentifier = userInfo[ImageSceneDelegate.productIdentifierKey] as? String {
                product = DataModelManager.sharedInstance.product(fromIdentifier: productIdentifier)
            }
        }
        return product
    }

    class func activity(for product: Product) -> NSUserActivity {
        /** Create an NSUserActivity from the product.
            Note: You must include the activityType string below in your Info.plist file under the `NSUserActivityTypes` array.
            More info: https://developer.apple.com/documentation/foundation/nsuseractivity
        */
        let userActivity = NSUserActivity(activityType: ImageSceneDelegate.ImageSceneActivityType())

        /** Target content identifier is a structured way to represent data in your model.
            Set a string that identifies the content of this NSUserActivity.
            Here the userActivity's targetContentIdentifier is the product's UUID string.
        */
        userActivity.title = product.name
        userActivity.targetContentIdentifier = product.identifier.uuidString

        // Add the product identifier to the user activity.
        userActivity.addUserInfoEntries(from: [ImageSceneDelegate.productIdentifierKey: product.identifier.uuidString])
        
        return userActivity
    }

    /** This is the NSUserActivity for restoring the state when the Scene reconnects.
        It can be the same activity that you use for handoff or spotlight, or it can be a separate activity with
        a different activity type and userInfo.
     
        After the system calls this function, and before it saves the activity in the restoration file,
        if the returned NSUserActivity has a delegate (NSUserActivityDelegate), the function userActivityWillSave calls that delegate.
        Additionally, if any UIResponders have the activity set as their userActivity property, the system calls the UIResponder
        updateUserActivityState function to update the activity. This happens synchronously and ensures that the system has filled
        in all the information for the activity before saving it.
     */

    /** The user might be editing this product in another scene,
        so you can call this when you want to update this scene when calling "requestSceneSessionRefresh".
    */
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

}
