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

    @Binding var garden: Garden
    @State var searchText: String = ""
    @SceneStorage("viewMode") private var mode: ViewMode = .table
    @State private var selection = Set<Plant.ID>()

    @State var sortOrder: [KeyPathComparator<Plant>] = [
        .init(\.variety, order: SortOrder.forward)
    ]

    var table: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Variety", value: \.variety)

            TableColumn("Days to Maturity", value: \.daysToMaturity) { plant in
                Text(plant.daysToMaturity.formatted())
            }

            TableColumn("Date Planted", value: \.datePlanted) { plant in
                Text(plant.datePlanted.formatted(date: .abbreviated, time: .omitted))
            }

            TableColumn("Harvest Date", value: \.harvestDate) { plant in
                Text(plant.harvestDate.formatted(date: .abbreviated, time: .omitted))
            }

            TableColumn("Last Watered", value: \.lastWateredOn) { plant in
                Text(plant.lastWateredOn.formatted(date: .abbreviated, time: .omitted))
            }

            TableColumn("Favorite", value: \.favorite, comparator: BoolComparator()) { plant in
                Toggle("Favorite", isOn: $garden[plant.id].favorite)
                    .labelsHidden()
            }
            .width(50)
        } rows: {
            ForEach(plants) { plant in
                TableRow(plant)
                    .itemProvider { plant.itemProvider }
            }
            .onInsert(of: [Plant.draggableType]) { index, providers in
                Plant.fromItemProviders(providers) { plants in
                    garden.plants.insert(contentsOf: plants, at: index)
                }
            }
        }
    }

    var body: some View {
        Group {
            switch mode {
            case .table:
                table
            case .gallery:
                PlantGallery(garden: $garden, selection: $selection)
            }
        }
        .focusedSceneValue(\.garden, $garden)
        .focusedSceneValue(\.selection, $selection)
        .searchable(text: $searchText)
        .toolbar {
            DisplayModePicker(mode: $mode)
            Button(action: addPlant) {
                Label("Add Plant", systemImage: "plus")
            }
        }
        .navigationTitle(garden.name)
        .navigationSubtitle("\(garden.displayYear)")
        .importsItemProviders(selection.isEmpty ? [] : Plant.importImageTypes) { providers in
            Plant.importImageFromProviders(providers) { url in
                for plantID in selection {
                    garden[plantID].imageURL = url
                }
            }
        }
    }
}

extension GardenDetail {

    func addPlant() {
        let plant = Plant()
        garden.plants.append(plant)
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
