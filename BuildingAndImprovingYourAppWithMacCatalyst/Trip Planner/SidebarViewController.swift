/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Displays a heterogeneous collection of model objects in a sidebar by wrapping them in `AnyModelItem`
*/
import UIKit

extension Country {
    var allModelItems: [AnyModelItem] {
        [lodgings.map(AnyModelItem.init), restaurants.map(AnyModelItem.init), sights.map(AnyModelItem.init)].flatMap { $0 }
    }
}

/// Sidebar sections
enum SidebarSection: Int, CaseIterable {
    case countries
    case rewardsPrograms

    // Per-country sections
    case lodging
    case restaurants
    case sights
    
    func children(for modelItem: AnyModelItem?) -> [AnyModelItem] {
        let sample = SampleData.data
        switch self {
        case .countries:
            return sample.countries.reduce(into: []) { result, country in
                result += country.allModelItems
            }
        case .rewardsPrograms:
            return sample.rewardsPrograms.map { AnyModelItem($0) }
        case .lodging:
            guard let country = modelItem?.country else { return [] }
            return country.lodgings.map { AnyModelItem($0) }
        case .restaurants:
            guard let country = modelItem?.country else { return [] }
            return country.restaurants.map { AnyModelItem($0) }
        case .sights:
            guard let country = modelItem?.country else { return [] }
            return country.sights.map { AnyModelItem($0) }
        }
    }
}

extension SidebarSection {
    var name: String {
        switch self {
        case .countries:
            return "Countries"
        case .rewardsPrograms:
            return "Rewards Programs"
        case .lodging:
            return "Lodging"
        case .restaurants:
            return "Restaurants"
        case .sights:
            return "Sights"
        }
    }

    var imageName: String {
        switch self {
        case .countries:
            return "globe"
        case .rewardsPrograms:
            return "giftcard"
        case .lodging:
            return "house"
        case .restaurants:
            return "person"
        case .sights:
            return "eye"
        }
    }
}

/// A collection item identifier
struct SidebarItemIdentifier: Hashable {
    enum Kind {
        case expandableSection(SidebarSection)
        case expandableModelSection(AnyModelItem, SidebarSection)
        case expandableModelItem(AnyModelItem)
        case leafModelItem(AnyModelItem)
        
        var children: [AnyModelItem] {
            switch self {
            case .leafModelItem(let modelItem):
                return [modelItem]
            case .expandableSection(let section):
                return section.children(for: nil)
            case .expandableModelSection(let subsection, let section):
                return section.children(for: subsection)
            case .expandableModelItem(let modelItem):
                let country = modelItem.country!
                return country.lodgings.map(AnyModelItem.init) +
                country.restaurants.map(AnyModelItem.init) +
                country.sights.map(AnyModelItem.init)
            }
        }

        /// Convenience for getting a human-readable name for the parent-most item of a `Kind`
        fileprivate var name: String {
            switch self {
            case .leafModelItem(let leaf):
                return leaf.name
            case .expandableSection(let section):
                return section.name
            case .expandableModelSection(let betterName, _):
                return betterName.name
            case .expandableModelItem(let anotherBetterName):
                return anotherBetterName.name
            }
        }
    }

    var name: String { kind.name }

    let kind: Kind

    static func == (lhs: SidebarItemIdentifier, rhs: SidebarItemIdentifier) -> Bool {
        switch lhs.kind {
        case .expandableSection(let lhsSection):
            if case let Kind.expandableSection(rhsSection) = rhs.kind {
                return lhsSection == rhsSection
            }
        case .expandableModelSection(let lhsItem, let lhsSection):
            if case let Kind.expandableModelSection(rhsItem, rhsSection) = rhs.kind {
                return lhsItem.itemID == rhsItem.itemID && lhsSection == rhsSection
            }
        case .expandableModelItem(let lhsItem):
            if case let Kind.expandableModelItem(rhsItem) = rhs.kind {
                return lhsItem.itemID == rhsItem.itemID
            }
        case .leafModelItem(let lhsItem):
            if case let Kind.leafModelItem(rhsItem) = rhs.kind {
                return lhsItem.itemID == rhsItem.itemID
            }
        }
        return false
    }

    func hash(into hasher: inout Hasher) {
        switch kind {
        case .expandableSection(let section):
            hasher.combine("expandableSection")
            hasher.combine(section.rawValue)
        case .expandableModelSection(let modelItem, let section):
            hasher.combine("expandableModelSection")
            modelItem.hash(into: &hasher)
            hasher.combine(section.rawValue)
        case .expandableModelItem(let modelItem):
            hasher.combine("expandableModelItem")
            modelItem.hash(into: &hasher)
        case .leafModelItem(let modelItem):
            hasher.combine("modelItem")
            modelItem.hash(into: &hasher)
        }
    }
}

/// A collection view-based view controller that displays model items
class SidebarViewController: UIViewController {
    private var browserSplitViewController: BrowserSplitViewController {
        self.splitViewController as! BrowserSplitViewController
    }

