/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Attaching a context menu interaction to this image allows a secondary-click on Mac Catalyst to display a menu for sharing specifically
            the image.
*/

import UIKit

/// An image view that can share its contents
class SharingImageView: UIImageView, UIContextMenuInteractionDelegate {
    override var activityItemsConfiguration: UIActivityItemsConfigurationReading? {
        get {
            if let image = image {
                return UIActivityItemsConfiguration(objects: [image])
            } else {
                // Return a non-nil value with no sharable objects, so that the framework will not
                // use a parent responder's activity items configuration.
                return UIActivityItemsConfiguration(objects: [])
            }
        }

        set {
            super.activityItemsConfiguration = newValue
            Swift.debugPrint("Cannot set activity items configuration")
        }
    }

    lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)

    override func willMove(toWindow newWindow: UIWindow?) {
        removeInteraction(contextMenuInteraction)
        super.willMove(toWindow: newWindow)
    }

    override func didMoveToWindow() {
        addInteraction(contextMenuInteraction)
        isUserInteractionEnabled = true
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
            defaultMenuItems in
            return UIMenu(title: "Share to:", image: nil, identifier: nil, options: [], children: defaultMenuItems)
        })
    }
}
