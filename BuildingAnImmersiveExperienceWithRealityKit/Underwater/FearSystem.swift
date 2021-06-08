/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Component and system that implements fish fear behavior.
*/

import RealityKit

/// Creatures that are afraid of scary creatures have this component.
struct FearComponent: Component {
    var fearLevel: Float = 0
}

/// Creatures that are scary to other creatures have this component.
struct ScaryComponent: Component { }

class FearSystem: System {
    required init(scene: Scene) { }

    static var dependencies: [SystemDependency] { [.before(MotionSystem.self)] }

    private static let fearfulQuery = EntityQuery(where: .has(FearComponent.self) && .has(MotionComponent.self) && .has(SettingsComponent.self))

    private static let scaryQuery = EntityQuery(where: .has(ScaryComponent.self))

    private let fearMax: Float = 0.7

    func update(context: SceneUpdateContext) {

        let scaries = context.scene.performQuery(Self.scaryQuery).map { $0 }

        // If there's nothing to be afraid of, do nothing.
        guard !scaries.isEmpty else { return }

        context.scene.performQuery(Self.fearfulQuery).forEach { entity in
            guard let settings = (entity.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return }

            // Find the closest scary creature.
            var scariest: Entity?
            var shortestDistance: Float = Float.infinity
            for scary in scaries {
                let distance = entity.distance(from: scary)
                guard distance < shortestDistance, distance < fearMax else { continue }
                shortestDistance = distance
                scariest = scary
            }

            guard let scariest = scariest else { return }

            if var motion = entity.components[MotionComponent.self] as? MotionComponent {
                // Swim away from that creature.
                var steer = entity.seek(scariest.position) * -1
                steer.clamp(lowerBound: -settings.maxSteeringForceVector, upperBound: settings.maxSteeringForceVector)

                motion.forces.append(MotionComponent.Force(acceleration: steer, multiplier: settings.fearWeight, name: "fear"))

                entity.components[MotionComponent.self] = motion
            }
        }
    }
}
