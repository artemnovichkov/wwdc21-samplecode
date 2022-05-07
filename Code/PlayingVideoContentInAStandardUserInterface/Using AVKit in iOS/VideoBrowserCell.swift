/*
See LICENSE folder for this sample’s licensing information.

Abstract:
VideoBrowserCell can either display information about a video or contain an embedded AVPlayerViewController.
*/

import UIKit
import AVKit

protocol VideoBrowserCellDelegate: AnyObject {
	func videoBrowserCellTapped(_ cell: VideoBrowserCell)
}

class VideoBrowserCell: UICollectionViewCell {
	weak var delegate: VideoBrowserCellDelegate?
	
	var playerViewControllerCoordinator: PlayerViewControllerCoordinator? {
		didSet {
			guard playerViewControllerCoordinator != oldValue else { return }
			if oldValue?.playerViewControllerIfLoaded?.viewIfLoaded?.isDescendant(of: videoContainerView) == true {
				oldValue?.removeFromParentIfNeeded()
			}
		}
	}
	
	@IBOutlet var containerView: UIView!
	@IBOutlet var videoContainerView: UIView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var thumbnailView: UIImageView!
	@IBOutlet var showVideoButton: UIButton!
    
	var debugHud: DebugHUD? {
		didSet {
			guard oldValue != debugHud else { return }
			oldValue?.removeFromSuperview()
			if let debugHud = debugHud {
				videoContainerView.insertSubview(debugHud, at: 0)
				debugHud.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					debugHud.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
					debugHud.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
					debugHud.widthAnchor.constraint(equalTo: videoContainerView.widthAnchor),
					debugHud.heightAnchor.constraint(equalTo: videoContainerView.heightAnchor)
                ])
			}
		}
	}
	
	@IBAction func handleButtonTap(_ sender: UIButton) {
		delegate?.videoBrowserCellTapped(self)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		contentView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
		contentView.layer.cornerCurve = .continuous
		contentView.layer.cornerRadius = 12.0
		containerView.clipsToBounds = true
		containerView.layer.cornerCurve = .continuous
		containerView.layer.cornerRadius = 8.0
	}
	
	deinit {
		playerViewControllerCoordinator = nil
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		playerViewControllerCoordinator = nil
		debugHud = nil
	}
}
