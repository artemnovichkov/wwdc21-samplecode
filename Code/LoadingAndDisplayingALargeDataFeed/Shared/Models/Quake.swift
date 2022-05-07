/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An NSManagedObject subclass for the Quake entity.
*/

import CoreData
import SwiftUI
import OSLog

// MARK: - Core Data

/// Managed object subclass for the Quake entity.
class Quake: NSManagedObject {

    // The characteristics of a quake.
    @NSManaged var magnitude: Float
    @NSManaged var place: String
    @NSManaged var time: Date

    // A unique identifier used to avoid duplicates in the persistent store.
    // Constrain the Quake entity on this attribute in the data model editor.
    @NSManaged var code: String

    /// Updates a Quake instance with the values from a QuakeProperties.
    func update(from quakeProperties: QuakeProperties) throws {
        let dictionary = quakeProperties.dictionaryValue
        guard let newCode = dictionary["code"] as? String,
              let newMagnitude = dictionary["magnitude"] as? Float,
              let newPlace = dictionary["place"] as? String,
              let newTime = dictionary["time"] as? Date
        else {
            throw QuakeError.missingData
        }
        
        code = newCode
        magnitude = newMagnitude
        place = newPlace
        time = newTime
    }
}

// MARK: - SwiftUI

extension Quake {
    
    /// The color which corresponds with the quake's magnitude.
    var color: Color {
        switch magnitude {
        case 0..<1:
            return .green
        case 1..<2:
            return .yellow
        case 2..<3:
            return .orange
        case 3..<5:
            return .red
        case 5..<Float.greatestFiniteMagnitude:
            return .init(red: 0.8, green: 0.2, blue: 0.7)
        default:
            return .gray
        }
    }
    
    /// An earthquake for use with canvas previews.
    static var preview: Quake {
        let quakes = Quake.makePreviews(count: 1)
        return quakes[0]
    }

    @discardableResult
    static func makePreviews(count: Int) -> [Quake] {
        var quakes = [Quake]()
        let viewContext = QuakesProvider.preview.container.viewContext
        for index in 0..<count {
            let quake = Quake(context: viewContext)
            quake.code = UUID().uuidString
            quake.time = Date().addingTimeInterval(Double(index) * -300)
            quake.magnitude = .random(in: -1.1...10.0)
            quake.place = "15km SSW of Cupertino, CA"
            quakes.append(quake)
        }
        return quakes
    }
}

// MARK: - Codable

/// A struct for decoding JSON with the following structure:
///
/// {
///    "features": [
///          {
///       "properties": {
///         "mag":1.9,
///         "place":"21km ENE of Honaunau-Napoopoo, Hawaii",
///         "time":1539187727610,"updated":1539187924350,
///         "code":"70643082"
///       }
///     }
///   ]
/// }
///
/// Stores an array of decoded QuakeProperties for later use in
/// creating or updating Quake instances.
struct GeoJSON: Decodable {
    
    private enum RootCodingKeys: String, CodingKey {
        case features
    }
    
    private enum FeatureCodingKeys: String, CodingKey {
        case properties
    }
    
    private(set) var quakePropertiesList = [QuakeProperties]()

    init(from decoder: Decoder) throws {
        let rootContainer = try decoder.container(keyedBy: RootCodingKeys.self)
        var featuresContainer = try rootContainer.nestedUnkeyedContainer(forKey: .features)
        
        while !featuresContainer.isAtEnd {
            let propertiesContainer = try featuresContainer.nestedContainer(keyedBy: FeatureCodingKeys.self)
            
            // Decodes a single quake from the data, and appends it to the array, ignoring invalid data.
            if let properties = try? propertiesContainer.decode(QuakeProperties.self, forKey: .properties) {
                quakePropertiesList.append(properties)
            }
        }
    }
}

/// A struct encapsulating the properties of a Quake.
struct QuakeProperties: Decodable {

    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
        case magnitude = "mag"
        case place
        case time
        case code
    }
    
    let magnitude: Float   // 1.9
    let place: String      // "21km ENE of Honaunau-Napoopoo, Hawaii"
    let time: Double       // 1539187727610
    let code: String       // "70643082"
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawMagnitude = try? values.decode(Float.self, forKey: .magnitude)
        let rawPlace = try? values.decode(String.self, forKey: .place)
        let rawTime = try? values.decode(Double.self, forKey: .time)
        let rawCode = try? values.decode(String.self, forKey: .code)
        
        // Ignore earthquakes with missing data.
        guard let magntiude = rawMagnitude,
              let place = rawPlace,
              let time = rawTime,
              let code = rawCode
        else {
            let values = "code = \(rawCode?.description ?? "nil"), "
            + "mag = \(rawMagnitude?.description ?? "nil"), "
            + "place = \(rawPlace?.description ?? "nil"), "
            + "time = \(rawTime?.description ?? "nil")"

            let logger = Logger(subsystem: "com.example.apple-samplecode.Earthquakes", category: "parsing")
            logger.debug("Ignored: \(values)")

            throw QuakeError.missingData
        }
        
        self.magnitude = magntiude
        self.place = place
        self.time = time
        self.code = code
    }
    
    // The keys must have the same name as the attributes of the Quake entity.
    var dictionaryValue: [String: Any] {
        [
            "magnitude": magnitude,
            "place": place,
            "time": Date(timeIntervalSince1970: TimeInterval(time) / 1000),
            "code": code
        ]
    }
}
