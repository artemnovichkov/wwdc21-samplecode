/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing search of a list of SF symbols in a given focus group.
*/

import UIKit

struct SearchResultsSample: MenuDescribable {

    static var title = "Search Results"
    static var iconName = "magnifyingglass"

    static var description = """
    Shows a custom search bar that is put into the same focus group than the \
    collection view showing the search results. This allows the user to press the \
    arrow down key to move focus from the search text field into the search results \
    and then navigate the search results with the arrow keys while still being able \
    to type into the search field.
    """

    static func create() -> UIViewController { SearchResultsSampleViewController() }
}

// MARK: - UISearchBarDelegate

extension SearchResultsSampleViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let results = !searchText.isEmpty ? self.allData?.filter({ $0.name.lowercased().contains(searchText.lowercased()) }) : self.allData
        var snapshot = NSDiffableDataSourceSnapshot<Int, SampleData>()
        snapshot.appendSections([0])
        snapshot.appendItems(results!)
        self.dataSource?.apply(snapshot, animatingDifferences: true)

        if !searchText.isEmpty {
            // Actively searching.
            self.collectionView.focusGroupIdentifier = searchBar.focusGroupIdentifier
        } else {
            // No searching, treat the collection view as its own group.
            self.collectionView.focusGroupIdentifier = FocusGroups.searchResults
        }
    }
}

// MARK: - SearchResultsSampleViewController

class SearchResultsSampleViewController: UICollectionViewController {

    private var allData: [SampleData]?
    private var dataSource: UICollectionViewDiffableDataSource<Int, SampleData>?

    init() {
        super.init(collectionViewLayout: SearchResultsSampleViewController.createLayout())

        let cellRegistration = UICollectionView.CellRegistration<CustomCollectionViewCell, SampleData>(handler: { cell, indexPath, data in
            cell.data = data
        })

        let dataSource = SampleData.createSampleDataSource(collectionView: self.collectionView, cellRegistration: cellRegistration)
        self.dataSource = dataSource
        self.allData = dataSource.snapshot().itemIdentifiers

        self.collectionView.allowsFocus = true

        let searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.frame.size.width = 320.0
        searchBar.delegate = self
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchBar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

