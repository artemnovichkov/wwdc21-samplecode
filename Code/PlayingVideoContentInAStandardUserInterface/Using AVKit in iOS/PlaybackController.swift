/*
See LICENSE folder for this sample’s licensing information.

Abstract:
PlaybackController creates PlayerViewControllerCoordinators and serves as the glue between the coordinators and the application's UI.
*/

import UIKit
import AVFoundation

class PlaybackController {
	
	weak var videoItemDelegate: PlayerViewControllerCoordinatorDelegate?
	var videos = Video.makeVideos()
	private var playbackItems = [Video: PlayerViewControllerCoordinator]()
	
	func prepareForPlayback() {
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback)
		} catch {
			print(error)
		}
	}
	
	private func coordinatorOrNil(for indexPath: IndexPath) -> PlayerViewControllerCoordinator? {
		let video = videos[indexPath.row]
		return playbackItems[video]
	}
	
	func coordinator(for indexPath: IndexPath) -> PlayerViewControllerCoordinator {
		let video = videos[indexPath.row]
		if let playbackItem = playbackItems[video] {
			return playbackItem
		} else {
			let playbackItem = PlayerViewControllerCoordinator(video: video)
			playbackItem.delegate = videoItemDelegate
			playbackItems[video] = playbackItem
			return playbackItem
		}
	}
	
	func indexPath(for coordinator: PlayerViewControllerCoordinator) -> IndexPath? {
		if let index = videos.firstIndex(of: coordinator.video) {
			return IndexPath(item: index, section: 0)
		}
        return nil
	}
	
	func embed(contentForIndexPath indexPath: IndexPath, in parentViewController: UIViewController, containerView: UIView) {
		coordinator(for: indexPath).embedInline(in: parentViewController, container: containerView)
	}
	
	func embed(debugHudForIndexPath indexPath: IndexPath, in cell: VideoBrowserCell) {
		cell.debugHud = coordinator(for: indexPath).externalDebugHud
		cell.debugHud?.status = coordinator(for: indexPath).status
	}
	
	func remove(contentForIndexPath indexPath: IndexPath) {
		coordinatorOrNil(for: indexPath)?.removeFromParentIfNeeded()
	}
	
	func present(contentForIndexPath indexPath: IndexPath, from presentingViewController: UIViewController) {
		coordinator(for: indexPath).presentFullScreen(from: presentingViewController)
	}
	
	func removeAllEmbeddedViewControllers() {
		playbackItems.forEach {
			$0.value.removeFromParentIfNeeded()
		}
	}
	
	func dismissActivePlayerViewController(animated: Bool, completion: @escaping () -> Void) {
		let fullScreenItems = playbackItems
			.filter { $0.value.status.contains(.fullScreenActive) }
			.map { $0.value }
		assert(fullScreenItems.count <= 1, "Never should be more than one thing full screen!")
		if let fullScreenItem = fullScreenItems.first {
			fullScreenItem.dismiss(completion: completion)
		} else {
			completion()
		}
	}
}
