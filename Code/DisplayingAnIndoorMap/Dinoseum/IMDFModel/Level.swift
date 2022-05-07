/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The decoded representation of an IMDF Level feature type.
*/

import Foundation

class Level: Feature<Level.Properties> {
    struct Properties: Codable {
        let ordinal: Int
        let category: String
        let shortName: LocalizedName
        let outdoor: Bool
        let buildingIds: [String]?
    }
    
    var units: [Unit] = []
    var openings: [Opening] = []
}

// For more information about this class, see: https://register.apple.com/resources/imdf/Level/
