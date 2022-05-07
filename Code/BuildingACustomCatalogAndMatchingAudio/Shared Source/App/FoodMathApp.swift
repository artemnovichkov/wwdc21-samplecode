/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The SwiftUI scene builder that sets up the UI for the FoodMath app.
*/

import SwiftUI

@main
struct FoodMathApp: App {
    @StateObject private var matcher = Matcher()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(matcher)
        }
    }
}
