/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller displays the list of active menu items to the user.
*/

import UIKit
import SoupKit
import os.log

class SoupMenuViewController: UIViewController {
        
    private var menuItems: [MenuItem] = SoupMenuManager().findItems(exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
    }
      
    // MARK: - Navigation
    
    private enum SegueIdentifiers: String {
        case newOrder = "Show New Order Detail Segue"
    }
    
    override var userActivity: NSUserActivity? {
        didSet {
            if userActivity?.activityType == NSStringFromClass(OrderSoupIntent.self) {
                performSegue(withIdentifier: SegueIdentifiers.newOrder.rawValue, sender: userActivity)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.newOrder.rawValue {
            guard let destination = segue.destination as? OrderDetailViewController else { return }
            
            var order: Order?
            
            if let sender = sender as? MenuItem {
                order = Order(quantity: 1, menuItem: sender, menuItemToppings: [])
            } else if let activity = sender as? NSUserActivity,
                let orderIntent = activity.interaction?.intent as? OrderSoupIntent {
                order = Order(from: orderIntent)
            }
            
            if let order = order {
                destination.order = order
            }
        }
    }
    
    // MARK: - Collection View Setup
    
    private enum Section {
        case menu
    }
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, MenuItem>! = nil
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

    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MenuItem> { cell, indexPath, menuItem in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = menuItem.localizedName()
            contentConfiguration.image = UIImage(named: menuItem.iconImageName)
            contentConfiguration.imageProperties.cornerRadius = 8
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.disclosureIndicator()]
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MenuItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: MenuItem) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        var snapshot = NSDiffableDataSourceSectionSnapshot<MenuItem>()
        snapshot.append(menuItems)
        dataSource.apply(snapshot, to: .menu, animatingDifferences: false)
    }
}

extension SoupMenuViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.item]
        performSegue(withIdentifier: SegueIdentifiers.newOrder.rawValue, sender: menuItem)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
