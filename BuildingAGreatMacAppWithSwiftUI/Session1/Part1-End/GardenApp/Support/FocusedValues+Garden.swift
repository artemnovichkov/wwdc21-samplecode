/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The focused value definitions.
*/

import SwiftUI

extension FocusedValues {
    var garden: Binding<Garden>? {
        get { self[FocusedGardenKey.self] }
        set { self[FocusedGardenKey.self] = newValue }
    }

    var selection: Binding<Set<Plant.ID>>? {
        get { self[FocusedGardenSelectionKey.self] }
        set { self[FocusedGardenSelectionKey.self] = newValue }
    }

    private struct FocusedGardenKey: FocusedValueKey {
        typealias Value = Binding<Garden>
    }

    private struct FocusedGardenSelectionKey: FocusedValueKey {
        typealias Value = Binding<Set<Plant.ID>>
    }
}
