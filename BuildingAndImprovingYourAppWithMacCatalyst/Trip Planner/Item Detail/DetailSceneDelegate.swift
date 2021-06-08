/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The delegate for scenes created by "drilling-down" to view detail items. On iPad this is typically a drag interaction to create a new
            scene, on Mac Catalyst, a double-click of a collection view cell.
*/

import UIKit

class DetailSceneDelegate: UIResponder, UIWindowSceneDelegate {
    static let activityType: String = "com.example.TripPlanner.detailScene"

    // The `window` property will automatically be loaded with the storyboard's initial view controller.
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            configure(with: userActivity)
        }
        if let windowScene = scene as? UIWindowScene {
            #if targetEnvironment(macCatalyst)
            configureToolbar(windowScene: windowScene)
            #endif
        }
    }

    func configure(with userActivity: NSUserActivity) {
        var newUserActivity: NSUserActivity? = nil
        if let itemId = userActivity.userInfo?["itemID"] as? ItemIdentifierProviding.ItemID,
           let item = SampleData.data.item(withID: itemId) {
            let detailViewController = DetailViewController(modelItem: item)
            window?.windowScene?.title = item.name

            if let navigationController = window?.rootViewController as? UINavigationController {
#if targetEnvironment(macCatalyst)
                navigationController.isNavigationBarHidden = true
#endif
                navigationController.viewControllers = [detailViewController]
                newUserActivity = userActivity
            }
        }
        self.userActivity = newUserActivity
        newUserActivity?.becomeCurrent()
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return userActivity
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        configure(with: userActivity)
    }

#if targetEnvironment(macCatalyst)
    private var toolbarModel = DetailToolbarModel()

    func configureToolbar(windowScene: UIWindowScene) {
        let toolbar = NSToolbar(identifier: "detail")
        toolbar.delegate = toolbarModel
        windowScene.titlebar?.toolbar = toolbar
        windowScene.titlebar?.toolbarStyle = .unifiedCompact
    }
#endif

}

#if targetEnvironment(macCatalyst)
private class DetailToolbarModel: NSObject, NSToolbarDelegate {
    var shareItem = NSSharingServicePickerToolbarItem(itemIdentifier: .init("share"))

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [shareItem.itemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [shareItem.itemIdentifier]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case shareItem.itemIdentifier:
            return shareItem
        default:
            return nil
        }
    }
}
#endif
