/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Window scene delegate for managing the secondary product image scene.
*/

import UIKit

@available(iOS 13.0, *)
class ImageSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    /** Apps configure their UIWindow and attach it to the provided UIWindowScene. This is once per UI setup.
     
        When using a storyboard file, as specified by the Info.plist key, UISceneStoryboardFile,
        the system automatically configures the window property and attaches it to the windowScene.
 
        Remember to retain the SceneDelegate's UIWindow.
        The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Determine the user activity from a new connection or from a session's state restoration.
        guard let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity else { return }
            
        if configure(window: window, session: session, with: userActivity) {
            scene.userActivity = userActivity
            
            /** Set the title for this scene to allow the system to differentiate multiple scenes for the user.
                If set to nil or an empty string, the system doesn't display a title.
            */
            scene.title = userActivity.title

            // Mark this scene's session with this userActivity product identifier so you can update the UI later.
            if let sessionProduct = ImageSceneDelegate.product(for: userActivity) {
                session.userInfo =
                    [ImageSceneDelegate.productIdentifierKey: sessionProduct.identifier.uuidString]
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
        
        // The secondary "prefers" predicate (this scene displays certain content — the product's identifier).
        if let activityProductIdentifier = session.userInfo![SceneDelegate.productIdentifierKey] as? String {
            let preferPredicate = NSPredicate(format: "self == %@", activityProductIdentifier)
            conditions.prefersToActivateForTargetContentIdentifierPredicate =
                NSCompoundPredicate(orPredicateWithSubpredicates: [preferPredicate])
        }
    }
    
    // willConnectTo uses this delegate to set up the view controller and user activity.
    func configure(window: UIWindow?, session: UISceneSession, with activity: NSUserActivity) -> Bool {
        var succeeded = false
        
        /** Manually set the rootViewController to this window with our own storyboard.
            This is useful if you have one view controller per storyboard.
        */
        let storyboard = UIStoryboard(name: ImageViewController.storyboardName, bundle: .main)
        guard let navigationController = storyboard.instantiateInitialViewController() as? UINavigationController else { return false }
        guard let imageViewController = navigationController.topViewController as? ImageViewController else { return false }

        /** Use the appropriate user activity, either from the connection options when the system created the scene,
            or from the session the system is restoring.
        */
        
        /** If there were no user activities, you don't have to do anything.
            The `window` property automatically loads with the storyboard's initial view controller.
        */
        if activity.activityType == ImageSceneDelegate.ImageSceneActivityType() {
            if let product = ImageSceneDelegate.product(for: activity) {
                imageViewController.product = product
                succeeded = true
            }
        } else {
            // The incoming activity is not recognizable here.
        }
        
        window?.rootViewController = navigationController

        return succeeded
    }
    
    /** On window close.
        The system uses this delegate as it's releasing the scene or on window close..
        This occurs shortly after the scene enters the background, or when the system discards its session.
        Release any scene-related resources that the system can recreate the next time the scene connects.
        The scene may reconnect later because the system didn’t necessarily discard its session (see`application:didDiscardSceneSessions` instead),
        so don't delete any user data or state permanently.
    */
    func sceneDidDisconnect(_ scene: UIScene) {
        //..
    }
    
    // On window open or in iOS resume.
    func sceneWillEnterForeground(_ scene: UIScene) {
        //..
    }
    
    // On window close or in iOS enter background.
    func sceneWillResignActive(_ scene: UIScene) {
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.resignCurrent()
        }
    }
    
    // On window activation.
    // The system calls this delegate every time a scene becomes active so set up your scene UI here.
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let userActivity = window?.windowScene?.userActivity {
            userActivity.becomeCurrent()
        }
    }
    
    // MARK: - Window Scene

    func windowScene(_ windowScene: UIWindowScene,
                     didUpdate previousCoordinateSpace: UICoordinateSpace,
                     interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
                     traitCollection previousTraitCollection: UITraitCollection) {
        //Swift.debugPrint("Window scene \(windowScene.session.role) updated coordinates.")
        //Swift.debugPrint("coord space = \(String(describing: self.window?.rootViewController?.view.coordinateSpace))")
        
        // The scene size has changed. (User moved the slider horizontally in either direction.)
    }
    
    func updateScene(with product: Product) {
        if let navController = window!.rootViewController as? UINavigationController {
            if let imageViewController = navController.topViewController as? ImageViewController {
                imageViewController.product = product
                window?.windowScene!.title = product.name
            }
        }
    }
    
    // MARK: - Handoff support
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        //..
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == ImageSceneDelegate.ImageSceneActivityType() else { return }
        
        // Pass the user activity product over to this view controller.
        if let navController = window?.rootViewController as? UINavigationController {
            if let imageViewController = navController.topViewController as? ImageViewController {
                imageViewController.product = ImageSceneDelegate.product(for: userActivity)
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

