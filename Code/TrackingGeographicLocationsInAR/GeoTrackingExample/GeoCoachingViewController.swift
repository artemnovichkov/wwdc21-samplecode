/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View and controller to provide user coaching for the GeoLocationSession localization
*/

import UIKit
import ARKit
import RealityKit

class GeoCoachingViewController {
    
    private let firstPromptDelay: Double = 1
    private let initializationDelay: Double = 4
    
    private let arCoachingFadeDuration: Double = 0.3
    private let arCoachingBackgroundOpacity: CGFloat = 0.6
    private let arCoachingTextLateralInset: CGFloat = 25

    private var coachingParentView = UIView()
    private var background = UIView()
    private var coachingText = UILabel()
    
    private var internallyActivated = false
    private var externallyBlocked = false
    
    private var worldTrackingInitialized: Bool = false
    private var permitTransitionToLocalizingState = false
    private var displayLookUpPrompt = false
    private var devicePointedLow = false
    private var displaySecondaryLocalizingPrompt = false
    private var secondaryPromptWorkItem = DispatchWorkItem {}
    
    private var canBeActivated: Bool {
        return internallyActivated && !externallyBlocked
    }
    
    private var geoTrackingStatus: ARGeoTrackingStatus!
    
    private var coachingState = CoachingState.uninitialized {
        didSet {
            self.setText(text: coachingState.userInstructions)
        }
    }
    
    enum CoachingState {
        case uninitialized
        case waitingForARTrackingStablility
        case initializing
        case scheduledForLocalizing
        case scheduledForLocalized
        case localizing
        case localizingWithSecondaryPrompt
        case localized
        case notAvailable
        
        var userInstructions: String? {
            switch self {
                case .uninitialized : return nil
                case .waitingForARTrackingStablility : return ""
                case .initializing : return "Move " + (UIDevice.current.userInterfaceIdiom == .phone ? "iPhone" : "iPad") + " to start"
                case .scheduledForLocalizing : return CoachingState.initializing.userInstructions
                case .scheduledForLocalized : return CoachingState.initializing.userInstructions
                case .localizing : return "Look at nearby buildings"
                case .localizingWithSecondaryPrompt : return "Look at nearby buildings and make sure nothing is in the way"
                case .localized : return nil
                case .notAvailable : return nil
            }
        }
    }
    
    init(for arView: ARView) {
        
        initializeParentView(for: arView)
        initializeBackgroundView()
        initializeLabelView()
    }
    
    public func update(for status: ARGeoTrackingStatus) {
        
        geoTrackingStatus = status
        
        devicePointedLow = (status.stateReason == .devicePointedTooLow)
        
        // The .notAvailableAtLocation condition can deactivate the coaching and should be processed first
        if status.stateReason == .notAvailableAtLocation {
            coachingState = .notAvailable
            setActive(false)
            return
        }
        
        // Allow an exit from any state any time after the intro timer
        if coachingState != .scheduledForLocalized && coachingState != .localized && status.state == .localized {
            if permitTransitionToLocalizingState {
                transitionToLocalizedState()
            } else {
                coachingState = .scheduledForLocalized
                
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3) {
                    self.transitionToLocalizedState()
                }
            }
            return
        }
        
        // Start the coaching and begin waiting for the ARTracking to stabilize
        if coachingState == .uninitialized {
            coachingState = .waitingForARTrackingStablility
        }
        
