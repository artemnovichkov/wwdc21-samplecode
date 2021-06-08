/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The water plants button view.
*/

import SwiftUI

struct WaterPlantsButton: View {
    @Binding var garden: Garden?
    @Binding var plants: Set<Plant.ID>?

    var body: some View {
        Button {
            if let plants = plants {
                garden?.water(plants)
            }
        } label: {
            Label("Water Plants", systemImage: "drop")
        }
        .keyboardShortcut("U", modifiers: [.command, .shift])
        .disabled(garden == nil || plants!.isEmpty)
    }
}
