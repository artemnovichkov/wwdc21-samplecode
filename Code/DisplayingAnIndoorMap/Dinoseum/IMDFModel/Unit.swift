/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The decoded representation of an IMDF Unit feature type.
*/

import Foundation

class Unit: Feature<Unit.Properties> {
    struct Properties: Codable {
        let category: String
        let levelId: UUID
    }
    
    var occupants: [Occupant] = []
    var amenities: [Amenity] = []
}

// For more information about this class, see: https://register.apple.com/resources/imdf/Unit/
