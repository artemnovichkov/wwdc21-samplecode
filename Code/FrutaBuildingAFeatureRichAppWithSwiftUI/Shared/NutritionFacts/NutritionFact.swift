/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Nutritional facts for food items.
*/

import Foundation

public struct Density {
    public var mass: Measurement<UnitMass>
    public var volume: Measurement<UnitVolume>

    public init(_ massAmount: Double, _ massUnit: UnitMass, per volumeAmount: Double, _ volumeUnit: UnitVolume) {
        self.mass = Measurement(value: massAmount, unit: massUnit)
        self.volume = Measurement(value: volumeAmount, unit: volumeUnit)
    }

    public init(mass: Measurement<UnitMass>, volume: Measurement<UnitVolume>) {
        self.mass = mass
        self.volume = volume
    }
}

public struct NutritionFact {
    public var identifier: String
    public var localizedFoodItemName: String

    public var referenceMass: Measurement<UnitMass>

    public var density: Density

    public var totalSaturatedFat: Measurement<UnitMass>
    public var totalMonounsaturatedFat: Measurement<UnitMass>
    public var totalPolyunsaturatedFat: Measurement<UnitMass>
    public var totalFat: Measurement<UnitMass> {
        return totalSaturatedFat + totalMonounsaturatedFat + totalPolyunsaturatedFat
    }

    public var cholesterol: Measurement<UnitMass>
    public var sodium: Measurement<UnitMass>

    public var totalCarbohydrates: Measurement<UnitMass>
    public var dietaryFiber: Measurement<UnitMass>
    public var sugar: Measurement<UnitMass>

    public var protein: Measurement<UnitMass>

    public var calcium: Measurement<UnitMass>
    public var potassium: Measurement<UnitMass>

    public var vitaminA: Measurement<UnitMass>
    public var vitaminC: Measurement<UnitMass>
    public var iron: Measurement<UnitMass>
}

extension NutritionFact {
    public func converted(toVolume newReferenceVolume: Measurement<UnitVolume>) -> NutritionFact {
        let newRefMassInCups = newReferenceVolume.converted(to: .cups).value
        let oldRefMassInCups = referenceMass.convertedToVolume(usingDensity: self.density).value

        let scaleFactor = newRefMassInCups / oldRefMassInCups

        return NutritionFact(
            identifier: identifier,
            localizedFoodItemName: localizedFoodItemName,
            referenceMass: referenceMass * scaleFactor,
            density: density,
            totalSaturatedFat: totalSaturatedFat * scaleFactor,
            totalMonounsaturatedFat: totalMonounsaturatedFat * scaleFactor,
            totalPolyunsaturatedFat: totalPolyunsaturatedFat * scaleFactor,
            cholesterol: cholesterol * scaleFactor,
            sodium: sodium * scaleFactor,
            totalCarbohydrates: totalCarbohydrates * scaleFactor,
            dietaryFiber: dietaryFiber * scaleFactor,
            sugar: sugar * scaleFactor,
            protein: protein * scaleFactor,
            calcium: calcium * scaleFactor,
            potassium: potassium * scaleFactor,
            vitaminA: vitaminA * scaleFactor,
            vitaminC: vitaminC * scaleFactor,
            iron: iron * scaleFactor
        )
    }

    public func converted(toMass newReferenceMass: Measurement<UnitMass>) -> NutritionFact {
        let newRefMassInGrams = newReferenceMass.converted(to: .grams).value
        let oldRefMassInGrams = referenceMass.converted(to: .grams).value
        let scaleFactor = newRefMassInGrams / oldRefMassInGrams
        return NutritionFact(
            identifier: identifier,
            localizedFoodItemName: localizedFoodItemName,
            referenceMass: newReferenceMass,
            density: density,
            totalSaturatedFat: totalSaturatedFat * scaleFactor,
            totalMonounsaturatedFat: totalMonounsaturatedFat * scaleFactor,
            totalPolyunsaturatedFat: totalPolyunsaturatedFat * scaleFactor,
            cholesterol: cholesterol * scaleFactor,
            sodium: sodium * scaleFactor,
            totalCarbohydrates: totalCarbohydrates * scaleFactor,
            dietaryFiber: dietaryFiber * scaleFactor,
            sugar: sugar * scaleFactor,
            protein: protein * scaleFactor,
            calcium: calcium * scaleFactor,
            potassium: potassium * scaleFactor,
            vitaminA: vitaminA * scaleFactor,
            vitaminC: vitaminC * scaleFactor,
            iron: iron * scaleFactor
        )
    }

    public func amount(_ mass: Measurement<UnitMass>) -> NutritionFact {
        return converted(toMass: mass)
    }

    public func amount(_ volume: Measurement<UnitVolume>) -> NutritionFact {
        let mass = volume.convertedToMass(usingDensity: density)
        return converted(toMass: mass)
    }
}

extension NutritionFact {
    /// Nutritional information is for 100 grams, unless a `mass` is specified.
    public static func lookupFoodItem(_ foodItemIdentifier: String,
                                      forMass mass: Measurement<UnitMass> = Measurement(value: 100, unit: .grams)) -> NutritionFact? {
        return nutritionFacts[foodItemIdentifier]?.converted(toMass: mass)
    }

