/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing a custom key command provided by the view controller.
*/

import UIKit

struct KeyCommandsSample: MenuDescribable {

    static var title = "Key Commands"
    static var iconName = "command"

    static var description = """
    This example shows a custom key command that the view controller provides but
    whoes method is implemented on each cell individually.

    The cell then generates a delegate callback from this to let the controller
    know to delete an item at the currently focused index path.

    Focus on a cell and press the delete key to delete the item.
    """

    static func create() -> UIViewController { KeyCommandsSampleViewController() }
}

@objc
protocol KeyCommandCollectionViewDelegate: UICollectionViewDelegate {
    @objc
    optional func collectionView(_ collectionView: UICollectionView, wantsToRemoveItemAt indexPath: IndexPath)
}

class KeyCommandSampleCell: CustomCollectionViewCell {
    private var collectionView: UICollectionView? {
        var view = self.superview
        while view != nil && !view!.isKind(of: UICollectionView.self) {
            view = view!.superview
        }
        return view as? UICollectionView
    }

    @objc
    func remove(_ sender: Any) {
        guard let collectionView = collectionView else { return }
        guard let indexPath = collectionView.indexPath(for: self) else { return }
        guard let delegate = collectionView.delegate as? KeyCommandCollectionViewDelegate else { return }

        delegate.collectionView?(collectionView, wantsToRemoveItemAt: indexPath)
    }
}

extension KeyCommandsSampleViewController: KeyCommandCollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, wantsToRemoveItemAt indexPath: IndexPath) {
        guard let dataSource = self.dataSource else {
            fatalError("Something is wrong with our internal state. We should never get this method if we don't have a data source.")
        }
        guard let itemIdentifierToRemove = dataSource.itemIdentifier(for: indexPath) else { return }

        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([itemIdentifierToRemove])
        self.dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

class KeyCommandsSampleViewController: UICollectionViewController {

    private var dataSource: UICollectionViewDiffableDataSource<Int, SampleData>?

    init() {
        super.init(collectionViewLayout: KeyCommandsSampleViewController.createLayout())

        let cellRegistration = UICollectionView.CellRegistration<KeyCommandSampleCell, SampleData>(handler: { cell, indexPath, data in
            cell.data = data
        })

        let dataSource = SampleData.createSampleDataSource(collectionView: self.collectionView, cellRegistration: cellRegistration)
        self.dataSource = dataSource

        self.collectionView.allowsFocus = true

        // We add the key command to the view controller, but because the cells are the start of the responder chain
        // when they are focused, their remove(_:) method is actually called.
        let keyCommand = UIKeyCommand(title: "Delete Symbol", action: #selector(remove(_:)), input: UIKeyCommand.inputDelete, modifierFlags: .command)
        self.addKeyCommand(keyCommand)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func remove(_ sender: Any) {
        // Just make sure noone above us gets this call so that we don't
        // accidentally trigger someone elses remove method.
        // Also this means we can reference the selector directly when creating the key command instead of referencing
        // the cell class even though we are not actually limiting the call to that class.
    }

    private class func createLayout() -> UICollectionViewLayout {
        let estimated = NSCollectionLayoutDimension.estimated(Layout.defaultSpacing * 3.0)
        let itemSize = NSCollectionLayoutSize(widthDimension: estimated, heightDimension: estimated)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: estimated)
        let group: NSCollectionLayoutGroup = .horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .flexible(Layout.defaultSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Layout.defaultSpacing
        let inset = Layout.defaultSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }
}

