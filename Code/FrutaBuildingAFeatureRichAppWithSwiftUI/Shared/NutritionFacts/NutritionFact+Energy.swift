/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Break down of calories in fat, carbohydrates, and protein
*/

import Foundation

private let kilocaloriesInFat: Double = 9
private let kilocaloriesInCarb: Double = 4
private let kilocaloriesInProtein: Double = 4

public struct CalorieBreakdown {
    public let percentFat: Double
    public let percentCarbohydrate: Double
    public let percentProtein: Double

    public var labeledValues: [(String, Double)] {
        return [
            ("Protein", percentProtein),
            ("Fat", percentFat),
            ("Carbohydrates", percentCarbohydrate)
        ]
    }
}

extension NutritionFact {
    public var kilocaloriesFromFat: Double {
        totalFat.converted(to: .grams).value * kilocaloriesInFat
    }

    public var kilocaloriesFromCarbohydrates: Double {
        (totalCarbohydrates - dietaryFiber).converted(to: .grams).value * kilocaloriesInCarb
    }

    public var kilocaloriesFromProtein: Double {
        protein.converted(to: .grams).value * kilocaloriesInProtein
    }

    public var kilocalories: Double {
        kilocaloriesFromFat + kilocaloriesFromCarbohydrates + kilocaloriesFromProtein
    }

    public var energy: Measurement<UnitEnergy> {
        return Measurement<UnitEnergy>(value: kilocalories, unit: .kilocalories)
    }

    public var calorieBreakdown: CalorieBreakdown {
        let totalKilocalories = kilocalories
        let percentFat = kilocaloriesFromFat / totalKilocalories * 100
        let percentCarbohydrate = kilocaloriesFromCarbohydrates / totalKilocalories * 100
        let percentProtein = kilocaloriesFromProtein / totalKilocalories * 100
        return CalorieBreakdown(
            percentFat: percentFat,
            percentCarbohydrate: percentCarbohydrate,
            percentProtein: percentProtein
        )
    }
}
