/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application scene delegate.
*/

import UIKit
import SoupKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        #if targetEnvironment(macCatalyst)
            if let titlebar = windowScene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
        #endif
        
        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.primaryBackgroundStyle = .sidebar
            splitViewController.delegate = self
            
            if let detailController = splitViewController.viewController(for: .secondary) as? OrderDetailViewController {
                detailController.purpose = .historicalOrder
            }
        }
    }
        
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSStringFromClass(OrderSoupIntent.self) ||
            userActivity.activityType == NSUserActivity.viewMenuActivityType ||
            userActivity.activityType == NSUserActivity.orderCompleteActivityType else {
                Logger().debug("Can't continue unknown NSUserActivity type \(userActivity.activityType)")
                return
        }

        // Pass the user activity to a view controller that is able to continue the specific activity.
        if let splitViewController = window?.rootViewController as? UISplitViewController,
           let navController = splitViewController.viewController(for: .primary) as? UINavigationController,
           let orderHistoryController = navController.topViewController as? OrderHistoryViewController {
            
            orderHistoryController.restoreUserActivityState(userActivity)
        }
    }
}

extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        // Display the primary column when transitioning to a compact size class.
        return .primary
    }
}
