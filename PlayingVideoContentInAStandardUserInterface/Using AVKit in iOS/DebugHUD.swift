/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DebugHUD is a view capable of printing the status of a VideoPlaybackItem.
*/

import UIKit

class DebugHUD: UIView {
	
	var status: PlayerViewControllerCoordinator.Status = [] {
		didSet {
			guard status != oldValue || label.text == nil else { return }
			label.text = status.debugDescription
		}
	}
	
	private lazy var label: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.textColor = .systemBlue
		label.backgroundColor = UIColor(white: 0.9, alpha: 0.35)
		label.textAlignment = .center
		label.numberOfLines = 0
		addSubview(label)
		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor)
			])
		return label
	}()
}
