/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The visualizer.
*/

import SwiftUI

struct Visualizer: View {
    var gradients: [Gradient]

    var body: some View {
        List {
            NavigationLink(destination: ShapeVisualizer(gradients: gradients).ignoresSafeArea()) {
                Label("Shapes", systemImage: "star.fill")
            }

            NavigationLink(destination: ParticleVisualizer(gradients: gradients).ignoresSafeArea()) {
                Label("Particles", systemImage: "sparkles")
            }
        }
        .navigationTitle("Visualizers")
    }
}
