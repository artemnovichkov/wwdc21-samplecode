/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience function for loading Codeable objects from JSON data.
*/

import UIKit
import SwiftUI

// Loads the scenarios for teach dynamic type.
let scenarioData: [Scenario] = load("scenarios.json")
// Loads the texture data to use in a scenario.
let texturesData: [Texture] = load("textures.json")

/// Loads the specified JSON file and constructs an array of Codable objects.
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}
