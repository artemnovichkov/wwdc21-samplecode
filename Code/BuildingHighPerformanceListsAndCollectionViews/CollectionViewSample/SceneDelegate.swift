/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = PostGridViewController(sectionsStore: SampleData.sectionsStore,
                                                               postsStore: SampleData.postsStore,
                                                               assetsStore: SampleData.assetsStore)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

}

