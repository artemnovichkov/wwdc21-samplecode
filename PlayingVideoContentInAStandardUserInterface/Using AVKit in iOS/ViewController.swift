/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ViewController is the initial table view controller shown in the app.
 It also creates the VideoPlaybackController object which tracks global playback state, and serves as the delegate for VideoPlaybackItems.
*/

import UIKit

class ViewController: UITableViewController {
	
	let playbackController = PlaybackController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		playbackController.prepareForPlayback()
		playbackController.videoItemDelegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		transitionCoordinator?.animate(alongsideTransition: nil) { context in
			if !context.isCancelled {
				self.playbackController.removeAllEmbeddedViewControllers()
			}
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Samples"
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "SampleCatalogCell", for: indexPath)
		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "Presenting Full Screen"
		case 1:
			cell.textLabel?.text = "Embedding Inline"
		default:
			fatalError()
		}
		return cell
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowSampleSegue",
			let sender = sender as? UITableViewCell,
			let indexPath = tableView.indexPath(for: sender),
			let contentBrowserViewController = segue.destination as? VideoBrowserViewController {
			contentBrowserViewController.playbackController = playbackController
			contentBrowserViewController.title = sender.textLabel?.text
			contentBrowserViewController.wantsFullScreen = indexPath.row == 0
		}
	}
}

extension ViewController: PlayerViewControllerCoordinatorDelegate {
	
	func playerViewControllerCoordinator(
		_ coordinator: PlayerViewControllerCoordinator,
		restoreUIForPIPStop completion: @escaping (Bool) -> Void) {
		if coordinator.playerViewControllerIfLoaded?.parent == nil {
			playbackController.dismissActivePlayerViewController(animated: false) {
				if let navigationController = self.navigationController {
					coordinator.restoreFullScreen(from: navigationController) {
						completion(true)
					}
				} else {
					completion(false)
				}
			}
		} else {
			completion(true)
		}
	}
	
    func playerViewControllerCoordinatorWillDismiss(_ coordinator: PlayerViewControllerCoordinator) {
        if let indexPath = playbackController.indexPath(for: coordinator),
            let contentBrowser = navigationController?.topViewController as? VideoBrowserViewController,
            !contentBrowser.collectionView.fullyShowsItem(at: indexPath) {
            contentBrowser.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }
}

private extension UICollectionView {
	
	func fullyShowsItem(at indexPath: IndexPath) -> Bool {
		if let attributes = layoutAttributesForItem(at: indexPath) {
			return bounds.inset(by: safeAreaInsets).contains(attributes.frame)
		}
        return false
	}
}
