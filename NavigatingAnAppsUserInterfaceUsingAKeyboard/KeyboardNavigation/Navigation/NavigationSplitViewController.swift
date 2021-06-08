/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's UISplitViewController's subclass.
*/

import UIKit

class NavigationSplitViewController: UISplitViewController {

    let menuController = MenuViewController()

    init() {
        super.init(style: .doubleColumn)

        self.menuController.delegate = self

        self.setViewController(UINavigationController(rootViewController: self.menuController), for: .primary)
        self.setViewController(UINavigationController(rootViewController: EmptyViewController()), for: .secondary)
        
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .oneBesideSecondary
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NavigationSplitViewController: MenuViewControllerDelegate {
    func menuViewController(_ menuViewController: MenuViewController, didSelect viewController: UIViewController) {
        self.showDetailViewController(UINavigationController(rootViewController: viewController), sender: nil)
    }
}
