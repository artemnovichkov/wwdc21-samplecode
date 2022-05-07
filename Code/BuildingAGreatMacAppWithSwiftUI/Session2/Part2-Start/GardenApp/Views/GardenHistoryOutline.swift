/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The garden history outline view.
*/

import SwiftUI

struct GardenHistoryOutline: View {
    @EnvironmentObject var store: Store
    var range: ClosedRange<Int>
    @Binding var expansionState: ExpansionState

    struct CurrentLabel: View {
        var body: some View {
            Label("Current", systemImage: "chart.bar.doc.horizontal")
        }
    }

    struct PastLabel: View {
        var year: Int
        var body: some View {
            Label(String(year), systemImage: "clock")
        }
    }

    var body: some View {
        ForEach(range.reversed(), id: \.self) { year in
            DisclosureGroup(isExpanded: $expansionState[year]) {
                ForEach(store.gardens(in: year)) { garden in
                    SidebarLabel(garden: garden)
                }
            } label: {
                Group {
                    if store.currentYear == year {
                         CurrentLabel()
                    } else {
                        PastLabel(year: year)
                    }
                }
            }
        }
    }
}
