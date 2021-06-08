/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant button view.
*/

import SwiftUI

struct AddPlantButton: View {
    @Binding var garden: Garden?

    var body: some View {
        Button {
            garden?.plants.append(Plant())
        } label: {
            Label("Add Plant", systemImage: "plus")
        }
        .keyboardShortcut("N", modifiers: [.command, .shift])
        .disabled(garden == nil)
    }
}
