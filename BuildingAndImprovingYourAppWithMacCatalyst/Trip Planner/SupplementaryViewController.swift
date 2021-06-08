/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View Controller used as the supplementary column of our app's split view controller-based interface. `SupplementaryViewController`
            has to do some work to mainain selection states between the `UISplitViewController`'s `.primary` column and any detail view controllers.
*/

import UIKit

private enum Section: Hashable {
    case main
}

protocol ImageNaming {
    /// An image present in the app's asset catalog.
    var imageName: String { get }
}

extension NSNotification.Name {
    static let selectedItemDidChange = NSNotification.Name("selectedItemDidChange")
}

/// A collection view-based view controller to display selected model items.
class SupplementaryViewController: UIViewController, UICollectionViewDragDelegate {
    private let selectedItemsCollection: ModelItemsCollection

    private var browserViewController: BrowserSplitViewController? { splitViewController as? BrowserSplitViewController }

    var selectedItems: [AnyModelItem] {
        var items: [AnyModelItem] = []
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            items = selectedIndexPaths.reduce(into: items) { items, indexPath in
                if let item = dataSource.itemIdentifier(for: indexPath) {
                    items.append(item)
                }
            }
        }
        return items
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.dragInteractionEnabled = UIApplication.shared.supportsMultipleScenes
        collectionView.dragDelegate = UIApplication.shared.supportsMultipleScenes ? self : nil

        return collectionView
    }()

    private lazy var collectionViewLayout: UICollectionViewLayout = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.323), heightDimension: .fractionalWidth(0.323))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(1), top: .fixed(1), trailing: .fixed(1), bottom: .fixed(1))

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.333))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let config = UICollectionViewCompositionalLayoutConfiguration()
        return UICollectionViewCompositionalLayout(section: section, configuration: config)
    }()

    private lazy var itemCellRegistration = UICollectionView.CellRegistration<ImageCollectionViewConfigurationCell, AnyModelItem> {
        [unowned self] cell, indexPath, modelItem in
        cell.automaticallyUpdatesBackgroundConfiguration = false

        #if targetEnvironment(macCatalyst)
        cell.doubleTapCallback = {
            // Open a new window with the detail view for the double-clicked item.
            guard let doubleClickedItemIndexPath = collectionView.indexPath(for: cell) else { return }
            let options = UIScene.ActivationRequestOptions()
            options.collectionJoinBehavior = .preferred
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: modelItem.userActivity, options: options, errorHandler: nil)
        }
        #endif
    }

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, AnyModelItem> = {
        _ = itemCellRegistration

        return UICollectionViewDiffableDataSource<Section, AnyModelItem>(collectionView: collectionView) {
            [unowned self] cell, indexPath, modelItem in
            let cell = collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: modelItem)

            let image = modelItem.image
            let imageView = UIImageView(image: image)
            imageView.backgroundColor = .tertiarySystemBackground
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 3.0
            cell.contentView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.frame = cell.contentView.frame.insetBy(dx: 4, dy: 4)
            cell.contentView.addSubview(imageView)
            return cell
        }
    }()

    init(selectedItemsCollection: ModelItemsCollection) {
        self.selectedItemsCollection = selectedItemsCollection
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // swiflint:disable:next overridden_super_call
        view = UIView()

        // Slightly inset the collection view to make drag-and-drop animations appear nicer with respect to padding around the drag preview.
        view.backgroundColor = .systemBackground
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 3, leading: 2, bottom: 0, trailing: 2)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        viewRespectsSystemMinimumLayoutMargins = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        // This leads to nicer drag and drop visuals (the edges of cells near the edge aren't clipped when dragged).
        collectionView.clipsToBounds = false

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: margins.topAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = dataSource
        reloadSnapshot()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(itemCollectionChanged(_:)),
                                               name: .modelItemsCollectionDidChange,
                                               object: selectedItemsCollection)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func selectAll(_ sender: Any?) {
        for row in 0..<collectionView.numberOfItems(inSection: 0) {
            collectionView.selectItem(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .centeredVertically)
        }
    }

    @objc
    func itemCollectionChanged(_ note: Notification) {
        reloadSnapshot(animated: true)
        // If we've cleared all selected items, make sure to clear them on the split view controller.
        if collectionView.indexPathsForSelectedItems?.isEmpty ?? true {
            browserViewController?.detailItem = nil
        }
    }

    private func reloadSnapshot(animated: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, AnyModelItem>()
        snapshot.appendSections([.main])

        // Enhancement: Consider sorting by the item's name, or better yet by parent-item so animations are smoother.
        snapshot.appendItems(selectedItemsCollection.modelItems)

        dataSource.apply(snapshot, animatingDifferences: true)

        if let selectedItem = browserViewController?.detailItem {
            if let selectedItemIndex = dataSource.indexPath(for: selectedItem) {
                collectionView.selectItem(at: selectedItemIndex, animated: false, scrollPosition: [])
            }
        } else {
            collectionView.deselectAll()
        }
    }

    // MARK: - UICollectionViewDragDelegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            Swift.debugPrint("Missing Item at \(indexPath)")
            return []
        }
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(item.userActivity, visibility: .all)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        previewParameters.backgroundColor = view.tintColor

        if let cell = collectionView.cellForItem(at: indexPath) {
            previewParameters.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 8)
        }
        return previewParameters
    }

}

// MARK: - UICollectionViewDelegate

extension SupplementaryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let modelItem = dataSource.itemIdentifier(for: indexPath) else { return }
        if browserViewController?.detailItem != modelItem {
            browserViewController?.detailItem = modelItem
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if browserViewController?.detailItem != nil {
            browserViewController?.detailItem = nil
        }
    }
}
