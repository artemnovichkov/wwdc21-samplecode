/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main entry point of the watchOS app
*/

import SwiftUI

@main
struct BARBluetoothApp: App {
    
    static let name: String = "BARBluetooth"
    
    /// This delegate manages the lifecycle of the watchOS app.
    @WKExtensionDelegateAdaptor var delegate: ExtensionDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                RootView().environmentObject(delegate.bluetoothReceiver)
            }
        }
    }
}
