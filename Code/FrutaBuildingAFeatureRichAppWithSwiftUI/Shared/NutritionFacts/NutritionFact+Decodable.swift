/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Loading nutrition facts from JSON
*/

import Foundation

//let nutritionFacts: [String: NutritionFact] = {
//    let jsonURL = Bundle.main.url(forResource: "NutritionalItems", withExtension: "json")!
//    let jsonData = try! Data(contentsOf: jsonURL)
//
//
//    return try! JSONDecoder().decode(Dictionary<String, NutritionFact>.self, from: jsonData)
//}()

let nutritionFacts: [String: NutritionFact] = {
        if let jsonURL = Bundle.main.url(forResource: "NutritionalItems", withExtension: "json"),
           let jsonData = try? Data(contentsOf: jsonURL),
           let facts = try? JSONDecoder().decode(Dictionary<String, NutritionFact>.self, from: jsonData) {
            return facts
        } else {
            return [String: NutritionFact]()
        }
    }()

extension NutritionFact: Decodable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case localizedFoodItemName
        case referenceMass
        case density
        case totalSaturatedFat
        case totalMonounsaturatedFat
        case totalPolyunsaturatedFat
        case cholesterol
        case sodium
        case totalCarbohydrates
        case dietaryFiber
        case sugar
        case protein
        case calcium
        case potassium
        case vitaminA
        case vitaminC
        case iron
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try values.decode(String.self, forKey: .identifier)
        localizedFoodItemName = try values.decode(String.self, forKey: .localizedFoodItemName)

        let densityString = try values.decode(String.self, forKey: .density)
        density = Density.fromString(densityString)

        referenceMass = try values.decode(Measurement<UnitMass>.self, forKey: .referenceMass)
        totalSaturatedFat = try values.decode(Measurement<UnitMass>.self, forKey: .totalSaturatedFat)
        totalMonounsaturatedFat = try values.decode(Measurement<UnitMass>.self, forKey: .totalMonounsaturatedFat)
        totalPolyunsaturatedFat = try values.decode(Measurement<UnitMass>.self, forKey: .totalPolyunsaturatedFat)
        cholesterol = try values.decode(Measurement<UnitMass>.self, forKey: .cholesterol)
        sodium = try values.decode(Measurement<UnitMass>.self, forKey: .sodium)
        totalCarbohydrates = try values.decode(Measurement<UnitMass>.self, forKey: .totalCarbohydrates)
        dietaryFiber = try values.decode(Measurement<UnitMass>.self, forKey: .dietaryFiber)
        sugar = try values.decode(Measurement<UnitMass>.self, forKey: .sugar)
        protein = try values.decode(Measurement<UnitMass>.self, forKey: .protein)
        calcium = try values.decode(Measurement<UnitMass>.self, forKey: .calcium)
        potassium = try values.decode(Measurement<UnitMass>.self, forKey: .potassium)
        vitaminA = try values.decode(Measurement<UnitMass>.self, forKey: .vitaminA)
        vitaminC = try values.decode(Measurement<UnitMass>.self, forKey: .vitaminC)
        iron = try values.decode(Measurement<UnitMass>.self, forKey: .iron)
    }
}

extension KeyedDecodingContainer {
    public func decode(_ type: Measurement<UnitMass>.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> Measurement<UnitMass> {
        let valueString = try decode(String.self, forKey: key)
        return Measurement(string: valueString)
    }

    public func decode(_ type: Measurement<UnitVolume>.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> Measurement<UnitVolume> {
        let valueString = try decode(String.self, forKey: key)
        return Measurement(string: valueString)
    }
}

extension Measurement where UnitType == UnitMass {
    init(string: String) {
        let components = string.split(separator: " ")
        let valueString = String(components[0])
        let unitSymbolString = String(components[1])
        self.init(
            value: Double(valueString)!,
            unit: UnitMass.fromSymbol(unitSymbolString)
        )
    }
}

extension Measurement where UnitType == UnitVolume {
    init(string: String) {
        let components = string.split(separator: " ")
        let valueString = String(components[0])
        let unitSymbolString = String(components[1])
        self.init(
            value: Double(valueString)!,
            unit: UnitVolume.fromSymbol(unitSymbolString)
        )
    }
}

// These methods return Units with an associated converter, whereas units
// initialized from a string using the `Unit(symbol:)` initializer
// do not have a converter associated and thereby don't support conversion.

extension UnitVolume {
    static func fromSymbol(_ symbol: String) -> UnitVolume {
        switch symbol {
        case "gal":
            return .gallons
        case "cup":
            return .cups
        default:
            return UnitVolume(symbol: symbol)
        }
    }
}

extension UnitMass {
    static func fromSymbol(_ symbol: String) -> UnitMass {
        switch symbol {
        case "kg":
            return .kilograms
        case "g":
            return .grams
        case "mg":
            return .milligrams
        default:
            return UnitMass(symbol: symbol)
        }
    }
}

extension UnitEnergy {
    static func fromSymbol(_ symbol: String) -> UnitEnergy {
        switch symbol {
        case "kCal":
            return .kilocalories
        default:
            return UnitEnergy(symbol: symbol)
        }
    }
}

extension Density {
    fileprivate static func fromString(_ string: String) -> Density {
        // Example: 5 g per 1 cup
        let components = string.split(separator: " ")

        let massValue = Double(components[0])!
        let massUnit: UnitMass = .fromSymbol(String(components[1]))
        let volumeValue = Double(components[3])!
        let volumeUnit: UnitVolume = .fromSymbol(String(components[4]))

        return Density(massValue, massUnit, per: volumeValue, volumeUnit)
    }
}
