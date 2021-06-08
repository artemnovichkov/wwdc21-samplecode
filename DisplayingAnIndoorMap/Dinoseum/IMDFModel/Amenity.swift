/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The decoded representation of an IMDF Amenity feature type.
*/

import Foundation
import MapKit

class Amenity: Feature<Amenity.Properties>, MKAnnotation {
    struct Properties: Codable {
        let category: String
        let name: LocalizedName?
        let unitIds: [UUID]
    }
    
    var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    var title: String?
    var subtitle: String?
}

// For more information about this class, see: https://register.apple.com/resources/imdf/Amenity/
