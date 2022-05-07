/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant commands.
*/

import SwiftUI

struct PlantCommands: Commands {
    @FocusedBinding(\.garden) private var garden: Garden?
    @FocusedBinding(\.selection) private var selection: Set<Plant.ID>?

    var body: some Commands {
        CommandGroup(before: .newItem) {
            AddPlantButton(garden: $garden)
        }

        CommandMenu("Plants") {
            WaterPlantsButton(garden: $garden, plants: $selection)
        }
    }
}

