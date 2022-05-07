/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class displays a list of previously placed orders.
*/

import UIKit
import SoupKit

class OrderHistoryViewController: UIViewController {
    
    private let soupMenuManager = SoupMenuManager()
    private let soupOrderManager = SoupOrderDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        configureCollectionView()
        configureDataSource()
    }
    
    // MARK: - Navigation
    
    private enum SegueIdentifiers: String {
        case soupMenu = "Soup Menu"
        case configureMenu = "Configure Menu"
    }
    
    // This IBAction exposes a unwind segue in the storyboard.
    @IBAction private func unwindToOrderHistory(segue: UIStoryboardSegue) {}

    @IBAction private func placeNewOrder(segue: UIStoryboardSegue) {
        if let source = segue.source as? OrderDetailViewController {
            soupOrderManager.placeOrder(order: source.order)
        }
    }
    
    private func displayOrderDetail(_ order: Order) {
        guard let detailVC = splitViewController?.viewController(for: .secondary) as? OrderDetailViewController else { return }
        detailVC.order = order
        splitViewController?.show(.secondary)
    }
    
    @IBAction private func clearHistory(_ sender: Any) {
        soupOrderManager.clearOrderHistory()
        guard let detailVC = splitViewController?.viewController(for: .secondary) as? OrderDetailViewController else { return }
        detailVC.order = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.configureMenu.rawValue {
            if let navController = segue.destination as? UINavigationController,
                let configureMenuTableViewController = navController.viewControllers.first as? ConfigureMenuTableViewController {
                configureMenuTableViewController.soupMenuManager = soupMenuManager
                configureMenuTableViewController.soupOrderDataManager = soupOrderManager
            }
        } else if segue.identifier == SegueIdentifiers.soupMenu.rawValue {
            if let navController = segue.destination as? UINavigationController,
                let menuController = navController.viewControllers.first as? SoupMenuViewController {

                if let activity = sender as? NSUserActivity, activity.activityType == NSStringFromClass(OrderSoupIntent.self) {
                    menuController.userActivity = activity
                } else {
                    menuController.userActivity = NSUserActivity.viewMenuActivity
                }
            }
        }
    }

    /// - Tag: continue_nsua
    /// The system calls this method when continuing a user activity through the restoration handler
    /// in `UISceneDelegate scene(_:continue:)`.
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)

        if activity.activityType == NSUserActivity.viewMenuActivityType {
            
            // This order came from the "View Menu" shortcut that is based on NSUserActivity.
            prepareForUserActivityRestoration() {
                self.performSegue(withIdentifier: SegueIdentifiers.soupMenu.rawValue, sender: nil)
            }
            
        } else if activity.activityType == NSStringFromClass(OrderSoupIntent.self) {
            
            // This order started as a shortcut, but isn't complete because the user tapped on the SoupChef Intent UI
            // during the order process. Let the user finish customizing their order.
            prepareForUserActivityRestoration() {
                self.performSegue(withIdentifier: SegueIdentifiers.soupMenu.rawValue, sender: activity)
            }
            
        } else if activity.activityType == NSUserActivity.orderCompleteActivityType,
                 let orderID = activity.userInfo?[NSUserActivity.ActivityKeys.orderID.rawValue] as? UUID,
                 let order = soupOrderManager.order(matching: orderID) {
            
            // This order was just created outside of the main app through an intent.
            // Display the order in the order history.
            prepareForUserActivityRestoration() {
                self.displayOrderDetail(order)
            }
        }
    }

    /// Ensures this view controller is visible and not presenting anything.
    private func prepareForUserActivityRestoration(completion: @escaping () -> Void) {
        splitViewController?.show(.primary)
        if presentedViewController != nil {
            dismiss(animated: false, completion: {
                completion()
            })
        } else {
            completion()
        }
    }
    
    // MARK: - Collection View Setup
    
    private var collectionView: UICollectionView! = nil
    
    func configureCollectionView() {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.collectionView = collectionView
        collectionView.delegate = self
    }
    
    // MARK: - Collection View Data Mangement
    
    private var ordersChangedObserver: NSObjectProtocol?
    private var dataSource: UICollectionViewDiffableDataSource<Section, Order>! = nil
    
    private enum Section {
        case history
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        return formatter
    }()

    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Order> { cell, indexPath, order in
            
            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.text = "\(order.quantity) \(order.menuItem.localizedName())"
            contentConfiguration.secondaryText = self.dateFormatter.string(from: order.date)
            contentConfiguration.image = UIImage(named: order.menuItem.iconImageName)
            contentConfiguration.imageProperties.cornerRadius = 8
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.disclosureIndicator()]
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Order>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Order) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        var snapshot = NSDiffableDataSourceSectionSnapshot<Order>()
        snapshot.append(soupOrderManager.orderHistory)
        dataSource.apply(snapshot, to: .history, animatingDifferences: false)
        
        ordersChangedObserver = NotificationCenter.default.addObserver(forName: dataChangedNotificationKey,
                                                                       object: soupOrderManager,
                                                                       queue: OperationQueue.main) {  [unowned self] (notification) in
            var snapshot = NSDiffableDataSourceSectionSnapshot<Order>()
            snapshot.append(self.soupOrderManager.orderHistory)
            self.dataSource.apply(snapshot, to: .history, animatingDifferences: true)
        }
    }
}

extension OrderHistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        displayOrderDetail(soupOrderManager.orderHistory[indexPath.item])
    }
}
