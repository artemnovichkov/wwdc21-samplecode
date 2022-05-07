/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The expansion state for the side bar.
*/

import Foundation

struct ExpansionState: RawRepresentable {

    var ids: Set<Int>
    
    let current = 2021

    init?(rawValue: String) {
        ids = Set(rawValue.components(separatedBy: ",").compactMap(Int.init))
    }

    init() {
        ids = []
    }

    var rawValue: String {
        ids.map({ "\($0)" }).joined(separator: ",")
    }

    var isEmpty: Bool {
        ids.isEmpty
    }

    func contains(_ id: Int) -> Bool {
        ids.contains(id)
    }

    mutating func insert(_ id: Int) {
        ids.insert(id)
    }

    mutating func remove(_ id: Int) {
        ids.remove(id)
    }

    subscript(year: Int) -> Bool {
        get {
            // Expand the current year by default
            ids.contains(year) ? true : year == current
        }
        set {
            if newValue {
                ids.insert(year)
            } else {
                ids.remove(year)
            }
        }
    }
}
