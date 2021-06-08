/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application's primary scene delegate class.
*/

import UIKit

extension NSUserActivity {
    
    func hasRestoreActivity() -> Bool {
        return userInfo != nil && !userInfo!.isEmpty
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        /** Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
            If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
            This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        */
        guard let scene = (scene as? UIWindowScene) else { return }
        
        scene.userActivity =
            session.stateRestorationActivity ??
            NSUserActivity(activityType: MainTableViewController.viewControllerActivityType())
        
        // Is there something to restore?
        if scene.userActivity!.hasRestoreActivity() {
            // Check if we need to restore the MainTableViewController.
            if scene.userActivity!.activityType.hasSuffix(MainTableViewController.activitySuffix) {
                if let navigationController = window?.rootViewController as? UINavigationController {
                    if let mainTableViewController = navigationController.topViewController {
                        mainTableViewController.restoreUserActivityState(scene.userActivity!)
                    }
                }
            } else // Check if we need to restore the DetailViewController.
                if scene.userActivity!.activityType.hasSuffix(DetailViewController.activitySuffix) {
                    if let detailViewController = DetailViewController.loadFromStoryboard() {
                        if let navigationController = window?.rootViewController as? UINavigationController {
                            if let mainTableVC = navigationController.topViewController as? MainTableViewController {
                                mainTableVC.navigationController?.pushViewController(detailViewController, animated: false)
                                detailViewController.restoreUserActivityState(scene.userActivity!)
                            }
                        }
                    }
                } else {
                    // Some other user activity is being restored.
                }
        }
    }

    // Called when the app is sent to the background to restore state.
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        if let navigationController = window?.rootViewController as? UINavigationController {
            if let currentViewController = navigationController.topViewController as? DetailViewController {
                return currentViewController.userActivity
            } else if let currentViewController = navigationController.topViewController as? MainTableViewController {
                return currentViewController.userActivity
            }
        }
        return scene.userActivity
    }

}

