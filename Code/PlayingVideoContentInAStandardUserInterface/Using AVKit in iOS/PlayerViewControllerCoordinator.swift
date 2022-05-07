/*
See LICENSE folder for this sample’s licensing information.

Abstract:
PlayerViewControllerCoordinator wraps an AVPlayerViewController and an AVPlayer,
showing one approach to tracking and managing a playback state across multiple view hierarchies and application contexts.
*/

import AVKit

class PlayerViewControllerCoordinator: NSObject {
	
	// MARK: - Initialization
	
	init(video: Video) {
		self.video = video
		super.init()
	}
	
	deinit {
		debugHud.removeFromSuperview()
		externalDebugHud.removeFromSuperview()
	}
	
	// MARK: - Properties

	weak var delegate: PlayerViewControllerCoordinatorDelegate?
	var video: Video
	private(set) var status: Status = [] {
		didSet {
			debugHud.status = status
			externalDebugHud.status = status
			if oldValue.isBeingShown && !status.isBeingShown {
				playerViewControllerIfLoaded = nil
			}
			addDebugHUDToPlayerViewControllerIfNeeded()
		}
	}
	
	private(set) lazy var externalDebugHud = DebugHUD()
	
	private(set) var playerViewControllerIfLoaded: AVPlayerViewController? {
		didSet {
			guard playerViewControllerIfLoaded != oldValue else { return }
			
			// 1) Invalidate KVO, delegate, player, status for old player view controller
			
			readyForDisplayObservation?.invalidate()
			readyForDisplayObservation = nil
			
			if oldValue?.delegate === self {
				oldValue?.delegate = nil
			}
			
			if oldValue?.hasContent(fromVideo: video) == true {
				oldValue?.player = nil
			}
			
			status = []
			
			// 2) Set up the new playerViewController
			
			if let playerViewController = playerViewControllerIfLoaded {
				
				// 2a) Assign self as delegate
				playerViewController.delegate = self
				
				// 2b) Create player for video
				if !playerViewController.hasContent(fromVideo: video) {
					let playerItem = AVPlayerItem(url: video.hlsUrl)
					// Note that we seek to the resume time *before* giving the player view controller the player.
					// This is more efficient and provides better UI since media is only loaded at the actual start time.
					playerItem.seek(to: CMTime(seconds: video.resumeTime, preferredTimescale: 90_000), completionHandler: nil)
					playerViewController.player = AVPlayer(playerItem: playerItem)
				}
				
				// 2c) Update ready for display status and start observing the property
				if playerViewController.isReadyForDisplay {
					status.insert(.readyForDisplay)
				}
				
				readyForDisplayObservation = playerViewController.observe(\.isReadyForDisplay) { [weak self] observed, _ in
					if observed.isReadyForDisplay {
						self?.status.insert(.readyForDisplay)
					} else {
						self?.status.remove(.readyForDisplay)
					}
				}
				
				// 2d) Update the debug hud's with the current status
				debugHud.status = status
				externalDebugHud.status = status
			}
		}
	}
	
	// MARK: - Private vars
	
	private weak var fullScreenViewController: UIViewController?
	private var readyForDisplayObservation: NSKeyValueObservation?
	private lazy var debugHud = DebugHUD()
}

// Utility functions for common UIKit tasks that the coordinator needs to help orchestrate.

extension PlayerViewControllerCoordinator {
	
	// Present full-screen, and then start playback. Notice that there's no reason to change the modal presentation style
	// or set the transitioning delegate -- AVPlayerViewController handles that automatically
	func presentFullScreen(from presentingViewController: UIViewController) {
		guard !status.contains(.fullScreenActive) else { return }
		removeFromParentIfNeeded()
		loadPlayerViewControllerIfNeeded()
		guard let playerViewController = playerViewControllerIfLoaded else { return }
		presentingViewController.present(playerViewController, animated: true) {
			playerViewController.player?.play()
		}
	}
	
	// Use standard UIKit view controller containment API and track status for embedding inline
	func embedInline(in parent: UIViewController, container: UIView) {
		loadPlayerViewControllerIfNeeded()
		guard let playerViewController = playerViewControllerIfLoaded, playerViewController.parent != parent else { return }
		removeFromParentIfNeeded()
		status.insert(.embeddedInline)
		parent.addChild(playerViewController)
		container.addSubview(playerViewController.view)
		playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			playerViewController.view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
			playerViewController.view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
			playerViewController.view.widthAnchor.constraint(equalTo: container.widthAnchor),
			playerViewController.view.heightAnchor.constraint(equalTo: container.heightAnchor)
        ])
		playerViewController.didMove(toParent: parent)
	}
	
	// This handles showing AVPlayerViewController fullscreen after Picture in Picture ends.
	func restoreFullScreen(from presentingViewController: UIViewController, completion: @escaping () -> Void) {
		guard let playerViewController = playerViewControllerIfLoaded,
			status.contains(.pictureInPictureActive),
			!status.contains(.fullScreenActive)
			else {
				completion()
				return
		}
		playerViewController.view.translatesAutoresizingMaskIntoConstraints = true
		playerViewController.view.autoresizingMask = [.flexibleWidth, .flexibleWidth]
		presentingViewController.present(playerViewController, animated: true, completion: completion)
	}
	
	// Before restoring from Picture in Picture, this dismisses any active player view controllers.
	// See the AVPlayerViewController delegate methods for obtaining the fullScreenViewController.
	func dismiss(completion: @escaping () -> Void) {
		fullScreenViewController?.dismiss(animated: true) {
			completion()
			self.status.remove(.fullScreenActive)
		}
	}
	
	// Removes the playerViewController from its parent, and updates status accordingly.
	func removeFromParentIfNeeded() {
		if status.contains(.embeddedInline) {
			playerViewControllerIfLoaded?.willMove(toParent: nil)
			playerViewControllerIfLoaded?.view.removeFromSuperview()
			playerViewControllerIfLoaded?.removeFromParent()
			status.remove(.embeddedInline)
		}
	}
}

