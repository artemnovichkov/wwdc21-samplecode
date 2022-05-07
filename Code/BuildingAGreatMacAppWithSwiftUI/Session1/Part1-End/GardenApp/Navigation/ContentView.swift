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
            Sidebar(selection: $selectedGardenID)
            GardenDetail(gardenId: $selectedGardenID)
        }
    }
}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}

struct Sidebar: View {

    @EnvironmentObject var store: Store

    @SceneStorage("expansionState") var expansionState = ExpansionState()

    @Binding var selection: Garden.ID?

    var body: some View {
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $expansionState[store.currentYear]) {
                ForEach(store.gardens(in: store.currentYear)) { garden in
                    Label(garden.name, systemImage: "leaf")
                        .badge(garden.numberOfPlantsNeedingWater)
                }
            } label: {
                Label("Current", systemImage: "chart.bar.doc.horizontal")
            }

            Section("History") {
                GardenHistoryOutline(range: store.previousYears, expansionState: $expansionState)
            }
        }
        .frame(minWidth: 250)
    }
}