    private var selectedItemsCollection: ModelItemsCollection {
        browserSplitViewController.selectedItemsCollection
    }

    private var model: Model { browserSplitViewController.model }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()
    
    private let layout: UICollectionViewLayout = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }()

    // MARK: - Cell Registrations

    // Top-level header item
    private lazy var topLevelSectionHeadingRegistration = UICollectionView.CellRegistration<DynamicImageCollectionViewCell, SidebarSection> {
        cell, indexPath, section in
        cell.update(with: section)
        cell.disclosureAccessory = .outlineDisclosure(options: .init(style: .header))
    }

    // Intermediate, collapsible header item
    private lazy var intermediateSectionHeaderRegistration = UICollectionView.CellRegistration<DynamicImageCollectionViewCell, SidebarSection> {
        cell, indexPath, section in
        cell.update(with: section)
        cell.disclosureAccessory = .outlineDisclosure(options: .init(style: .cell))
    }

    // Intermediate, collapsible item
    private lazy var disclosableSectionHeaderRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AnyModelItem> {
        cell, indexPath, modelItem in
        var content = UIListContentConfiguration.sidebarCell()
        content.image = modelItem.iconImage
        content.text = modelItem.name
        cell.contentConfiguration = content
        cell.accessories = [.outlineDisclosure(options: .init(style: .cell))]
    }

    // Leaf item
    private lazy var leafItemRegistration = UICollectionView.CellRegistration<DynamicImageCollectionViewCell, AnyModelItem> {
        cell, indexPath, modelItem in
        cell.update(with: modelItem)
    }
    
    fileprivate private(set) lazy var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItemIdentifier> = {
        // Create registrations upfront, not in the data source callbacks
        let leafItemRegistration = leafItemRegistration
        let topLevelSectionHeadingRegistration = topLevelSectionHeadingRegistration
        let intermediateSectionHeaderRegistration = intermediateSectionHeaderRegistration
        let disclosableSectionHeaderRegistration = disclosableSectionHeaderRegistration
        
        return UICollectionViewDiffableDataSource<SidebarSection, SidebarItemIdentifier>(collectionView: collectionView) {
            collectionView, indexPath, itemIdentifier -> UICollectionViewCell in
            guard let section = SidebarSection(rawValue: indexPath.section) else { fatalError("Unknown section: \(indexPath.section)") }
            switch itemIdentifier.kind {
            case .expandableSection(let section):
                return collectionView.dequeueConfiguredReusableCell(using: topLevelSectionHeadingRegistration, for: indexPath, item: section)
            case .expandableModelSection(_, let section):
                return collectionView.dequeueConfiguredReusableCell(using: intermediateSectionHeaderRegistration, for: indexPath, item: section)
            case .expandableModelItem(let modelItem):
                return collectionView.dequeueConfiguredReusableCell(using: disclosableSectionHeaderRegistration, for: indexPath, item: modelItem)
            case .leafModelItem(let modelItem):
                return collectionView.dequeueConfiguredReusableCell(using: leafItemRegistration, for: indexPath, item: modelItem)
            }
        }
    }()
    
    override func loadView() {
        view = collectionView
    }
    
    private func addCountriesToSnapshot() {
        var countriesSectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItemIdentifier>()
        let countriesSectionHeaderIdentifier = SidebarItemIdentifier(kind: .expandableSection(.countries))
        countriesSectionSnapshot.append([countriesSectionHeaderIdentifier])

        let countries = model.countries
        let countryItems = countries.map { SidebarItemIdentifier(kind: .expandableModelItem(AnyModelItem($0))) }
        countriesSectionSnapshot.append(countryItems, to: countriesSectionHeaderIdentifier)

        for country in countries {
            let countryItemIdentifier = SidebarItemIdentifier(kind: .expandableModelItem(AnyModelItem(country)))

            let lodgingItemIdentifiers = country.lodgings.map { SidebarItemIdentifier(kind: .leafModelItem(AnyModelItem($0))) }
            if !lodgingItemIdentifiers.isEmpty {
                let countryLodgingIdentifier = SidebarItemIdentifier(kind: .expandableModelSection(AnyModelItem(country), .lodging))
                countriesSectionSnapshot.append([countryLodgingIdentifier], to: countryItemIdentifier)
                countriesSectionSnapshot.append(lodgingItemIdentifiers, to: countryLodgingIdentifier)
            }
            let restaurantItemIdentifiers = country.restaurants.map { SidebarItemIdentifier(kind: .leafModelItem(AnyModelItem($0))) }
            if !restaurantItemIdentifiers.isEmpty {
                let countryRestaurantIdentifier = SidebarItemIdentifier(kind: .expandableModelSection(AnyModelItem(country), .restaurants))
                countriesSectionSnapshot.append([countryRestaurantIdentifier], to: countryItemIdentifier)
                countriesSectionSnapshot.append(restaurantItemIdentifiers, to: countryRestaurantIdentifier)
            }
            let sightsItemIdentifiers = country.sights.map { SidebarItemIdentifier(kind: .leafModelItem(AnyModelItem($0))) }
            if !sightsItemIdentifiers.isEmpty {
                let countrySightsIdentifier = SidebarItemIdentifier(kind: .expandableModelSection(AnyModelItem(country), .sights))
                countriesSectionSnapshot.append([countrySightsIdentifier], to: countryItemIdentifier)
                countriesSectionSnapshot.append(sightsItemIdentifiers, to: countrySightsIdentifier)
            }
        }
        dataSource.apply(countriesSectionSnapshot, to: .countries, animatingDifferences: false)
    }

    private func addRewardsToSnapshot() {
        // Rewards programs
        var rewardsProgramsSectionSnapshot = NSDiffableDataSourceSectionSnapshot<SidebarItemIdentifier>()
        let rewardsProgramsHeaderIdentifier = SidebarItemIdentifier(kind: .expandableSection(.rewardsPrograms))
        rewardsProgramsSectionSnapshot.append([rewardsProgramsHeaderIdentifier])

        let rewardsPrograms = model.rewardsPrograms
        let rewardsProgramsIdentifiers = rewardsPrograms.map { SidebarItemIdentifier(kind: .leafModelItem(AnyModelItem($0))) }

        rewardsProgramsSectionSnapshot.append(rewardsProgramsIdentifiers, to: rewardsProgramsHeaderIdentifier)

        dataSource.apply(rewardsProgramsSectionSnapshot, to: .rewardsPrograms, animatingDifferences: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        // Top-level headers
        var snapshot = NSDiffableDataSourceSnapshot<SidebarSection, SidebarItemIdentifier>()
        snapshot.appendSections([.countries, .rewardsPrograms])
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)

        addCountriesToSnapshot()
        addRewardsToSnapshot()

        // Pre-select rows that are already selected. This is useful during state restoration.
        let selectedItems = selectedItemsCollection.modelItems
        let itemIdentifiers = selectedItems.compactMap { SidebarItemIdentifier(kind: .leafModelItem($0)) }
        collectionView.expandParentsToShow(leafItemIdentifiers: itemIdentifiers, dataSource: dataSource)

        for selectedItem in selectedItems {
            if let index = dataSource.indexPath(for: SidebarItemIdentifier(kind: .leafModelItem(selectedItem))) {
                collectionView.selectItem(at: index, animated: false, scrollPosition: [])
            }
        }

        // Subscribe our cells to content size category changes so they can redraw their images.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentSizeCategoryDidChange(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    @objc
    func contentSizeCategoryDidChange(_ note: Notification) {
        collectionView.visibleCells.forEach { cell in
            cell.setNeedsUpdateConfiguration()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        #if targetEnvironment(macCatalyst)
        self.navigationController?.isNavigationBarHidden = true
        #endif
    }
}

extension SidebarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let sidebarItemIdentifier = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        let selectedModelItems = sidebarItemIdentifier.kind.children

        selectedItemsCollection.add(modelItems: selectedModelItems)
        let subtitle = selectedItemsCollection.subtitle(forMostRecentlySelected: sidebarItemIdentifier)

        // We want slightly different treatment of the title versus the subtitle in Catalyst. On iPadOS, the title will show in the app switcher. On
        // Catalyst, the subtitle will show beneath the window's title.
        #if targetEnvironment(macCatalyst)
        view.window?.windowScene?.subtitle = subtitle
        #else
        view.window?.windowScene?.title = subtitle
        #endif
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let sidebarItemIdentifier = dataSource.itemIdentifier(for: indexPath) else { return }
        selectedItemsCollection.remove(modelItems: sidebarItemIdentifier.kind.children)

        let subtitle = selectedItemsCollection.subtitle(forMostRecentlySelected: nil)
        #if targetEnvironment(macCatalyst)
        view.window?.windowScene?.subtitle = subtitle
        #else
        view.window?.windowScene?.title = subtitle
        #endif
    }
}

private class DynamicImageCollectionViewCell: UICollectionViewListCell {
    var disclosureAccessory: UICellAccessory? = nil

    private var modelItem: AnyModelItem? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    private var section: SidebarSection? {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }

    func update(with modelItem: AnyModelItem) {
        self.modelItem = modelItem
    }

    func update(with section: SidebarSection) {
        self.section = section
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        if let modelItem = modelItem {
            var newConfiguration = UIListContentConfiguration.sidebarCell().updated(for: state)
            newConfiguration.text = modelItem.name
            newConfiguration.image = modelItem.iconImage
            contentConfiguration = newConfiguration
        } else if let section = section {
            var newConfiguration = UIListContentConfiguration.sidebarHeader().updated(for: state)
            newConfiguration.text = section.name
            newConfiguration.image = section.imageName.image()
            contentConfiguration = newConfiguration
        }
        // Add checkmarks
        var accessories = [UICellAccessory]()
        #if !targetEnvironment(macCatalyst)
        if state.isSelected {
            accessories = [.checkmark()]
        }
        #endif
        if let disclosureAccessory = disclosureAccessory {
            accessories.append(disclosureAccessory)
        }
        self.accessories = accessories
    }
}
