/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Iconography for different units for mass and volume.
*/

import Foundation
import SwiftUI

extension Unit {
    public var unitIcon: Image {
        if let iconProvider = self as? UnitIconProvider {
            return iconProvider.customUnitIcon
        }
        // Fallback to 'gauge' where no icon is specified
        return Image(systemName: "gauge")
    }
}

// Allow Unit subclasses to provide icon overrides
private protocol UnitIconProvider {
    var customUnitIcon: Image { get }
}

extension UnitMass: UnitIconProvider {
    var customUnitIcon: Image {
        Image(systemName: "scalemass.fill")
    }
}

extension UnitVolume: UnitIconProvider {
    var customUnitIcon: Image {
        switch symbol {
        // Icons included in the asset catalog
        case "cup", "qt", "tbsp", "tsp", "gal":
            return Image(symbol)
        default:
            return Image(systemName: "drop.fill")
        }
    }
}
