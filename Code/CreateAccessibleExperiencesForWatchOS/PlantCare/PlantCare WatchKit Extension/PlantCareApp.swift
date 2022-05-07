/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app.
*/

import SwiftUI

@main
struct PlantCareApp: App {
    @StateObject var plantData = PlantData.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                PlantContentView()
                    .environmentObject(plantData)
            }
        }
    }
}
