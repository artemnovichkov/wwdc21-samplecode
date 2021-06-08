/*
See LICENSE folder for this sample’s licensing information.

Abstract:
State restoration support for this sample's main window scene delegate.
*/

import UIKit

@available(iOS 13.0, *)
extension SceneDelegate {
    
    // Activity type for restoring this scene (loaded from the plist).
    static let MainSceneActivityType = { () -> String in
        // Load the activity type from the Info.plist.
        let activityTypes = Bundle.main.infoDictionary?["NSUserActivityTypes"] as? [String]
        return activityTypes![0]
    }

    // State restoration keys:
    static let productKey = "product" // The product identifier.
    static let selectedTabKey = "selectedTab" // The selected tab bar item.
    static let presentedEditorKey = "presentedEditor" // Editor presentation state (true = presented).
    static let editorTitleKey = "editorTitle" // Editor title edit field.
    static let editorPriceKey = "editorPrice" // Editor price edit field.
    static let editorYearKey = "editorYear" // Editor year edit field.

    /** Data key for storing the session's userInfo.
        The system marks this session's userInfo with the current product's identifier so you can use it later
        to update this scene if it’s in the background.
    */
    static let productIdentifierKey = "productIdentifier"

    /** This is the NSUserActivity that you use to restore state when the Scene reconnects.
        It can be the same activity that you use for handoff or spotlight, or it can be a separate activity
        with a different activity type and/or userInfo.
     
        This object must be lightweight. You should store the key information about what the user was doing last.
     
        After the system calls this function, and before it saves the activity in the restoration file, if the returned NSUserActivity has a
        delegate (NSUserActivityDelegate), the function userActivityWillSave calls that delegate. Additionally, if any UIResponders have the activity
        set as their userActivity property, the system calls the UIResponder updateUserActivityState function to update the activity.
        This happens synchronously and ensures that the system has filled in all the information for the activity before saving it.
     */
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // Offer the user activity for this scene.

        // Check whether the EditViewController is showing.
        if  let rootViewController = window?.rootViewController as? UINavigationController,
            let detailParentViewController = rootViewController.topViewController as? DetailParentViewController,
            let presentedNavController = detailParentViewController.presentedViewController as? UINavigationController,
            let presentedViewController = presentedNavController.topViewController as? EditViewController {
                presentedViewController.updateUserActivity()
        }

        return scene.userActivity
    }

    // Utility function to return a Product instance from the input user activity.
    class func product(for activity: NSUserActivity) -> Product? {
         var product: Product!
         if let userInfo = activity.userInfo {
             // Decode the user activity product identifier from the userInfo.
             if let productIdentifier = userInfo[SceneDelegate.productKey] as? String {
                 product = DataModelManager.sharedInstance.product(fromIdentifier: productIdentifier)
             }
         }
         return product
    }
    
}
