/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A container view controller for displaying `AnyModelItem`s. This view controller encapsulates the logic for determining which view
            controller subclass to use to represent the various specific model items `AnyModelItem` can wrap.
*/

import UIKit

class DetailViewController: UIViewController {
    private let modelItem: AnyModelItem

    init(modelItem: AnyModelItem) {
        self.modelItem = modelItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = modelItem.name
        installChildDetailViewController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var activityItemsConfiguration: UIActivityItemsConfigurationReading? {
        get { modelItem }
        set {
            super.activityItemsConfiguration = newValue
            Swift.debugPrint("Cannot set activityItemsConfiguration")
        }
    }

    lazy var shareButtonItem: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(share(_:)))
    }()

#if os(iOS)
    lazy var printButtonItem: UIBarButtonItem = {
        let target: Any?
        if splitViewController == nil {
            target = children.first
        } else {
            target = nil
        }
        return UIBarButtonItem(image: UIImage(systemName: "printer"), style: .plain, target: target, action: #selector(printContent(_:)))
    }()
#endif

    @objc
    func share(_ sender: Any) {
        if let buttonItem = sender as? UIBarButtonItem, let activityItemsConfiguration = activityItemsConfiguration {
            let activityViewController = UIActivityViewController(activityItemsConfiguration: activityItemsConfiguration)
            activityViewController.popoverPresentationController?.barButtonItem = buttonItem
            present(activityViewController, animated: true, completion: nil)
        }
    }

    private func installChildDetailViewController() {
        var childViewController: UIViewController? = nil
        var barButtonItems = [UIBarButtonItem]()

        if let location = modelItem.locatedItem {
            let locatedItemViewController = LocatedItemDetailViewController(modelItem: location)
            childViewController = locatedItemViewController
            if let imageBarItem = locatedItemViewController.specialBarButtonImage {
                let imageView = UIImageView(image: imageBarItem)
                let iconItem = UIBarButtonItem(customView: imageView)
                barButtonItems = [iconItem]
            }
        } else if let rewardsProgram = modelItem.rewardsProgram {
            let storyboard = UIStoryboard(name: "RewardsDetail", bundle: nil)
            childViewController = storyboard.instantiateInitialViewController { coder in
                RewardsProgramDetailViewController(coder: coder, program: rewardsProgram)
            }
        }

        if let childViewController = childViewController {
            addChild(childViewController)
            self.view.addSubview(childViewController.view)
            childViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                childViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
                childViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
                childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            childViewController.didMove(toParent: self)

            barButtonItems.insert(shareButtonItem, at: 0)

            #if os(iOS)
            // On Mac Catalyst, it is sufficient to have the "Print" Menu Item only. Without the promise of a physical keyboard (for ⌘P key commands)
            // or an app menu bar, printing should be available prominently.
            barButtonItems.insert(printButtonItem, at: 1)
            #endif
            self.navigationItem.rightBarButtonItems = barButtonItems
        }
    }
}
