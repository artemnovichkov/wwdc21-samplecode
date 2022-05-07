/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The collection view of menu choices for this sample.
*/

import UIKit

private let reuseIdentifier = "Cell"

protocol MenuDescribable {
    static var title: String { get }
    static var description: String { get }
    static var iconName: String { get }
    static func create() -> UIViewController
}

protocol MenuViewControllerDelegate: AnyObject {
    func menuViewController(_ menuViewController: MenuViewController, didSelect viewController: UIViewController)
}

protocol MenuListCellDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, showDescriptionForItemAt indexPath: IndexPath)
}

class MenuViewController: UICollectionViewController, MenuListCellDelegate {

    class MenuListCell: UICollectionViewListCell {
        private var collectionView: UICollectionView? {
            var view = self.superview
            while view != nil && !view!.isKind(of: UICollectionView.self) {
                view = view!.superview
            }
            return view as? UICollectionView
        }

        @objc
        func showDescription() {
            guard let collectionView = collectionView else { return }
            guard let indexPath = collectionView.indexPath(for: self) else { return }
            guard let delegate = collectionView.delegate as? MenuListCellDelegate else { return }

            delegate.collectionView(collectionView, showDescriptionForItemAt: indexPath)
        }
    }

    private struct Menu: Hashable {
        private let item: MenuDescribable.Type

        var title: String { item.title }
        var description: String { item.description }
        var icon: UIImage { UIImage(systemName: item.iconName) ?? UIImage(systemName: "questionmark.square.dashed")! }

        func create() -> UIViewController { item.create() }

        init(for item: MenuDescribable.Type) {
            self.item = item
        }

        static func == (lhs: MenuViewController.Menu, rhs: MenuViewController.Menu) -> Bool {
            return lhs.item == rhs.item
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(self.title)
        }
    }

    private class var menuStructure: [Menu] {
        return [
            Menu(for: SearchResultsSample.self),
            Menu(for: SelectionSample.self),
            Menu(for: GroupsSample.self),
            Menu(for: GroupSortingSample.self),
            Menu(for: FocusGuideSample.self),
            Menu(for: KeyCommandsSample.self)
        ]
    }

    private var dataSource: UICollectionViewDiffableDataSource<Int, Menu>?

    public weak var delegate: MenuViewControllerDelegate?

    init() {
        super.init(collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .sidebar)))

        let infoCommand = UIKeyCommand(title: "Show sample info",
                                       action: #selector(MenuViewController.MenuListCell.showDescription),
                                       input: "i",
                                       modifierFlags: .command)
        self.addKeyCommand(infoCommand)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        let cellRegistration = UICollectionView.CellRegistration<MenuListCell, Menu>(handler: { cell, indexPath, menu in
            var configuration = cell.defaultContentConfiguration()
            configuration.image = menu.icon
            configuration.text = menu.title
            cell.contentConfiguration = configuration

            let button = UIButton(type: .detailDisclosure, primaryAction: UIAction() { [weak cell] _ in
                if let cell = cell {
                    cell.showDescription()
                }
            })
            cell.accessories = [ .customView(configuration: .init(customView: button, placement: .trailing())) ]
        })

        let dataSource = UICollectionViewDiffableDataSource<Int, Menu>(collectionView: self.collectionView,
                                                                       cellProvider: { collectionView, indexPath, menu in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: menu)
        })
        self.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Int, Menu>()
        snapshot.appendSections([0])
        snapshot.appendItems(MenuViewController.menuStructure)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - MenuListCellDelegate

    func collectionView(_ collectionView: UICollectionView, showDescriptionForItemAt indexPath: IndexPath) {
        guard let dataSource = self.dataSource else { fatalError() }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }

        let menu = dataSource.itemIdentifier(for: indexPath)!
        let description = DescriptionPopoverViewController(withTitle: menu.title, description: menu.description)
        description.modalPresentationStyle = .popover
        description.popoverPresentationController?.sourceView = cell
        description.popoverPresentationController?.permittedArrowDirections = .left
        self.present(description, animated: true)
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let dataSource = self.dataSource else { fatalError() }

        let menu = dataSource.itemIdentifier(for: indexPath)!
        let viewController = menu.create()
        self.delegate?.menuViewController(self, didSelect: viewController)
    }

}
