/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A helper class for injecting presentation settings.
*/

import UIKit

class PresentationHelper {
    
    static let sharedInstance = PresentationHelper()
    var smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier = .medium
    var prefersScrollingExpandsWhenScrolledToEdge: Bool = false
    var prefersEdgeAttachedInCompactHeight: Bool = true
    var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = true
}
