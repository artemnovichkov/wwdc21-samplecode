/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate to configure the scene's window and user interface.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        let splitViewController = NavigationSplitViewController()
        window.rootViewController = splitViewController

        window.makeKeyAndVisible()
        self.window = window
    }

}

