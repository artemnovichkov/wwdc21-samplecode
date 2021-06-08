/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller extension for the on-boarding experience.
*/

import UIKit
import ARKit

// The delegate for a view that presents visual instructions that guide the user during session
// initialization and recovery. For an example that explains more about coaching overlay, see:
// `Placing Objects and Handling 3D Interaction`
// <https://developer.apple.com/documentation/arkit/world_tracking/placing_objects_and_handling_3d_interaction>
//
extension ViewController: ARCoachingOverlayViewDelegate {
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        mapView.isUserInteractionEnabled = false
        undoButton.isEnabled = false
        geoCoachingController.setBlocked(true)
        configureUIForCoaching(true)
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        mapView.isUserInteractionEnabled = true
        undoButton.isEnabled = true
        geoCoachingController.setBlocked(false)
        configureUIForCoaching(false)
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        restartSession()
    }

    // Sets up the coaching view.
    func setupWorldTrackingCoachingOverlay() {
        coachingOverlayWorldTracking.delegate = self
        arView.addSubview(coachingOverlayWorldTracking)
        coachingOverlayWorldTracking.session = arView.session
        coachingOverlayWorldTracking.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            coachingOverlayWorldTracking.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            coachingOverlayWorldTracking.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            coachingOverlayWorldTracking.widthAnchor.constraint(equalTo: arView.widthAnchor),
            coachingOverlayWorldTracking.heightAnchor.constraint(equalTo: arView.heightAnchor)
            ])
    }
    
    func configureUIForCoaching(_ active: Bool) {
        undoButton.isHidden = active
        trackingStateLabel.isHidden = active
    }
}
