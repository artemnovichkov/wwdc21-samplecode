/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for managing video playback.
*/

import UIKit
import AVKit
import os

// Change the value of checkParentalControlsExplicitly to compare automatic support for parental controls,
// vs. explicitly calling requestPlaybackRestrictionsAuthorization.
let checkParentalControlsExplicitly = true

class VideoPlaybackViewController: UIViewController, AVPlayerViewControllerDelegate {
	// The playerViewController is the one currently in use for full-screen playback.
	@objc dynamic var playerViewController: AVPlayerViewController?

	let customInteractiveVideoOverlay = CustomInteractiveVideoOverlay(nibName: "CustomInteractiveVideoOverlay", bundle: nil)
	
	var player: AVQueuePlayer?
	@objc dynamic var pendingPlayerItem: AVPlayerItem?
	var playerItemStatusObservation: NSKeyValueObservation?
	var currentItemErrorObservation: NSKeyValueObservation?
	
	var isPlaybackActive = false
	
	func commonInit() {
		
		playerItemStatusObservation = observe(\.pendingPlayerItem?.status) { (object, change) in
			DispatchQueue.main.async { // Avoid modifying an observed property from directly within an observer.
				let pendingItemStatus = object.pendingPlayerItem?.status
				if pendingItemStatus == AVPlayerItem.Status.readyToPlay {
					if checkParentalControlsExplicitly {
						// Explicitly check whether it is okay to play this item.
						object.pendingPlayerItem?.requestPlaybackRestrictionsAuthorization { (success, error) in
							if success {
								object.pendingPlayerItem = nil
								object.playerViewController?.player = object.player
								object.player?.rate = 1.0
							} else {
								// If the request failed, immediately dismiss our view controller.
								_ = object._dismiss()
							}
						}
					} else {
						// Start playback immediately (AVPlayerViewController will request authorization automatically when we provide the player item).
						object.pendingPlayerItem = nil
						object.playerViewController?.player = object.player
						object.player?.rate = 1.0
					}
				}
			}
		}
		
		currentItemErrorObservation = observe(\.playerViewController?.player?.currentItem?.error) { (object, change) in
			DispatchQueue.main.async {
				if object.playerViewController?.player?.currentItem?.error != nil {
					// A very simple error handler: Just dismiss the playback UI.
					// This is probably sufficient for unanticipated failures, or any where the error message is unlikely to help the user solve the problem.
					_ = object._dismiss()
				}
			}
		}
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		view.backgroundColor = .black
		if let playerViewController = playerViewController {
			view.addSubview(playerViewController.view)
			playerViewController.view.frame = view.bounds
		}
	}

	private func metadataItem(_ identifier: AVMetadataIdentifier, stringValue value: String) -> AVMutableMetadataItem {
		let metadataItem = AVMutableMetadataItem()
		metadataItem.value = value as NSString
		metadataItem.extendedLanguageTag = "und"
		metadataItem.identifier = identifier
		return metadataItem
	}
	
	private func metadataItemForMediaContentRating(_ rating: String) -> AVMetadataItem {
		return metadataItem(.iTunesMetadataContentRating, stringValue: rating)
	}
	
	private func loadNewPlayerViewController() {
		let newPlayerViewController = AVPlayerViewController()
		newPlayerViewController.delegate = self
		newPlayerViewController.customOverlayViewController = customInteractiveVideoOverlay
		if let oldPlayerViewController = self.playerViewController {
			oldPlayerViewController.removeFromParent()
			oldPlayerViewController.viewIfLoaded?.removeFromSuperview()
		}
		self.playerViewController = newPlayerViewController
		player = AVQueuePlayer()
		addChild(newPlayerViewController)
		if isViewLoaded {
			view.addSubview(newPlayerViewController.view)
		}
	}
	
	func loadAndPlay(url: URL, title: String, description: String, rating: String) {
		loadNewPlayerViewController()
		let playerItem = AVPlayerItem(url: url)
		playerItem.externalMetadata = [
			metadataItemForMediaContentRating(rating),
			metadataItem(AVMetadataIdentifier.commonIdentifierTitle, stringValue: title),
			metadataItem(.commonIdentifierDescription, stringValue: description)
		]
		self.pendingPlayerItem = playerItem
		player?.replaceCurrentItem(with: playerItem)
		if playerViewController != nil && !isPlaybackActive {
			isPlaybackActive = true
		}
	}

	override func viewWillLayoutSubviews() {
		if let playerViewController = playerViewController {
			playerViewController.view.frame = view.bounds
		}
		super.viewWillLayoutSubviews()
	}
	
	private func _dismiss(stopping: Bool = true) -> Bool {
		if let playerViewController = self.playerViewController {
			isPlaybackActive = false
			if let presenting = presentingViewController {
				presenting.dismiss(animated: true, completion: {
					// done
					if stopping {
						playerViewController.player?.rate = 0.0 // stop playback immediately (don't wait for dealloc)
					}
					playerViewController.removeFromParent()
					playerViewController.view.removeFromSuperview()
					self.playerViewController = nil
				})
				return true
			}
		}
		if let presenting = presentingViewController {
			if presenting.presentedViewController == self {
				presenting.dismiss(animated: true, completion: {
					
				})
			}
		}
		return false
	}
	
	// MARK: - AVPlayerViewControllerDelegate
	
	func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
		return _dismiss()
	}
	
	func playerViewControllerDidEndDismissalTransition(_ playerViewController: AVPlayerViewController) {
	}

	func playerViewController(_ playerViewController: AVPlayerViewController, skipToNextChannel completion: @escaping (Bool) -> Void) {
		// Load content for the new channel, update the playerViewController, and call the completion block to indicate success or failure.
		if let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8") {
			let playerItem = AVPlayerItem(url: url)
			playerViewController.player?.replaceCurrentItem(with: playerItem)
			completion(true)
		}
		completion(false)
	}
	
	func playerViewController(_ playerViewController: AVPlayerViewController, skipToPreviousChannel completion: @escaping (Bool) -> Void) {
		// Load content for the new channel, update the playerViewController, and call the completion block to indicate success or failure.
		if let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8") {
			let playerItem = AVPlayerItem(url: url)
			playerViewController.player?.replaceCurrentItem(with: playerItem)
			completion(true)
		}
		completion(false)
	}
}

