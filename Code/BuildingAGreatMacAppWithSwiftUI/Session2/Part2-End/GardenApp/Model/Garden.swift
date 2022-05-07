/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model describing the Garden.
*/

import Foundation

struct Garden: Codable, Identifiable {
    var id: String
    var year: Int
    var name: String
    var plants: [Plant]

    var numberOfPlantsNeedingWater: Int {
        let result = plants.reduce(0) { count, plant in count + (plant.needsWater ? 1 : 0) }
        print("\(name) has \(result)")
        for plant in plants {
            print("- \(plant)")
        }
        return result
    }

    mutating func water(_ plantsToWater: Set<Plant.ID>) {
        for (index, plant) in plants.enumerated() {
            if plantsToWater.contains(plant.id) {
                plants[index].lastWateredOn = Date()
            }
        }
    }

    mutating func remove(_ plants: Set<Plant.ID>) {
        self.plants.removeAll(where: { plants.contains($0.id) })
    }

    var displayYear: String {
        String(year)
    }

    subscript(plantId: Plant.ID?) -> Plant {
        get {
            if let id = plantId {
                return plants.first(where: { $0.id == id })!
            }
            return Plant()
        }

        set(newValue) {
            if let index = plants.firstIndex(where: { $0.id == newValue.id }) {
                plants[index] = newValue
            }
        }
    }
}

extension Garden {
    static var placeholder: Self {
        Garden(id: UUID().uuidString, year: 2021, name: "New Garden", plants: [])
    }
}