        // Manage transitions from the .initializing state
        if coachingState == .initializing {
            if status.state == .localizing {
                if permitTransitionToLocalizingState {
                    transitionToLocalizingState()
                } else {
                    coachingState = .scheduledForLocalizing
                    
                    // Schedule delayed transition to localizing state
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + initializationDelay) {
                        if self.coachingState != .localized {
                            self.transitionToLocalizingState()
                        }
                    }
                }
            }
        }
        
        // Manage the look up prompt
        if coachingState != .uninitialized && coachingState != .waitingForARTrackingStablility && coachingState != .localized {
            if !displayLookUpPrompt && status.stateReason == .devicePointedTooLow {
                setLookUpPromptActive(true)
            } else if displayLookUpPrompt && status.stateReason != .devicePointedTooLow {
                setLookUpPromptActive(false)
            }
        }
    }
    
    // Call this function to block the view. Useful to avoid conflict with other UI.
    public func setBlocked(_ blocked: Bool) {
        
        externallyBlocked = blocked
        coachingParentView.isHidden = !canBeActivated
    }
    
    public func worldTrackingStateIsNormal(_ isNormal: Bool) {
        
        if !worldTrackingInitialized && isNormal {
            worldTrackingInitialized = true
            
            // Enter the initializing state after the device orientation has been updated
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.25) { [self] in
                coachingState = .initializing
                // Update while in the new state to respond to any device orientation state changes
                update(for: geoTrackingStatus)
            }
            
            // Schedule a timer to prevent too rapid a transition into the localizing or localized state
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + initializationDelay) {
                self.permitTransitionToLocalizingState = true
            }
        }
    }
    
    private func setActive(_ active: Bool) {
        
        // Prevent repeat activation into the same state
        guard internallyActivated != active else { return }
        
        internallyActivated = active
        
        // The app only un-hides the view during activation. The app needs to delay hiding in the case of deactivation to accommodate fading.
        DispatchQueue.main.async() { [self] in
            if canBeActivated {
                coachingParentView.isHidden = false
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + arCoachingFadeDuration) {
                    coachingParentView.isHidden = true
                }
            }
            UIView.animate(withDuration: arCoachingFadeDuration, delay: 0, options: .beginFromCurrentState, animations: {
                coachingParentView.alpha = canBeActivated ? 1 : 0
            })
        }
    }
    
    private func setLookUpPromptActive(_ active: Bool) {
        
        displayLookUpPrompt = active
        if active {
            setText(text: "Look up")
        } else {
            setText(text: coachingState.userInstructions)
        }
    }

    private func transitionToLocalizingState() {
        
        // Prevent repeat activation into the same state
        guard coachingState != .localizing else { return }
        
        coachingState = .localizing

        // Schedule secondary prompt
        secondaryPromptWorkItem = DispatchWorkItem { [self] in
            if coachingState == .localizing {
                coachingState = .localizingWithSecondaryPrompt
                // May have to re-dispay look-up prompt after scheduled state chaange
                if displayLookUpPrompt {
                    setLookUpPromptActive(true)
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 15, execute: secondaryPromptWorkItem)
    }
    
    private func transitionToLocalizedState() {
        
        coachingState = .localized
        setActive(false)
        // Cancel the scheduled secondary prompt.
        secondaryPromptWorkItem.cancel()
    }
    
    // Display text in this coaching view.
    // Note: Perform UI modifications on main thread so that calls from background threads can successfully modify the text
    ///- Tag: SetText
    private func setText(text: String?) {
        
        if let unwrappedText = text {
            DispatchQueue.main.async() {
                self.setActive(true)
                self.coachingText.text = unwrappedText
            }
        }
    }
    
    private func initializeParentView(for parentView: ARView) {
        
        coachingParentView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(coachingParentView)
        coachingParentView.fillParentView()
        
        coachingParentView.alpha = 0
        coachingParentView.isHidden = true
    }
    
    private func initializeBackgroundView() {
        
        background.translatesAutoresizingMaskIntoConstraints = false
        coachingParentView.addSubview(background)
        background.fillParentView()
        background.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: arCoachingBackgroundOpacity)
    }
    
    private func initializeLabelView() {
        
        coachingText.translatesAutoresizingMaskIntoConstraints = false
        coachingParentView.addSubview(coachingText)
        coachingText.fillParentView(withInset: arCoachingTextLateralInset)
        
        coachingText.adjustsFontSizeToFitWidth = false
        coachingText.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        coachingText.text = ""
        coachingText.font = UIFont.preferredFont(forTextStyle: .headline)
        coachingText.textAlignment = .center
        coachingText.numberOfLines = 0
        coachingText.lineBreakMode = .byWordWrapping
    }
}
