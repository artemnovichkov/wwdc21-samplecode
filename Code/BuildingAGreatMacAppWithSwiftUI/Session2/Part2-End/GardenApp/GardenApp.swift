/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main application code for this sample.
*/

import SwiftUI

@main
struct GardenApp: App {

    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .commands {
            SidebarCommands()
            PlantCommands()
            ImportExportCommands(store: store)
            ImportFromDevicesCommands()
        }
        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
