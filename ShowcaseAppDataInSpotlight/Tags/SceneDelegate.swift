/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate class.
*/

import CoreSpotlight
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let userInfo = userActivity.userInfo as? [String: Any],
              let identifier = userInfo[CSSearchableItemActivityIdentifier] as? String else {
                  return
              }

        // Find the photo view controller.
        guard let rootViewController = window?.rootViewController as? UINavigationController,
              let photosViewController = rootViewController.topViewController as? PhotosViewController else {
                  return
              }

        let persistentContainer = appDelegate.coreDataStack.persistentContainer

        // Find the photo object and its image.
        guard let uri = URL(string: identifier),
              let objectID = persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri) else {
                  return
              }

        if let photo = persistentContainer.viewContext.object(with: objectID) as? Photo {
            guard let photoData = photo.photoData?.data,
                  let image = UIImage(data: photoData) else {
                      return
                  }
            
            // Present the photo.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageNC")
            guard let navController = viewController as? UINavigationController,
                  let imageViewController = navController.topViewController as? FullImageViewController else {
                      return
                  }
            imageViewController.fullImage = image
            navController.modalPresentationStyle = .fullScreen
            photosViewController.present(navController, animated: true)
        } else if let tag = persistentContainer.viewContext.object(with: objectID) as? Tag {
            guard let tagName = tag.name else {
                return
            }

            guard let searchBar = photosViewController.navigationItem.searchController?.searchBar else {
                return
            }
            searchBar.text = tagName
        }
    }
}
