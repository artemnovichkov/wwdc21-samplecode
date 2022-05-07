/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing a 2x2 grid using a selection gesture recognizer.
*/

import UIKit

struct SelectionSample: MenuDescribable {

    static var title = "Selection"
    static var iconName = "hand.tap"

    static var description = """
    Shows a 2x2 grid of focusable items that have a selection gesture recognizer \
    attached to them. When the user selects them by hitting return (iPad OS) or \
    space (Mac Catalyst), they flash briefly in the tint color.
    """

    static func create() -> UIViewController { GridViewController<SelectionFocusView>() }
}

class SelectionFocusView: FocusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add a gesture recognizer that triggers when the user triggers focus selection (return).
        let selectGesture = UITapGestureRecognizer(target: self, action: #selector(select(_:)))
        selectGesture.allowedTouchTypes = []
        selectGesture.allowedPressTypes = [ UIPress.PressType.select.rawValue as NSNumber ]
        self.addGestureRecognizer(selectGesture)

        // Add a gesture recognizer that triggers when the user touches.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(select(_:)))
        // Nothing to configure here, a single touch is the default.
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override func select(_ sender: Any?) {
        self.backgroundColor = .tintColor
        UIView.animate(withDuration: 1.0, delay: 0.5, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.backgroundColor = .secondarySystemFill
        })
    }
}
