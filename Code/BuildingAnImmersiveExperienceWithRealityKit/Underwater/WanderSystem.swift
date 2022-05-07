/*
See LICENSE folder for this sample’s licensing information.

Abstract:
System and component to implement non-schooling fish behavior.
*/

import RealityKit
import Foundation

struct WanderAimlesslyComponent: RealityKit.Component {
    var attractor: SIMD3<Float>?

    // Each wanderer wanders at a different speed.
    let wanderlust: Float = Float.random(in: 0.1..<1.0)
}

class WanderSystem: RealityKit.System {

    private static let query = EntityQuery(where: .has(WanderAimlesslyComponent.self) && .has(MotionComponent.self) && .has(SettingsComponent.self))

    // This system should always run before the Motion system, which manages
    // acceleration, which this system modifies.
    static var dependencies: [SystemDependency] { [.before(MotionSystem.self)] }

    required init(scene: Scene) { }

    func update(context: SceneUpdateContext) {
        let wanderers = context.scene.performQuery(Self.query)

        for entity in wanderers {
            guard var motion = entity.components[MotionComponent.self] as? MotionComponent,
                var wander = entity.components[WanderAimlesslyComponent.self] as? WanderAimlesslyComponent,
                let settings = (entity.components[SettingsComponent.self] as? SettingsComponent)?.settings else { continue }

            var distanceFromAttractor: Float = 0

            if let attractor = wander.attractor {
                distanceFromAttractor = entity.distance(from: attractor)
            }

            // This method has reached its attractor; pick a new one.
            if distanceFromAttractor < 0.01 {

                var newAttractor = SIMD3<Float>.spawnPoint(from: Settings.fishOrigin, radius: Settings.wanderRadius)

                // Keep the wanderer roughly level with where it currently is
                // to avoid going up or down too steeply.
                newAttractor.y = entity.position.y + Float.random(in: -0.1..<0.1)

                let obstacles = context.scene.raycast(from: entity.position,
                                                      to: newAttractor,
                                                      query: .nearest,
                                                      mask: .sceneUnderstanding,
                                                      relativeTo: nil)

                // Don't pick a point in the wall.
                if let nearest = obstacles.first {
                    newAttractor = nearest.position
                }

                wander.attractor = newAttractor
            }

            if let attractor = wander.attractor {
                var steer = normalize(attractor - entity.position)
                steer *= settings.topSpeed * wander.wanderlust
                steer -= motion.velocity
                motion.forces.append(MotionComponent.Force(acceleration: steer, multiplier: settings.attractorWeight, name: "wander"))
            }

            entity.components[MotionComponent.self] = motion
            entity.components[WanderAimlesslyComponent.self] = wander
        }
    }
}
