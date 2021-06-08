/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the top-level menu of videos.
*/

import UIKit
import TVUIKit

class MenuViewController: UIViewController {
	
	var videoPlaybackViewController: VideoPlaybackViewController
	@IBOutlet var firstPosterView: TVPosterView?
	@IBOutlet var secondPosterView: TVPosterView?
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		videoPlaybackViewController = VideoPlaybackViewController()
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder: NSCoder) {
		videoPlaybackViewController = VideoPlaybackViewController()
		super.init(coder: coder)
	}
	
    override func viewDidLoad() {
		view.backgroundColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
        super.viewDidLoad()
    }

	func presentVideo(_ url: URL, title: String, description: String, rating: String) {
		present(videoPlaybackViewController, animated: true) {
			self.videoPlaybackViewController.loadAndPlay(url: url, title: title, description: description, rating: rating)
		}
	}
	
	@IBAction func action(posterView: TVPosterView) {
		let title = posterView.title
		let url: URL
		let description: String
		let rating: String
		if posterView == firstPosterView {
			// This video is rated PG. Substitute your own content URLs to make this example more interesting.
			url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
			description = "The heartwarming story of Bib and Bop."
			rating = "PG"
		} else {
			// This video is rated PG-13.
			url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")!
			description = "The definitive version of this classic story, preserving the director's original vision."
			rating = "PG-13"
		}
		presentVideo(url, title: title ?? "", description: description, rating: rating)
	}
}
