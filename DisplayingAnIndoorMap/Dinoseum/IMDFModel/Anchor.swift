/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The decoded representation of an IMDF Anchor feature type.
*/

import Foundation

class Anchor: Feature<Anchor.Properties> {
    struct Properties: Codable {
        let addressId: String?
        let unitId: UUID
    }
}

// For more information about this class, see: https://register.apple.com/resources/imdf/Anchor/
