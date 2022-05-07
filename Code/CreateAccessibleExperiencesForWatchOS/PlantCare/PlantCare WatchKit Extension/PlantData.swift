/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant data and model.
*/

import Foundation
import os
import SwiftUI
import ClockKit

enum SunlightLevel: Codable, CustomStringConvertible {
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}

struct Plant: Hashable, Codable, Identifiable {
    internal let id: UUID
    let name: String
    let imageName: String
    var wateringFrequency: Int
    var lastWateredDate: Date?
    var fertilizingFrequency: Int
    var lastFertilizedDate: Date?
    var sunlightLevel: SunlightLevel
    
    init(name: String, imageName: String, wateringFrequency: Int, fertilizingFrequency: Int, sunlightLevel: SunlightLevel) {
        self.id = UUID()
        self.name = name
        self.imageName = imageName
        self.wateringFrequency = wateringFrequency
        self.fertilizingFrequency = fertilizingFrequency
        self.sunlightLevel = sunlightLevel
    }
    
    var daysUntilNextWateringDue: Int {
        if let lastWateredDate = lastWateredDate {
            return remainingDays(lastTaskDate: lastWateredDate, frequency: wateringFrequency)
        }
        return 0
    }
    
    var daysUntilNextFertilizingDue: Int {
        if let lastFertilizedDate = lastFertilizedDate {
            return remainingDays(lastTaskDate: lastFertilizedDate, frequency: fertilizingFrequency)
        }
        return 0
    }
    
    func stringForTask(task: PlantTask) -> String {
        // Just a sample app, but make sure to account for pluralization!
        switch task {
        case .water:
            return "\(daysUntilNextWateringDue) days"
        case .fertilize:
            return "\(daysUntilNextFertilizingDue) days"
        case .sunlight:
            return "\(sunlightLevel)"
        }
    }
    
    func accessibilityStringForTask(task: PlantTask) -> String {
        // Just a sample app, but make sure to account for pluralization!
        switch task {
        case .water:
            return "\(task.name) in \(daysUntilNextWateringDue) days"
        case .fertilize:
            return "\(task.name) in \(daysUntilNextFertilizingDue) days"
        case .sunlight:
            return "Keep in \(sunlightLevel) sunlight"
        }
    }
    
    func remainingDays(lastTaskDate: Date, frequency: Int) -> Int {
        let oneDay = 24 * 60 * 60
        let dueDate = lastTaskDate.addingTimeInterval(TimeInterval(frequency * oneDay))
        
        let remainingDaysDelta = dueDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
        if remainingDaysDelta < 0 {
            return 0
        } else {
            return Int(round(remainingDaysDelta / Double(oneDay)))
        }
    }
    
    var percentageOfTimeUntilWateringDue: Float {
        return Float(daysUntilNextWateringDue) / Float(wateringFrequency)
    }
    
    static func == (lhs: Plant, rhs: Plant) -> Bool {
        lhs.id == rhs.id
    }
}

enum PlantTask {
    case water
    case fertilize
    case sunlight
    
    var color: Color {
        switch self {
        case .water:
            return .blue
        case .fertilize:
            return .green
        case .sunlight:
            return .orange
        }
    }
    
    var name: String {
        switch self {
        case .water:
            return "Watering"
        case .fertilize:
            return "Fertilizing"
        case .sunlight:
            return "Sunlight"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .water:
            return "drop"
        case .fertilize:
            return "leaf"
        case .sunlight:
            return "sun.max"
        }
    }
    
    var systemImageFillName: String {
        switch self {
        case .water:
            return "drop.fill"
        case .fertilize:
            return "leaf.fill"
        case .sunlight:
            return "sun.max"
        }
    }
}

final class PlantData: ObservableObject {
    @Published public var plants: [Plant] = [Plant]() {
        didSet {
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
        }
    }
    
    static let shared = PlantData()
    
    private init() {
        plants = createTestPlants()
    }
    
    func createTestPlants() -> [Plant] {
        let oneDay = 24 * 60 * 60
        
        var wwDaisy = Plant(name: "WWDaisy", imageName: "Daisy", wateringFrequency: 8, fertilizingFrequency: 20, sunlightLevel: .medium)
        wwDaisy.lastWateredDate = Date().addingTimeInterval(TimeInterval(-1 * oneDay * 3)) // 3 days ago
        wwDaisy.lastFertilizedDate = Date().addingTimeInterval(TimeInterval(-1 * oneDay * 13)) // 13 days ago
        
        var rosieGold = Plant(name: "Rosie Gold", imageName: "Rose", wateringFrequency: 3, fertilizingFrequency: 16, sunlightLevel: .high)
        rosieGold.lastWateredDate = Date() // 0 days ago
        rosieGold.lastFertilizedDate = Date().addingTimeInterval(TimeInterval(-1 * oneDay * 8)) // 8 days ago
        
        var basil = Plant(name: "Fred", imageName: "Basil", wateringFrequency: 10, fertilizingFrequency: 20, sunlightLevel: .low)
        basil.lastWateredDate = Date().addingTimeInterval(TimeInterval(-1 * oneDay * 6)) // 6 days ago
        basil.lastFertilizedDate = Date().addingTimeInterval(TimeInterval(-1 * oneDay * 7)) // 7 days ago
        
        return [wwDaisy, rosieGold, basil]
    }
}
