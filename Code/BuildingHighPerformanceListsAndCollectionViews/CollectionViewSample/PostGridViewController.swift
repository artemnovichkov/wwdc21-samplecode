/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The grid view controller.
*/

import UIKit
import Combine

class PostGridViewController: UIViewController {

    var dataSource: UICollectionViewDiffableDataSource<Section.ID, DestinationPost.ID>! = nil
    var collectionView: UICollectionView! = nil
    
    var sectionsStore: AnyModelStore<Section>
    var postsStore: AnyModelStore<DestinationPost>
    var assetsStore: AssetStore
    
    fileprivate var prefetchingIndexPathOperations = [IndexPath: AnyCancellable]()
    fileprivate let sectionHeaderElementKind = "SectionHeader"
    
    init(sectionsStore: AnyModelStore<Section>, postsStore: AnyModelStore<DestinationPost>, assetsStore: AssetStore) {
        self.sectionsStore = sectionsStore
        self.postsStore = postsStore
        self.assetsStore = assetsStore
        
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Destinations"
        configureHierarchy()
        configureDataSource()
        setInitialData()
    }
}

extension PostGridViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<DestinationPostCell, DestinationPost.ID> { [weak self] cell, indexPath, postID in
            guard let self = self else { return }
            
            let post = self.postsStore.fetchByID(postID)
            let asset = self.assetsStore.fetchByID(post.assetID)
            
            // Retrieve the token that's tracking this asset from either the prefetching operations dictionary
            // or just use a token that's already set on the cell, which is the case when a cell is being reconfigured.
            var assetToken = self.prefetchingIndexPathOperations.removeValue(forKey: indexPath) ?? cell.assetToken
            
            // If the asset is a placeholder and there is no token, ask the asset store to load it, reconfiguring
            // the cell in its completion handler.
            if asset.isPlaceholder && assetToken == nil {
                assetToken = self.assetsStore.loadAssetByID(post.assetID) { [weak self] in
                    self?.setPostNeedsUpdate(postID)
                }
            }
            
            cell.assetToken = assetToken
            cell.configureFor(post, using: asset)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section.ID, DestinationPost.ID>(collectionView: collectionView) {
            (collectionView, indexPath, identifier) in
            
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        
        let headerRegistration = createSectionHeaderRegistration()
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    private func setPostNeedsUpdate(_ id: DestinationPost.ID) {
        var snapshot = self.dataSource.snapshot()
        snapshot.reconfigureItems([id])
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func setInitialData() {
        // Initial data
        var snapshot = NSDiffableDataSourceSnapshot<Section.ID, DestinationPost.ID>()
        snapshot.appendSections(Section.ID.allCases)
        for sectionType in Section.ID.allCases {
            let items = self.sectionsStore.fetchByID(sectionType).posts
            snapshot.appendItems(items, toSection: sectionType)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension PostGridViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            // Don't start a new prefetching operation if one is in process.
            guard prefetchingIndexPathOperations[indexPath] != nil else {
                continue
            }
            guard let destinationID = self.dataSource.itemIdentifier(for: indexPath) else {
                continue
            }
            let destination = self.postsStore.fetchByID(destinationID)

            prefetchingIndexPathOperations[indexPath] = assetsStore.loadAssetByID(destination.assetID) { [weak self] in
                // After the asset load completes, trigger a reconfigure for the item so the cell can be updated if
                // it is visible.
                self?.setPostNeedsUpdate(destinationID)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            prefetchingIndexPathOperations.removeValue(forKey: indexPath)?.cancel()
        }
    }
}

extension PostGridViewController {
    private func createSectionHeaderRegistration() -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: sectionHeaderElementKind
        ) { [weak self] supplementaryView, elementKind, indexPath in
            guard let self = self else { return }
            
            let sectionID = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            supplementaryView.configurationUpdateHandler = { supplementaryView, state in
                guard let supplementaryCell = supplementaryView as? UICollectionViewListCell else { return }
                
                var contentConfiguration = UIListContentConfiguration.plainHeader().updated(for: state)
                
                contentConfiguration.textProperties.font = Appearance.sectionHeaderFont
                contentConfiguration.textProperties.color = UIColor.label
                
                contentConfiguration.text = sectionID.rawValue

                supplementaryCell.contentConfiguration = contentConfiguration
                
                supplementaryCell.backgroundConfiguration = .clear()
            }
        }
    }
    
    /// - Tag: Grid
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int,
            layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                 heightDimension: .estimated(350))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // If there's space, adapt and go 2-up + peeking 3rd item.
            let columnCount = layoutEnvironment.container.effectiveContentSize.width > 500 ? 3 : 1
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(350))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columnCount)
            group.interItemSpacing = .fixed(20)
            
            let section = NSCollectionLayoutSection(group: group)
            let sectionID = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            
            section.interGroupSpacing = 20
            
            if sectionID == .featured {
                section.decorationItems = [
                    .background(elementKind: "SectionBackground")
                ]
                
                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(Appearance.sectionHeaderFont.lineHeight))
                let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: titleSize,
                    elementKind: self.sectionHeaderElementKind,
                    alignment: .top)
                
                section.boundarySupplementaryItems = [titleSupplementary]
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 20, trailing: 20)
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
            }
            return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        
        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config)
        
        layout.register(SectionBackgroundDecorationView.self, forDecorationViewOfKind: "SectionBackground")
        return layout
    }
}
