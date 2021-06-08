/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the watchOS app.
*/

import SwiftUI

/// This view displays an interface for discovering and connecting to bluetooth peripherals.
struct RootView: View {
    
    @EnvironmentObject var receiver: BluetoothReceiver
    
    /// A button to start and stop the scanning process.
    private var scanButton: some View {
        Button("\(receiver.isScanning ? "Scanning..." : "Scan")") {
            toggleScanning()
        }
    }
    
    /// A view to list of the peripherals that were discovered during the scan.
    var discoveredPeripherals: some View {
        ForEach(Array(receiver.discoveredPeripherals), id: \.identifier) { peripheral in
            Text(peripheral.name ?? "unnamed peripheral")
                .onTapGesture { receiver.connect(to: peripheral) }
        }
    }
    
    /// A view to display the bluetooth peripheral that this device is currently connected to.
    @ViewBuilder
    var connectedPeripheral: some View {
        if let peripheral = receiver.connectedPeripheral {
            Text(peripheral.name ?? "unnamed peripheral")
                .onTapGesture { receiver.disconnect(from: peripheral) }
        }
    }
    
    var body: some View {
        List {
            scanButton.foregroundColor(Color.blue)
            Section(header: Text("Connected")) {
                connectedPeripheral
            }
            Section(header: Text("Discovered")) {
                discoveredPeripherals
            }
        }
    }
    
    private func toggleScanning() {
        if receiver.isScanning {
            receiver.stopScanning()
        } else {
            receiver.startScanning()
        }
    }
}
