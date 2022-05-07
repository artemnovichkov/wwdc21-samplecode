/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Controls for functionality that might be hidden temporarily.
*/

import SwiftUI

/// DevelopmentSettingsView is a view that offers controls for hidden settings.
/// This is meant as a developer only tool, to temporarily hide certain key features of the app.
struct DevelopmentSettingsView: View {
    
    // MARK: - Properties
    
    /// `true` if barcode scanning should be shown in the UI, persisted in `UserDefaults`.
    @AppStorage("barcode-scanning-available") var isBarcodeScanningAvailable = true
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            settingsList
                .navigationBarTitle("Development Settings", displayMode: .inline)
        }
    }
    
    private var settingsList: some View {
        List {
            Section(header: Text("Features")) {
                Toggle("Barcode Scanning", isOn: $isBarcodeScanningAvailable)
            }
            Section(header: Text("Reset")) {
                Button("Reset Recent Albums") {
                    RecentAlbumsStorage.shared.reset()
                }
            }
        }
    }
}

// MARK: - Previews

struct DevelopmentSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DevelopmentSettingsView()
    }
}
