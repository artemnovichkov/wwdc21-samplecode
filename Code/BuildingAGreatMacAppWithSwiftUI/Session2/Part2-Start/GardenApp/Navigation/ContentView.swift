/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main content view for this sample.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @SceneStorage("selection") private var selectedGardenID: Garden.ID?

    var body: some View {
        NavigationView {
            Sidebar(selection: selection)
            GardenDetail(garden: selectedGarden)
        }
    }

    private var selection: Binding<Garden.ID?> {
        $selectedGardenID
    }
    
    private var selectedGarden: Binding<Garden> {
        $store[selection.wrappedValue]
    }
}
