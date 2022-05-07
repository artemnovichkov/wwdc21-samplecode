/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The particle visualizer.
*/

import SwiftUI

struct ParticleVisualizer: View {
    var gradients: [Gradient]
    @StateObject private var model = ParticleModel()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                model.update(time: now, size: size)

                context.blendMode = .screen
                model.forEachParticle { particle in
                    var innerContext = context
                    innerContext.opacity = particle.opacity
                    innerContext.fill(
                        Ellipse().path(in: particle.frame),
                        with: particle.shading(gradients))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { model.add(position: $0.location) }
        )
        .accessibilityLabel("A particle visualizer")
    }
}

struct ParticleView_Previews: PreviewProvider {
    static var previews: some View {
        ParticleVisualizer(gradients: [])
            .preferredColorScheme(.dark)
    }
}
