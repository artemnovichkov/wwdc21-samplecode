/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main entry point for the watchOS and iOS apps.
*/

import SwiftUI
import NearbyInteraction

#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

@main
struct WatchNIDemoApp: App {
    
    private var niManager: NearbyInteractionManager?
    
    init() {
        /// NearbyInteraction is only supported on devices with a U1 chip.
        if NISession.isSupported {
            niManager = NearbyInteractionManager()
        }
    }
    
    @State var distance: Measurement<UnitLength>? {
        willSet {
            if let oldDistance = distance?.value, let newDistance = newValue?.value {
                /// When the distance value changes, play a haptic feedback.
                if oldDistance.rounded(.up) != newDistance.rounded(.up) {
                    playHaptic()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let niManager = niManager {
                    ContentView(niManager: niManager)
                        .onReceive(niManager.$distance) {
                            self.distance = $0?.converted(to: Helper.localUnits)
                        }
                } else {
                    Text("NearbyInteraction is not supported on this device")
                }
            }
            .multilineTextAlignment(.center)
            
            /// Disable the screen timeout on iOS devices.
            #if os(iOS)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            #endif
        }
    }
    
    func playHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #else
        let generator = UIImpactFeedbackGenerator()
        generator.impactOccurred()
        #endif
    }
}
