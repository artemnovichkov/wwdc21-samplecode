/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The particle model.
*/

import SwiftUI

final class ParticleModel: ObservableObject {
    private var rootCell = ParticleCell(birthRate: 2.0)
    private var lastTime = 0.0

    func update(time: Double, size: CGSize) {
        let delta = min(time - lastTime, 1.0 / 30.0)
        lastTime = time

        if delta > 0 {
            rootCell.updateOldParticles(delta: delta)
            rootCell.createNewParticles(delta: delta) {
                make(position: CGPoint(
                    x: Double.random(in: 0..<size.width),
                    y: Double.random(in: 0..<size.height)))
            }
        }
    }

    func add(position: CGPoint) {
        let particle = make(position: position)
        rootCell.particles.append(particle)
    }

    func make(position: CGPoint) -> Particle {
        var particle = Particle()
        particle.lifetime = 0.5
        particle.position = position
        particle.parentCenter = particle.position
        particle.gradientIndex = Int.random(in: 0..<100)

        var cell = ParticleCell()
        cell.beginEmitting = 0.0
        cell.endEmitting = Double.random(in: 0.05..<0.1)
        cell.birthRate = 8000
        cell.generator = { particle in
            particle.lifetime = Double.random(in: 0.2..<0.5)
            let ang = Double.random(in: -.pi ..< .pi)
            let velocity = Double.random(in: 200..<400)
            particle.velocity = CGSize(width: velocity * cos(ang), height: velocity * -sin(ang))
            particle.size *= Double.random(in: 0.25..<1)
            particle.sizeSpeed = -particle.size * 0.5
            particle.opacity = Double.random(in: 0.25..<0.75)
            particle.opacitySpeed = -particle.opacity / particle.lifetime
            particle.colorIndex = Int.random(in: 0..<100)
        }
        particle.cell = cell
        return particle
    }

    func forEachParticle(do body: (Particle) -> Void) {
        rootCell.forEachParticle(do: body)
    }
}
