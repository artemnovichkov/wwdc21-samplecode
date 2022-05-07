/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model that describes an individual SF symbol.
*/

import UIKit

struct SampleData: Hashable {
    let name: String
    let icon: UIImage
}

extension SampleData {
    static func createSampleData() -> [SampleData] {
        return createSymbolLibrary()
    }

    static func createSampleDataSource<CellType: UICollectionViewCell>(
        collectionView: UICollectionView,
        cellRegistration: UICollectionView.CellRegistration<CellType, SampleData>) -> UICollectionViewDiffableDataSource<Int, SampleData> {
        
        let dataSource =
            UICollectionViewDiffableDataSource<Int, SampleData>(collectionView: collectionView, cellProvider: { collectionView, indexPath, data in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: data)
        })

        var snapshot = NSDiffableDataSourceSnapshot<Int, SampleData>()
        snapshot.appendSections([0])
        snapshot.appendItems(createSampleData())
        dataSource.apply(snapshot, animatingDifferences: false)

        return dataSource
    }
}

