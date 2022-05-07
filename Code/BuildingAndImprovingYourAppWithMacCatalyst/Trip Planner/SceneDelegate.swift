/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    #if targetEnvironment(macCatalyst)
    private var toolbarModel: MainSceneToolbarModel = MainSceneToolbarModel()
    #endif

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
                
        #if targetEnvironment(macCatalyst)
        windowScene.titlebar?.toolbarStyle = .unified

        // Give the Catalyst version a toolbar that adds the new Big Sur-look to Catalyst Apps
        let toolbar = NSToolbar(identifier: "main")
        toolbar.delegate = toolbarModel
        toolbar.displayMode = .iconOnly
        
        windowScene.titlebar!.toolbar = toolbar

        // Don't allow the scene to become too small
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 932, height: 470)
        #endif

        if let browserViewController = window?.rootViewController as? BrowserSplitViewController {
            NotificationCenter
                .default
                .addObserver(self,
                             selector: #selector(browserStateChanged(_:)),
                             name: .browserStateDidChange,
                             object: browserViewController)
        }

        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            configure(with: userActivity)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
    }

    // State restoration
    static let activityType = "Browse"
    private var currentUserActivity: NSUserActivity? = nil

    var browserViewController: BrowserSplitViewController? { window?.rootViewController as? BrowserSplitViewController }

    func updateUserActivity() {
        var newUserActivity: NSUserActivity? = nil

        if let browserViewController = browserViewController {
            let userActivity = NSUserActivity(activityType: Self.activityType)

            var userInfo = [String: Any]()

            let selectedItems = browserViewController.selectedItems
            let selectedItemIDs = selectedItems.map { $0.itemID as String }
            userInfo["selectedItems"] = selectedItemIDs

            if let detailItem = browserViewController.detailItem {
                userInfo["detailItem"] = detailItem.itemID as String
            }

            userActivity.userInfo = userInfo
            newUserActivity = userActivity
        }
        self.currentUserActivity = newUserActivity
        newUserActivity?.becomeCurrent()
    }

    func configure(with userActivity: NSUserActivity) {
        if let userInfo = userActivity.userInfo {
            let selectedItemIDs: [String]? = userInfo["selectedItems"] as? [String]
            let detailItemID: String? = userInfo["detailItem"] as? String

            if let browserViewController = browserViewController {
                let model = browserViewController.model
                let selectedItems = selectedItemIDs != nil ? selectedItemIDs!.compactMap { model.item(withID: $0) } : []
                let detailItem = detailItemID != nil ? model.item(withID: detailItemID!) : nil
                browserViewController.restoreSelections(selectedItems: selectedItems, detailItem: detailItem)
            }
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        configure(with: userActivity)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return currentUserActivity
    }

    @objc
    func browserStateChanged(_ note: Notification) {
        updateUserActivity()
    }
}

#if targetEnvironment(macCatalyst)

private class MainSceneToolbarModel: NSObject, NSToolbarDelegate {
    var shareItem: NSSharingServicePickerToolbarItem = {
        NSSharingServicePickerToolbarItem(itemIdentifier: .init("share"))
    }()

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier.toggleSidebar,
            NSToolbarItem.Identifier.primarySidebarTrackingSeparatorItemIdentifier,
            shareItem.itemIdentifier
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier.toggleSidebar,
            NSToolbarItem.Identifier.flexibleSpace,
            NSToolbarItem.Identifier.primarySidebarTrackingSeparatorItemIdentifier,
            shareItem.itemIdentifier
        ]
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
