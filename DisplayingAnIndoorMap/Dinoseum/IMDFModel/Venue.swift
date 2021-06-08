/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The decoded representation of an IMDF Venue feature type.
*/

import Foundation

class Venue: Feature<Venue.Properties> {
    struct Properties: Codable {
        let category: String
    }
    
    var levelsByOrdinal: [Int: [Level]] = [:]
}

// For more information about this class, see: https://register.apple.com/resources/imdf/Venue/