    /// Nutritional information is for 1 cup, unless a `volume` is specified.
    public static func lookupFoodItem(_ foodItemIdentifier: String,
                                      forVolume volume: Measurement<UnitVolume> = Measurement(value: 1, unit: .cups)) -> NutritionFact? {
        guard let nutritionFact = nutritionFacts[foodItemIdentifier] else {
            return nil
        }

        // Convert volume to mass via density
        let mass = volume.convertedToMass(usingDensity: nutritionFact.density)
        return nutritionFact.converted(toMass: mass)
    }

    // MARK: - Examples

    public static var banana: NutritionFact {
        nutritionFacts["banana"]!
    }

    public static var blueberry: NutritionFact {
        nutritionFacts["blueberry"]!
    }

    public static var peanutButter: NutritionFact {
        nutritionFacts["peanut-butter"]!
    }

    public static var almondMilk: NutritionFact {
        nutritionFacts["almond-milk"]!
    }

    public static var zero: NutritionFact {
        NutritionFact(
            identifier: "",
            localizedFoodItemName: "",
            referenceMass: .grams(0),
            density: Density(mass: .grams(1), volume: .cups(1)),
            totalSaturatedFat: .grams(0),
            totalMonounsaturatedFat: .grams(0),
            totalPolyunsaturatedFat: .grams(0),
            cholesterol: .grams(0),
            sodium: .grams(0),
            totalCarbohydrates: .grams(0),
            dietaryFiber: .grams(0),
            sugar: .grams(0),
            protein: .grams(0),
            calcium: .grams(0),
            potassium: .grams(0),
            vitaminA: .grams(0),
            vitaminC: .grams(0),
            iron: .grams(0)
        )
    }
}

extension NutritionFact {
    // Support adding up nutritional facts
    public static func + (lhs: NutritionFact, rhs: NutritionFact) -> NutritionFact {
        // Calculate combined mass, volume and density
        let totalMass = lhs.referenceMass + rhs.referenceMass
        let lhsVolume = lhs.referenceMass.convertedToVolume(usingDensity: lhs.density)
        let rhsVolume = lhs.referenceMass.convertedToVolume(usingDensity: lhs.density)
        let totalVolume = lhsVolume + rhsVolume

        return NutritionFact(
            identifier: "",
            localizedFoodItemName: "",
            referenceMass: totalMass,
            density: Density(mass: totalMass, volume: totalVolume),
            totalSaturatedFat: lhs.totalSaturatedFat + rhs.totalSaturatedFat,
            totalMonounsaturatedFat: lhs.totalMonounsaturatedFat + rhs.totalMonounsaturatedFat,
            totalPolyunsaturatedFat: lhs.totalPolyunsaturatedFat + rhs.totalPolyunsaturatedFat,
            cholesterol: lhs.cholesterol + rhs.cholesterol,
            sodium: lhs.sodium + rhs.sodium,
            totalCarbohydrates: lhs.totalCarbohydrates + rhs.totalCarbohydrates,
            dietaryFiber: lhs.dietaryFiber + rhs.dietaryFiber,
            sugar: lhs.sugar + rhs.sugar,
            protein: lhs.protein + rhs.protein,
            calcium: lhs.calcium + rhs.calcium,
            potassium: lhs.potassium + rhs.potassium,
            vitaminA: lhs.vitaminA + rhs.vitaminA,
            vitaminC: lhs.vitaminC + rhs.vitaminC,
            iron: lhs.iron + rhs.iron
        )
    }
}

// MARK: - CustomStringConvertible

extension NutritionFact: CustomStringConvertible {
    public var description: String {
        let suffix = identifier.isEmpty ? "" : " of \(identifier)"
        return "\(referenceMass.converted(to: .grams).localizedSummary(unitStyle: .medium))" + suffix
    }
}

// MARK: - Volume <-> Mass Conversion

extension Measurement where UnitType == UnitVolume {
    public func convertedToMass(usingDensity density: Density) -> Measurement<UnitMass> {
        let densityLiters = density.volume.converted(to: .liters).value
        let liters = converted(to: .liters).value
        let scale = liters / densityLiters
        return density.mass * scale
    }
}

extension Measurement where UnitType == UnitMass {
    public func convertedToVolume(usingDensity density: Density) -> Measurement<UnitVolume> {
        let densityKilograms = density.mass.converted(to: .kilograms).value
        let kilograms = converted(to: .kilograms).value
        let scale = kilograms / densityKilograms
        return density.volume * scale
    }
}

// MARK: - Convenience Accessors

extension Measurement where UnitType == UnitVolume {
    public static func cups(_ cups: Double) -> Measurement<UnitVolume> {
        return Measurement(value: cups, unit: .cups)
    }

    public static func tablespoons(_ tablespoons: Double) -> Measurement<UnitVolume> {
        return Measurement(value: tablespoons, unit: .tablespoons)
    }
}

extension Measurement where UnitType == UnitMass {
    public static func grams(_ grams: Double) -> Measurement<UnitMass> {
        return Measurement(value: grams, unit: .grams)
    }
}
