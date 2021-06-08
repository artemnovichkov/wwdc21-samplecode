/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The definition of the particle.
*/

import SwiftUI

struct Particle {
    var lifetime = 0.0
    var position = CGPoint.zero
    var parentCenter = CGPoint.zero
    var velocity = CGSize.zero
    var size = 16.0
    var sizeSpeed = 0.0
    var opacity = 0.0
    var opacitySpeed = 0.0
    var gradientIndex = 0
    var colorIndex = 0
    var cell: ParticleCell?

    mutating func update(delta: Double) -> Bool {
        lifetime -= delta
        position.x += velocity.width * delta
        position.y += velocity.height * delta
        size += sizeSpeed * delta
        opacity += opacitySpeed * delta

        var active = lifetime > 0

        if var cell = cell {
            cell.updateOldParticles(delta: delta)
            if active {
                cell.createNewParticles(delta: delta) {
                    Particle(position: position, parentCenter: position,
                         velocity: velocity, size: size,
                         gradientIndex: gradientIndex)
                }
            }
            active = active || cell.isActive
            self.cell = cell
        } else {
            if (opacitySpeed <= 0 && opacity <= 0) ||
                (sizeSpeed <= 0 && size <= 0)
            {
                active = false
            }
        }

        return active
    }

    var frame: CGRect {
        CGRect(origin: position, size: CGSize(width: size, height: size))
    }

    func shading(_ gradients: [Gradient]) -> GraphicsContext.Shading {
        let stops = gradients[gradientIndex % gradients.count].stops
        return .color(stops[colorIndex % stops.count].color)
    }
}
