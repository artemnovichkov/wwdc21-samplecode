/*
See LICENSE folder for this sample’s licensing information.

Abstract:
VideoBrowserViewController displays a list of videos, optionally embedding them in collection view cells.
*/

import UIKit
import AVKit

class VideoBrowserViewController: UICollectionViewController {
	
	var wantsFullScreen = false
	
	var playbackController: PlaybackController!
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return playbackController.videos.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentBrowserCellReuseIdentifier", for: indexPath) as? VideoBrowserCell
			else { fatalError("Could not dequeue a cell for ContentBrowserCellReuseIdentifier") }
		cell.titleLabel.text = playbackController.videos[indexPath.item].title
		cell.playerViewControllerCoordinator = playbackController.coordinator(for: indexPath)
		cell.showVideoButton.isHidden = !wantsFullScreen
		cell.delegate = self
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? VideoBrowserCell {
			if wantsFullScreen {
				playbackController.embed(debugHudForIndexPath: indexPath, in: cell)
			} else {
				playbackController.embed(contentForIndexPath: indexPath, in: self, containerView: cell.videoContainerView)
			}
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? VideoBrowserCell {
			cell.playerViewControllerCoordinator = nil
		}
	}
}

extension VideoBrowserViewController: VideoBrowserCellDelegate {
	
	func videoBrowserCellTapped(_ cell: VideoBrowserCell) {
		if let indexPath = collectionView.indexPath(for: cell) {
			playbackController.present(contentForIndexPath: indexPath, from: self)
		}
	}
}
