/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates selection changes across the split view controller's various columns.
*/

import UIKit

class BrowserSplitViewController: UISplitViewController {
    private(set) var selectedItemsCollection = ModelItemsCollection()
    private var supplementarySelectionChangeObserver: Any?
    
    var selectedItems: [AnyModelItem] {
        selectedItemsCollection.modelItems
    }

    var detailItem: AnyModelItem? {
        didSet {
            updateDueToDetailItemChange()
        }
    }
    
    let model = SampleData.data

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryBackgroundStyle = .sidebar

        setViewController(emptyNavigationController(), for: .secondary)
        setViewController(emptyNavigationController(), for: .supplementary)

        supplementarySelectionChangeObserver = NotificationCenter
        .default
        .addObserver(forName: .modelItemsCollectionDidChange, object: selectedItemsCollection, queue: nil) { [weak self] note in
            self?.updateDueToSelectedItemsChange()
        }

        updateDueToSelectedItemsChange()
        updateDueToDetailItemChange()
    }

    deinit {
        supplementarySelectionChangeObserver.map(NotificationCenter.default.removeObserver(_:))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        show(.primary)
    }

    private func postBrowserStateChangeNotification() {
        NotificationCenter.default.post(name: .browserStateDidChange, object: self)
    }

    private func updateDueToSelectedItemsChange() {
        if let navigationController = viewController(for: .supplementary) as? UINavigationController, navigationController.viewControllers.isEmpty {
                let viewController = SupplementaryViewController(selectedItemsCollection: selectedItemsCollection)
                navigationController.viewControllers = [viewController]
            }
            show(.supplementary)
            if selectedItemsCollection.modelItems.isEmpty {
                view.window?.windowScene?.subtitle = ""
            }
        postBrowserStateChangeNotification()
    }

    private func updateDueToDetailItemChange() {
        let subtitleKeyPath: ReferenceWritableKeyPath<UIScene, String>?
        if view.window?.windowScene != nil {
            // Using a writable keypath here helps us to not litter the code below with the target conditional (#if targetEnvironment...)
#if targetEnvironment(macCatalyst)
            subtitleKeyPath = \UIScene.subtitle
#else
            subtitleKeyPath = \UIScene.title
#endif
        } else {
            subtitleKeyPath = nil
        }

        if let detailItem = detailItem {
            if let navigationController = viewController(for: .secondary) as? UINavigationController {
                let detailViewController = DetailViewController(modelItem: detailItem)
                if let keyPath = subtitleKeyPath {
                    view.window?.windowScene?[keyPath: keyPath] = detailItem.name
                }
                navigationController.viewControllers = [detailViewController]
            }
        } else {
            setViewController(emptyNavigationController(), for: .secondary)
            if selectedItemsCollection.modelItems.isEmpty {
                if let keyPath = subtitleKeyPath, let scene = view.window?.windowScene {
                    scene[keyPath: keyPath] = ""
                }
            } else {
                if let keyPath = subtitleKeyPath, let scene = view.window?.windowScene {
                    scene[keyPath: keyPath] = selectedItemsCollection.subtitle(forMostRecentlySelected: nil)
                }
            }
        }
        NotificationCenter.default.post(name: .browserStateDidChange, object: self)
    }

    private func emptyNavigationController() -> UINavigationController {
        let emptyNavigationController = UINavigationController()
        #if targetEnvironment(macCatalyst)
        emptyNavigationController.isNavigationBarHidden = true
        #endif
        return emptyNavigationController
    }

    var sidebarViewController: SidebarViewController {
        (viewController(for: .primary) as! UINavigationController).viewControllers.first as! SidebarViewController
    }

    var detailViewController: DetailViewController? {
        (viewController(for: .secondary) as? UINavigationController)?.viewControllers.first as? DetailViewController
    }

    var supplementaryViewController: SupplementaryViewController? {
        (viewController(for: .supplementary) as? UINavigationController)?.viewControllers.first as? SupplementaryViewController
    }

    override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        switch action {
        case #selector(UIResponder.printContent(_:)):
            if supplementaryViewController?.selectedItems.count == 1, let specificDetailChild = detailViewController?.children.first {
                // Direct the responder chain to the detail view controller if the user only has a single item selected.
                return specificDetailChild
            } else {
                // Otherwise, print all of the selected items
                return self
            }
        default:
            return super.target(forAction: action, withSender: sender)
        }
    }

    // MARK: State restoration
    func restoreSelections(selectedItems: [AnyModelItem], detailItem: AnyModelItem?) {
        selectedItemsCollection.modelItems = selectedItems
        self.detailItem = detailItem
    }
    
    // MARK: Printing

    private var itemsToPrint: [AnyModelItem] {
        if let supplementaryViewController = supplementaryViewController,
           !supplementaryViewController.selectedItems.isEmpty {
            return supplementaryViewController.selectedItems
        } else {
            return selectedItems
        }
    }
    
    // This action will be used whenever any UIResponder within the BrowserSplitView is first responder, except if the
    // RewardsProgramDetailViewController or the LocatedItemDetailViewController are first responder.
    override func printContent(_ sender: Any?) {
        
        let printItems = itemsToPrint
        guard !printItems.isEmpty else {
            return
        }
        
        let renderer = ItemPrintPageRenderer(items: printItems)
        
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.orientation = .portrait
        
        if printItems.count == 1 {
            info.jobName = printItems.first!.name
        } else {
            info.jobName = "Multiple Items"
        }
        
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printPageRenderer = renderer
        printInteractionController.printInfo = info
        
        printInteractionController.present(from: .zero, in: self.view, animated: true) {controller, completed, error in
            if error != nil {
                Swift.debugPrint("Error while printing: \(String(describing: error))")
            }
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(self.printContent(_:)) {
            return ItemPrintPageRenderer.canPrint(items: itemsToPrint)
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

}

extension NSNotification.Name {
    static let browserStateDidChange = NSNotification.Name("browserStateDidChange")
}
