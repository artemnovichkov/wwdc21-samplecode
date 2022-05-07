/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class shows soup order details. When configured with a 'newOrder' purpose,
 the view controller collects details of a new order. When configured with a 'historicalOrder'
 purpose, the view controller displays details of a previously placed order.
*/

import UIKit
import SoupKit
import os.log
import IntentsUI

class OrderDetailViewController: UIViewController {
    
    enum Purpose {
        case newOrder, historicalOrder
    }
    
    var order: Order! {
        didSet {
            configureDataSource()
        }
    }
    var purpose: Purpose = .newOrder {
        didSet {
            navigationItem.rightBarButtonItem = (purpose == .newOrder) ? orderButton : nil
        }
    }
    
    private var collectionView: UICollectionView! = nil
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    
    private var titleCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var sectionHeaderCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var priceCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var quantityCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var choiceCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var siriCellRegistration: UICollectionView.CellRegistration<AddToSiriCollectionViewCell, Item>!
    
    private var orderButton: UIBarButtonItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        orderButton = navigationItem.rightBarButtonItem
        configureCollectionView()
    }
}

// MARK: - IntentsUI Delegates

extension OrderDetailViewController: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    /// - Tag: edit_phrase
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            Logger().debug("Error adding voice shortcut \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            Logger().debug("Error editing voice shortcut \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Collection View Setup

extension OrderDetailViewController: UICollectionViewDelegate {
    private func configureCollectionView() {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        self.collectionView = collectionView
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let section = self.visibleSections(for: self.purpose)[sectionIndex]
            
            var configuration: UICollectionLayoutListConfiguration
            if section == .soupDescription || section == .siri {
                configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            } else {
                configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
                configuration.headerMode = .firstItemInSection
            }
            
            configuration.backgroundColor = .systemGroupedBackground
            
            let sectionLayout = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return sectionLayout
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard purpose == .newOrder else { return }
        
        if let item = dataSource.itemIdentifier(for: indexPath),
           item.type == .choice,
           let rawValue = item.rawValue,
           let rawString = rawValue as? String,
           let topping = Order.MenuItemTopping(rawValue: rawString) {
            
            if order.menuItemToppings.contains(topping) {
                order.menuItemToppings.remove(topping)
            } else {
                order.menuItemToppings.insert(topping)
            }
            
            updateSnapshot()
        }
    }
}

// MARK: - Collection View Data Mangement

extension OrderDetailViewController {
    
    private enum Section: String {
        case soupDescription
        case price = "Price"
        case quantity = "Quantity"
        case toppings = "Toppings"
        case total = "Total"
        case siri
    }
    
    private enum CellType {
        case titleBanner
        case sectionHeader
        case price // Unit price and total price
        case quantity // Number of units
        case choice // Toppings
        case siri
    }
    
    private class Item: Hashable, Identifiable {
        let type: CellType
        let text: String?
        let rawValue: AnyHashable?
        let enabled: Bool
        
        init(type: CellType, text: String? = nil, rawValue: AnyHashable? = nil, enabled: Bool = false) {
            self.type = type
            self.text = text
            self.rawValue = rawValue
            self.enabled = enabled
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    private func visibleSections(for purpose: OrderDetailViewController.Purpose) -> [Section] {
        if purpose == .newOrder {
            return [.soupDescription, .price, .quantity, .toppings, .total]
        } else {
            return [.soupDescription, .quantity, .toppings, .total, .siri]
        }
    }
    
    private func items(for order: Order, in section: Section) -> [Item] {
        switch section {
        case .soupDescription:
            return [Item(type: .titleBanner, text: order.menuItem.localizedName(), rawValue: order.menuItem)]
        case .price:
            return [Item(type: .sectionHeader, text: section.rawValue),
                    Item(type: .price, text: NumberFormatter.currencyFormatter.string(from: (order.menuItem.price as NSDecimalNumber)))]
        case .total:
            return [Item(type: .sectionHeader, text: section.rawValue),
                    Item(type: .price, text: NumberFormatter.currencyFormatter.string(from: (order.total as NSDecimalNumber)))]
        case .quantity:
            return [Item(type: .sectionHeader, text: section.rawValue),
                    Item(type: .quantity, text: "\(order.quantity)", rawValue: order.quantity)]
        case .toppings:
            var toppings = Order.MenuItemTopping.allCases.map { (topping) -> Item in
                Item(type: .choice, text: topping.localizedName(), rawValue: topping.rawValue, enabled: order.menuItemToppings.contains(topping))
            }
            let sectionHeader = Item(type: .sectionHeader, text: section.rawValue)
            toppings.insert(sectionHeader, at: 0)
            return toppings
        case .siri:
            return [Item(type: .siri)]
        }
    }
    
    private func configureDataSource() {
        prepareCellRegistrations()
            
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            switch item.type {
            case .titleBanner:
                return collectionView.dequeueConfiguredReusableCell(using: self.titleCellRegistration, for: indexPath, item: item)
            case .choice:
                return collectionView.dequeueConfiguredReusableCell(using: self.choiceCellRegistration, for: indexPath, item: item)
            case .price:
                return collectionView.dequeueConfiguredReusableCell(using: self.priceCellRegistration, for: indexPath, item: item)
            case .quantity:
                return collectionView.dequeueConfiguredReusableCell(using: self.quantityCellRegistration, for: indexPath, item: item)
            case .siri:
                return collectionView.dequeueConfiguredReusableCell(using: self.siriCellRegistration, for: indexPath, item: item)
            case .sectionHeader:
                return collectionView.dequeueConfiguredReusableCell(using: self.sectionHeaderCellRegistration, for: indexPath, item: item)
            }
        }
        
        updateSnapshot()
    }
    
    private func prepareCellRegistrations() {
        titleCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.text
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)

            if let menuItem = item.rawValue as? MenuItem {
                content.image = UIImage(named: menuItem.iconImageName)
                content.imageProperties.cornerRadius = 8
                cell.contentConfiguration = content
                cell.contentView.backgroundColor = .systemGroupedBackground
            }
        }

        sectionHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.text
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .footnote)
            cell.contentConfiguration = content
        }

        priceCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = item.text
            cell.contentConfiguration = contentConfiguration
        }

        quantityCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = item.text
            cell.contentConfiguration = contentConfiguration

            let hidden = self.purpose == .historicalOrder
            let stepper = self.createStepper(value: item.rawValue as? Double ?? 1)
            var accessory = UICellAccessory.CustomViewConfiguration(customView: stepper, placement: .trailing(), isHidden: hidden)
            accessory.reservedLayoutWidth = .actual
            cell.accessories = [UICellAccessory.customView(configuration: accessory)]
        }

        choiceCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = item.text
            cell.contentConfiguration = contentConfiguration
            cell.accessories = item.enabled ? [.checkmark()] : []
        }

        siriCellRegistration = UICollectionView.CellRegistration<AddToSiriCollectionViewCell, Item> { cell, indexPath, item in
            var contentConfiguration = AddToSiriCellContentConfiguration()
            contentConfiguration.intent = self.order.intent
            contentConfiguration.delegate = self
            cell.contentConfiguration = contentConfiguration
        }
    }
    
    private func createStepper(value: Double) -> UIStepper {
        let stepper = UIStepper()
        stepper.value = value
        stepper.minimumValue = 1
        stepper.maximumValue = 100
        stepper.stepValue = 1
        stepper.addTarget(self, action: #selector(OrderDetailViewController.quantityStepperDidChange(_:)), for: .valueChanged)
        return stepper
    }
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        let sections = order != nil ? visibleSections(for: purpose) : []
        snapshot.appendSections(sections)
        for section in sections {
            snapshot.appendItems(items(for: order, in: section), toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
    
    @objc
    private func quantityStepperDidChange(_ sender: UIStepper) {
        order.quantity = Int(sender.value)
        updateSnapshot()
    }
}
