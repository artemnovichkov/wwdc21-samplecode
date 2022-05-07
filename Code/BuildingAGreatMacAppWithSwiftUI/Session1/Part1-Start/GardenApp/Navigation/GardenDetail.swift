/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The detail view for each garden.
*/

import SwiftUI

struct GardenDetail: View {

    enum ViewMode: String, CaseIterable, Identifiable {
        var id: Self { self }
        case table
        case gallery
    }

    @EnvironmentObject var store: Store
    @Binding var gardenId: Garden.ID?
    @State var searchText: String = ""
    @SceneStorage("viewMode") private var mode: ViewMode = .table
    @State private var selection = Set<Plant.ID>()

    @State var sortOrder: [KeyPathComparator<Plant>] = [
        .init(\.variety, order: SortOrder.forward)
    ]
    
    var body: some View {
        Text("Plant Table")
            .navigationTitle(garden.name)
            .navigationSubtitle("\(garden.displayYear)")
    }
}

struct GardenDetailPreviews: PreviewProvider {
    static var store = Store()
    static var previews: some View {
        GardenDetail(gardenId: .constant(store.gardens(in: 2021).first!.id))
            .environmentObject(store)
            .frame(width: 450)
    }
}

extension GardenDetail {

    var garden: Garden {
        store[gardenId]
    }

    var gardenBinding: Binding<Garden> {
        $store[gardenId]
    }

    func addPlant() {
        let plant = Plant()
        gardenBinding.wrappedValue.plants.append(plant)
        selection = Set([plant.id])
    }

    var plants: [Plant] {
        return garden.plants
            .filter {
                searchText.isEmpty ? true : $0.variety.localizedCaseInsensitiveContains(searchText)
            }
            .sorted(using: sortOrder)
    }

}

private struct BoolComparator: SortComparator {
    typealias Compared = Bool

    func compare(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        switch (lhs, rhs) {
        case (true, false):
            return order == .forward ? .orderedDescending : .orderedAscending
        case (false, true):
            return order == .forward ? .orderedAscending : .orderedDescending
        default: return .orderedSame
        }
    }

    var order: SortOrder = .forward
}
