/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate class that handles the iCloud account availability checking.
*/

import UIKit
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window,
              let splitViewController = window.rootViewController as? UISplitViewController,
              let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
            fatalError("Failed to retrieve the navigation controller. Main.storyboard may be corrupted.")
        }
        
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController?.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self
    }

    // Check the account status and kick off the local cache building if iCloud is logged in.
    //
    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0 // Clear the badge number.

        let appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
        animateSpinner(start: true)
        
        // Check the account status. Fetch the current user ID and handle user switching, if necessary.
        // The completion handler runs in the main queue.
        //
        appDelegate.container.checkAccountStatus { (available, newUserRecordID, error) in
            self.animateSpinner(start: false)

            // If accountStatus doesn't return .available, or fetchUserRecordID() returns an error,
            // call handleAccountUnavailable to alert, and clear the cache and currentUserRecordID.
            //
            guard available, error == nil else {
                self.handleAccountUnavailable()
                return
            }
            
            let building = appDelegate.buildZoneCacheIfNeed(for: newUserRecordID)
            if building {
                self.animateSpinner(start: true)
            }
        }
    }
}

// MARK: - UISplitViewControllerDelegate
//
extension SceneDelegate: UISplitViewControllerDelegate {
    // Return false to always show the main view.
    //
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        return false
    }
}

// MARK: - Accepting a CloudKit share
//
// To be able to accept a share, add a CKSharingSupported entry in the info.plist file and set it to true.
//
extension SceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
        
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        acceptSharesOperation.acceptSharesCompletionBlock = { error in
            // Stop spinning and return if hitting any errors.
            //
            guard handleCloudKitError(error, operation: .acceptShare, alert: true) == nil,
                let zoneCache = appDelegate.zoneCacheOrNil, let cloudKitDB = zoneCache.cloudKitDB(with: .shared) else {
                DispatchQueue.main.async {
                    self.animateTopicSpinner(start: false)
                }
                return
            }
            
            // Start spinning again for the rest of the work in case sceneWillEnterForeground stopped
            // spinning in the completion handler of container.checkAccountStatus.
            //
            DispatchQueue.main.async {
                self.animateTopicSpinner(start: true)
            }
            
            // If the change happens on the current zone, update the topic cache by fetching the changes.
            //
            let zoneID = cloudKitShareMetadata.share.recordID.zoneID
            if let topicCache = appDelegate.topicCacheOrNil, topicCache.zone.zoneID == zoneID {
                topicCache.fetchChanges()
                return
            }

            // Switch to the zone directly if the zone exists. Zone switching eventually stops the spinning.
            //
            if let zone = zoneCache.zone(with: zoneID, cloudKitDB: cloudKitDB) {
                let payload = ZoneSwitched(cloudKitDB: cloudKitDB, zone: zone)
                let userInfo = [UserInfoKey.zoneSwitched: payload]
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .zoneDidSwitch, object: nil, userInfo: userInfo)
                }
                return
            }
            
            // The zone doesn't exist in the cache yet, so fetch the new zone and switch to it.
            // Zone switching eventually stops the spinning.
            //
            zoneCache.fetchNewZones(with: [zoneID], cloudKitDB: cloudKitDB) { zoneArray in
                // Stop spinning and return if failing to fetch the zone with zoneID.
                //
                guard let zone = zoneArray.first else {
                    DispatchQueue.main.async {
                        self.animateTopicSpinner(start: false)
                    }
                    return
                }
                // The zone is valid, so switch to it.
                //
                let payload = ZoneSwitched(cloudKitDB: cloudKitDB, zone: zone)
                let userInfo = [UserInfoKey.zoneSwitched: payload]
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .zoneDidSwitch, object: nil, userInfo: userInfo)
                }
            }
        }
        animateTopicSpinner(start: true)
        appDelegate.container.add(acceptSharesOperation)
    }
}

// MARK: - Checking account status
//
extension SceneDelegate {
    private func handleAccountUnavailable() {
        let title = "iCloud account is unavailable."
        let message = "Be sure to sign in iCloud and turn on iCloud Drive before using this sample."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        window?.rootViewController?.present(alert, animated: true)

        // Ask the app delegate to invalidate the current user.
        //
        let appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
        appDelegate.invalidateCurrentUser()
    }
}

// MARK: - Animating spinner
//
extension SceneDelegate {
    func animateTopicSpinner(start: Bool) {
        let rootVC = window?.rootViewController
        guard let splitViewController = rootVC as? UISplitViewController else {
            return
        }
        
        let count = splitViewController.viewControllers.count
        let navController = splitViewController.viewControllers[count - 1] as? UINavigationController
        let topVC = navController?.topViewController as? UINavigationController
        let detailNC = topVC ?? navController
        if let detailVC = detailNC?.topViewController as? MainViewController {
            _ = detailVC.view
            start ? detailVC.spinner.startAnimating() : detailVC.spinner.stopAnimating()
        }
    }
    
    private func animateZoneSpinner(start: Bool) {
        let rootVC = window?.rootViewController
        guard let splitViewController = rootVC as? UISplitViewController else {
            return
        }
        
        let masterNC = splitViewController.viewControllers.first as? UINavigationController
        if let masterVC = masterNC?.viewControllers.first as? ZoneViewController {
            _ = masterVC.view
            start ? masterVC.spinner.startAnimating() : masterVC.spinner.stopAnimating()
        }
    }
    
    private func animateSpinner(start: Bool) {
        animateZoneSpinner(start: start)
        animateTopicSpinner(start: start)
    }
}
