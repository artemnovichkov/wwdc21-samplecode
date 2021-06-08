/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that configures a custom UI for ride requests.
*/

import IntentsUI

class IntentViewController: UIViewController, INUIHostedViewControlling {
            
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configure(with interaction: INInteraction, context: INUIHostedViewContext, completion: @escaping (CGSize) -> Void) {
        completion(desiredSize)
    }
    
    var desiredSize: CGSize {
        // Size of the custom UI built in storyboard
        return CGSize(width: 350.0, height: 150.0)
    }
}
