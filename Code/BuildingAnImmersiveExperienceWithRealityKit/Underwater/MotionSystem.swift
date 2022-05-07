/*
See LICENSE folder for this sample’s licensing information.

Abstract:
System that implements fish movement.
*/
import RealityKit

/// This system applies the calculated acceleration to the current velocity and moves the entities accordingly.
class MotionSystem: RealityKit.System {

    private static let query = EntityQuery(where: .has(MotionComponent.self) && .has(SettingsComponent.self))

    required init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {

        let deltaTime = Float(context.deltaTime)
        let dtSquared = deltaTime * deltaTime

        context.scene.performQuery(Self.query).forEach { entity in

            guard var motion = entity.components[MotionComponent.self] as? MotionComponent,
            let settings = (entity.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return }

            defer {
                // Reset acceleration for the next update so that the other systems that modify acceleration have a blank slate.
                motion.forces = [MotionComponent.Force]()
                entity.components[MotionComponent.self] = motion
            }

            var newTransform = entity.transform

            // Add up all the forces that our other systems have applied to the MotionComponent, and use that to change the velocity.
            let acceleration = combinedForces(values: motion.forces)

            let accelerationScaled = acceleration * dtSquared * settings.timeScale

            motion.velocity += accelerationScaled

            newTransform.translation += motion.velocity

            entity.move(to: newTransform, relativeTo: nil)

            // If the creature is moving at all, have it look in the direction it's moving.
            if motion.velocity.length > 0 {
                let previousRotation = entity.transform.rotation

                entity.look(
                    at: newTransform.translation - motion.velocity,
                    from: newTransform.translation,
                    relativeTo: nil
                )

                if settings.useAngularModelSpeed {
                    entity.transform.rotation = simd_slerp(
                        entity.transform.rotation,
                        previousRotation,
                        pow(0.9, settings.angularModelSpeed * Float(context.deltaTime) * motion.velocity.length)
                    )
                }
            }
        }
    }

    private func combinedForces(values: [MotionComponent.Force]) -> SIMD3<Float> {
        values.reduce(.zero) { result, force in
            result + (force.acceleration * force.multiplier)
        }
    }
}
