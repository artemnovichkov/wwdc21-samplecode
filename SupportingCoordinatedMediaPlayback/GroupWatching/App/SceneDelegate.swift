/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's scene delegate object that observes when group sessions become available.
*/

import UIKit
import Combine
import GroupActivities

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { fatalError() }
        window = createWindow(for: windowScene)
        window?.makeKeyAndVisible()
    }
    
    private func createWindow(for windowScene: UIWindowScene) -> UIWindow {
        
        let list = MovieListViewController()
        let player = MoviePlayerViewController()
        // Set the default poster to the first movie in the library.
        player.updatePoster(for: Library.shared.movies[0])
        
        var rootViewController: UIViewController
        
        if windowScene.traitCollection.userInterfaceIdiom == .phone {
            // The single-screen UI for iPhone.
            rootViewController = MovieDetailViewController(player: player, list: list)
        } else {
            // The splitview UI for iPad.
            let movieInfo = MovieInfoViewController()
            let detail = MovieDetailViewController(player: player, info: movieInfo)
            
            let svc = UISplitViewController(style: .doubleColumn)
            svc.preferredDisplayMode = .oneBesideSecondary
            svc.preferredSplitBehavior = .tile
            svc.presentsWithGesture = true
            svc.displayModeButtonVisibility = .automatic
            svc.setViewController(list, for: .primary)
            svc.setViewController(detail, for: .secondary)
            rootViewController = svc
        }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        return window
    }
}
