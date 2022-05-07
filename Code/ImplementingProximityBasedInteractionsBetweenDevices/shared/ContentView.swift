/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view that displays the distance to the paired device.
*/

import SwiftUI

/// The main view that displays connection instructions and the distance to the
/// paired device.
struct ContentView: View {
    
    @ObservedObject var niManager: NearbyInteractionManager
    
    #if os(watchOS)
    let connectionDirections = "Open the app on your phone to connect"
    #else
    let connectionDirections = "Open the app on your watch to connect"
    #endif
    
    var body: some View {
        VStack(spacing: 10) {
            if niManager.isConnected {
                if let distance = niManager.distance?.converted(to: Helper.localUnits) {
                    Text(Helper.localFormatter.string(from: distance)).font(.title)
                } else {
                    Text("-")
                }
            } else {
                Text(connectionDirections)
            }
        }
    }
}
