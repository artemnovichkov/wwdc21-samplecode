/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's main window scene delegate.
*/

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static let storyboardName = "Main"
    
    var window: UIWindow?
    
    /** Apps configure their UIWindow and attach it to the provided UIWindowScene scene.
        The system calls willConnectTo shortly after the app delegate's "configurationForConnecting" function.
        Use this function to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
     
        When using a storyboard file, as specified by the Info.plist key, UISceneStoryboardFile, the system automatically configures
        the window property and attaches it to the windowScene.
 
        Remember to retain the SceneDelegate's UIWindow.
        The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Determine the user activity from a new connection or from a session's state restoration.
        guard let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity else { return }
        
        if configure(window: window, session: session, with: userActivity) {
            // Remember this activity for later when this app quits or suspends.
            scene.userActivity = userActivity
            
            /** Set the title for this scene to allow the system to differentiate multiple scenes for the user.
                If set to nil or an empty string, the system doesn't display a title.
            */
            scene.title = userActivity.title
            
            // Mark this scene's session with this userActivity product identifier so you can update the UI later.
            if let sessionProduct = SceneDelegate.product(for: userActivity) {
                session.userInfo =
                    [SceneDelegate.productIdentifierKey: sessionProduct.identifier]
            }
        } else {
            Swift.debugPrint("Failed to restore scene from \(userActivity)")
        }
        
        /** Set up the activation predicates to determine which scenes to activate.
            Restrictions:
                Block-based predicates are not allowed.
                Regular expression predicates are not allowed.
                The only keyPath you can reference is "self".
        */
        let conditions = scene.activationConditions
        
        // The primary "can" predicate (the kind of content this scene can display — specific targetContentIdenfiers).
        conditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false)

        // The secondary "prefers" predicate (this scene displays certain content -— the product's identifier).
        if let activityProductIdentifier = session.userInfo![SceneDelegate.productIdentifierKey] as? String {
            let preferPredicate = NSPredicate(format: "self == %@", activityProductIdentifier)
            conditions.prefersToActivateForTargetContentIdentifierPredicate =
                NSCompoundPredicate(orPredicateWithSubpredicates: [preferPredicate])
        }
    }

    func configure(window: UIWindow?, session: UISceneSession, with activity: NSUserActivity) -> Bool {
        var succeeded = false
        
        // Check the user activity type to know which part of the app to restore.
        if activity.activityType == SceneDelegate.MainSceneActivityType() {
            // The activity type is for restoring DetailParentViewController.

            // Present a parent detail view controller with the specified product and selected tab.
            let storyboard = UIStoryboard(name: SceneDelegate.storyboardName, bundle: .main)
            
            guard let detailParentViewController =
                storyboard.instantiateViewController(withIdentifier: DetailParentViewController.viewControllerIdentifier)
                    as? DetailParentViewController else { return false }

            if let userInfo = activity.userInfo {
                // Decode the user activity product identifier from the userInfo.
                if let productIdentifier = userInfo[SceneDelegate.productKey] as? String {
                    let product = DataModelManager.sharedInstance.product(fromIdentifier: productIdentifier)
                    detailParentViewController.product = product
                }
                
                // Decode the selected tab bar controller tab from the userInfo.
                if let selectedTab = userInfo[SceneDelegate.selectedTabKey] as? Int {
                    detailParentViewController.restoredSelectedTab = selectedTab
                }
                
                // Push the detail view controller for the user activity product.
                if let navigationController = window?.rootViewController as? UINavigationController {
                    navigationController.pushViewController(detailParentViewController, animated: false)
                }
                
                succeeded = true
            }
        } else {
            // The incoming userActivity is not recognizable here.
        }
        
        return succeeded
    }
    
    /** Use this delegate as the system is releasing the scene or on window close.
        This occurs shortly after the scene enters the background, or when the system discards its session.
        Release any scene-related resources that the system can recreate the next time the scene connects.
        The scene may reconnect later because the system didn't necessarily discard its session (see`application:didDiscardSceneSessions` instead),
        so don't delete any user data or state permanently.
    */
    func sceneDidDisconnect(_ scene: UIScene) {
        //..
    }
    
    /** Use this delegate when the scene moves from an active state to an inactive state, on window close, or in iOS enter background.
        This may occur due to temporary interruptions (for example, an incoming phone call).
    */
    func sceneWillResignActive(_ scene: UIScene) {
        // Save any pending changes to the product list.
        DataModelManager.sharedInstance.saveDataModel()
        
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.resignCurrent()
        }
    }
    
    /** Use this delegate as the scene transitions from the background to the foreground, on window open, or in iOS resume.
        Use it to undo the changes made on entering the background.
    */
    func sceneWillEnterForeground(_ scene: UIScene) {
        //..
    }
    
    /** Use this delegate when the scene "has moved" from an inactive state to an active state.
        Also use it to restart any tasks that the system paused (or didn't start) when the scene was inactive.
        The system calls this delegate every time a scene becomes active so set up your scene UI here.
    */
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.becomeCurrent()
        }
    }

    /** Use this delegate as the scene transitions from the foreground to the background.
        Also use it to save data, release shared resources, and store enough scene-specific state information
        to restore the scene to its current state.
     */
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save any pending changes to the product list.
        DataModelManager.sharedInstance.saveDataModel()
    }

    // MARK: - Window Scene

    // Listen for size change.
    func windowScene(_ windowScene: UIWindowScene,
                     didUpdate previousCoordinateSpace: UICoordinateSpace,
                     interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                     traitCollection previousTraitCollection: UITraitCollection) {
        // The scene size has changed. (User moved the slider horizontally in either direction.)
    }
    
    func updateScene(with product: Product) {
        if let navController = window!.rootViewController as? UINavigationController {
            if let collectionView = navController.viewControllers[0] as? CollectionViewController {
                // Update the collection view.
                collectionView.collectionView.reloadData()
            }
            
            // Update the detail view controller.
            if let detailParentViewController = navController.topViewController as? DetailParentViewController {
                // Check that the view controller product identifier matches the incoming product identifier.
                if product.identifier.uuidString == detailParentViewController.product.identifier.uuidString {
                    detailParentViewController.product = product
                    window?.windowScene!.title = product.name
                }
            }
        }
    }
    
    // MARK: - Handoff support
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        //..
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == SceneDelegate.MainSceneActivityType() else { return }
 
        if let rootViewController = window?.rootViewController as? UINavigationController {
            // Update the detail view controller.
            if let detailParentViewController = rootViewController.topViewController as? DetailParentViewController {
                detailParentViewController.product = SceneDelegate.product(for: userActivity)
            }
        }
    }

    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("UnableToContinueTitle", comment: ""),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OKTitle", comment: ""), style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

}
