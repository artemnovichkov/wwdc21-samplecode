/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point into the app.
*/

import SwiftUI

@main
struct GradientBuilderApp: App {
    @State private var store = GradientModelStore.defaultStore

    var body: some Scene {
        WindowGroup {
            ContentView(store: $store)
        }
    }
}
