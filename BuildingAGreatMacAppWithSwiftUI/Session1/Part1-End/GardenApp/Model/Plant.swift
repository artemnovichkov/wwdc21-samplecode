/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model describing the Plant.
*/

import Foundation

struct Plant: Identifiable, Codable {
    var id: UUID
    var variety: String
    var plantingDepth: Float?
    var daysToMaturity: Int = 0
    var datePlanted = Date()
    var favorite: Bool = false
    var lastWateredOn = Date()
    var wateringFrequency: Int?

    init(
        id: UUID,
        variety: String,
        plantingDepth: Float? = nil,
        daysToMaturity: Int = 0,
        datePlanted: Date = Date(),
        favorite: Bool = false,
        lastWateredOn: Date = Date(),
        wateringFrequency: Int? = 5
    ) {
        self.id = id
        self.variety = variety
        self.plantingDepth = plantingDepth
        self.daysToMaturity = daysToMaturity
        self.datePlanted = datePlanted
        self.favorite = favorite
        self.lastWateredOn = lastWateredOn
        self.wateringFrequency = wateringFrequency
    }

    init() {
        self.init(id: UUID(), variety: "New Plant")
    }

    var harvestDate: Date {
        return datePlanted.addingTimeInterval(TimeInterval(daysToMaturity) * 24 * 60 * 60)
    }

    var needsWater: Bool {
        if let wateringFrequency = wateringFrequency {
            return lastWateredOn.timeIntervalSince(Date()) > TimeInterval(wateringFrequency) * 24 * 60 * 60
        } else {
            return true
        }
    }
}
