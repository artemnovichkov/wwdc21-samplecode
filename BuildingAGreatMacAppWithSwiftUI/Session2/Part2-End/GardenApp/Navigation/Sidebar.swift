/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample's side bar view.
*/

import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var store: Store
    @SceneStorage("expansionState") var expansionState = ExpansionState()
    @Binding var selection: Garden.ID?

    var body: some View {
        List(selection: $selection) {
            DisclosureGroup(isExpanded: $expansionState[store.currentYear]) {
                ForEach(store.gardens(in: store.currentYear)) { garden in
                    SidebarLabel(garden: garden)
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
