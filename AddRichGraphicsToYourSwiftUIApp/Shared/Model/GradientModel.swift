/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The gradient model.
*/

import SwiftUI

struct GradientModel: Equatable, Identifiable {
    /// A single gradient stop.
    struct Stop: Equatable, Identifiable {
        /// Stop color.
        var color: Color
        /// Stop location in [0, 1] range.
        var location: Double
        /// Unique identifier.
        var id: Int
    }

    /// Array of (possibly unsorted) color stops.
    var stops: [Stop]

    /// The name for this gradient.
    var name: String

    /// Unique identifier.
    var id: Int

    subscript(stopID stopID: Stop.ID) -> Stop {
        get { stops.first(where: { $0.id == stopID }) ?? Stop(color: .clear, location: 0, id: 0) }
        set {
            if let index = stops.firstIndex(where: { $0.id == stopID }) {
                stops[index] = newValue
            }
        }
    }

    @discardableResult
    mutating func append(color: Color, at location: Double) -> Stop {
        var id = 0
        for stop in stops {
            id = max(id, stop.id)
        }
        let stop = Stop(color: color, location: location, id: id + 1)
        stops.append(stop)
        return stop
    }

    mutating func remove(_ stopID: Stop.ID) {
        stops.removeAll { $0.id == stopID }
    }

    var ordered: GradientModel {
        var copy = self
        copy.stops.sort(by: { $0.location < $1.location })
        return copy
    }

    var gradient: Gradient {
        Gradient(stops: ordered.stops.map {
            Gradient.Stop(color: $0.color, location: $0.location)
        })
    }
}

extension GradientModel {
    init(colors: [Color], name: String = "", id: Int = 0) {
        stops = []
        for (index, color) in colors.enumerated() {
            stops.append(Stop(
                color: color,
                location: Double(index) / Double(colors.count - 1),
                id: index))
        }
        self.name = name
        self.id = id
    }
}
