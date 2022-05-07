/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the interactive video overlay.
*/

import UIKit

class CustomInteractiveVideoOverlay: UIViewController {

	@IBOutlet var stackView: UIStackView?

	override var preferredFocusEnvironments: [UIFocusEnvironment] {
		return stackView?.arrangedSubviews ?? []
	}
}
