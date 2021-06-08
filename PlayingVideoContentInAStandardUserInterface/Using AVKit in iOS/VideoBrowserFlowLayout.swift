/*
See LICENSE folder for this sample’s licensing information.

Abstract:
VideoBrowserFlowLayout is a UICollectionViewFlowLayout subclass that defines the ContentBrowserViewController's layout.
*/

import UIKit

class VideoBrowserFlowLayout: UICollectionViewFlowLayout {
	static let padding: CGFloat = 16
	override func prepare() {
		if let collectionView = collectionView {
			let minInset = VideoBrowserFlowLayout.padding
			minimumInteritemSpacing = minInset
			minimumLineSpacing = minInset
			sectionInset = UIEdgeInsets(top: minInset, left: minInset, bottom: minInset, right: minInset)
			let width = collectionView.safeAreaLayoutGuide.layoutFrame.width - (minInset * 2)
			let maxHeight = min(304, width)
			itemSize = CGSize(width: width, height: maxHeight)
		}
		super.prepare()
	}
}