extension PlayerViewControllerCoordinator: AVPlayerViewControllerDelegate {
	
	// 1a) Simply tracking state
	func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
		status.insert(.pictureInPictureActive)
	}
	
	// 1b) More state tracking
	func playerViewController(_ playerViewController: AVPlayerViewController, failedToStartPictureInPictureWithError error: Error) {
		status.remove(.pictureInPictureActive)
	}
	
	// 1c) And more state tracking
	func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
		status.remove(.pictureInPictureActive)
	}
	
	// 2a) Track the presentation of AVPlayerViewController's content. Note that this may happen when we are still embedded inline.
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
        status.insert([.fullScreenActive, .beingPresented])
        
        coordinator.animate(alongsideTransition: nil) { context in
            self.status.remove(.beingPresented)
            // You must check context.isCancelled to determine whether or not the transition was successful.
            if context.isCancelled {
                self.status.remove(.fullScreenActive)
            } else {
                // Keep note of the view controller that was used to present full screen.
                self.fullScreenViewController = context.viewController(forKey: .to)
            }
        }
	}
	
	// 2b) Track the dismissal of AVPlayerViewControllers's content from full screen. This is
	// The mirror image of func playerViewController(_:willBeginFullScreenPresentationWithAnimationCoordinator:)
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator
        ) {
        status.insert([.beingDismissed])
        delegate?.playerViewControllerCoordinatorWillDismiss(self)
        
        coordinator.animate(alongsideTransition: nil) { context in
            self.status.remove(.beingDismissed)
            if !context.isCancelled {
                self.status.remove(.fullScreenActive)
            }
        }
    }
	
	// 3) The most important delegate method for Picture in Picture -- restoring the user interface.
	// This implementation sends the callback up to its own delegate (ViewController) because the coordinator
	// doesn't have enough global context to handle the restore.
	func playerViewController(
		_ playerViewController: AVPlayerViewController,
		restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
		) {
		if let delegate = delegate {
			delegate.playerViewControllerCoordinator(self, restoreUIForPIPStop: completionHandler)
		} else {
			completionHandler(false)
		}
	}
	
}

extension PlayerViewControllerCoordinator {
	
	private func loadPlayerViewControllerIfNeeded() {
		if playerViewControllerIfLoaded == nil {
			playerViewControllerIfLoaded = AVPlayerViewController()
		}
	}
	
	private func addDebugHUDToPlayerViewControllerIfNeeded() {
		if status.contains(.embeddedInline) || status.contains(.fullScreenActive) {
			if let playerViewController = playerViewControllerIfLoaded,
				let contentOverlayView = playerViewController.contentOverlayView,
				!debugHud.isDescendant(of: contentOverlayView) {
				playerViewController.contentOverlayView?.addSubview(debugHud)
				debugHud.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					debugHud.centerXAnchor.constraint(equalTo: contentOverlayView.centerXAnchor),
					debugHud.centerYAnchor.constraint(equalTo: contentOverlayView.centerYAnchor),
					debugHud.widthAnchor.constraint(equalTo: contentOverlayView.widthAnchor),
					debugHud.heightAnchor.constraint(equalTo: contentOverlayView.heightAnchor)
                ])
			}
		}
	}
}

extension PlayerViewControllerCoordinator {
	
	// OptionSet describing the various states we are tracking in the debug hud.
	struct Status: OptionSet, CustomDebugStringConvertible {
		
		let rawValue: Int
		
		static let embeddedInline = Status(rawValue: 1 << 0)
		static let fullScreenActive = Status(rawValue: 1 << 1)
		static let beingPresented = Status(rawValue: 1 << 2)
		static let beingDismissed = Status(rawValue: 1 << 3)
		static let pictureInPictureActive	= Status(rawValue: 1 << 4)
		static let readyForDisplay = Status(rawValue: 1 << 5)
		
		static let descriptions: [(Status, String)] = [
			(.embeddedInline, "Embedded Inline"),
			(.fullScreenActive, "Full Screen Active"),
			(.beingPresented, "Being Presented"),
			(.beingDismissed, "Being Dismissed"),
			(.pictureInPictureActive, "Picture In Picture Active"),
			(.readyForDisplay, "Ready For Display")
		]
		
		var isBeingShown: Bool {
			return !intersection([.embeddedInline, .pictureInPictureActive, .fullScreenActive]).isEmpty
		}
		
		var debugDescription: String {
			var debugDescriptions = Status.descriptions
				.filter { contains($0.0) }
				.map { $0.1 }
			if isEmpty {
				debugDescriptions.append("Idle (Tap to full screen)")
			} else if !contains(.readyForDisplay) {
				debugDescriptions.append("NOT Ready For Display")
			}
			return debugDescriptions.joined(separator: "\n")
		}
	}
}

protocol PlayerViewControllerCoordinatorDelegate: AnyObject {
	func playerViewControllerCoordinator(
		_ coordinator: PlayerViewControllerCoordinator,
		restoreUIForPIPStop completion: @escaping (Bool) -> Void
	)
	
	func playerViewControllerCoordinatorWillDismiss(_ coordinator: PlayerViewControllerCoordinator)
}

private extension AVPlayerViewController {
	
	func hasContent(fromVideo video: Video) -> Bool {
		let url = (player?.currentItem?.asset as? AVURLAsset)?.url
		return url == video.hlsUrl
	}
}
