/*
See LICENSE folder for this sample’s licensing information.

Abstract:
RealityKit system that implements boids flocking.
*/

import RealityKit

struct FlockingComponent: Component { }

struct FlockLeader: Component { }

class FlockingSystem: RealityKit.System {

    private static let query = EntityQuery(where: .has(FlockingComponent.self) && .has(MotionComponent.self) && .has(SettingsComponent.self))
    private static let leaderQuery = EntityQuery(where: .has(FlockLeader.self))

    // This system runs before the Motion system because it manages the acceleration and velocity, which this system modifies.
    static var dependencies: [SystemDependency] { [.before(MotionSystem.self)] }

    required init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {

        let leader = context.scene.performQuery(Self.leaderQuery).map { $0 }.first

        let flockers = context.scene.performQuery(Self.query)

        for entity in flockers {
            guard var motion = entity.components[MotionComponent.self] as? MotionComponent else { continue }
            guard let settings = (entity.components[SettingsComponent.self] as? SettingsComponent)?.settings else { continue }

            let separation = separate(from: entity, flockers)
            let alignment = align(from: entity, flockers)
            let cohesion = cohere(from: entity, flockers)

            motion.forces.append(MotionComponent.Force(acceleration: separation, multiplier: settings.separationWeight, name: "sep"))
            motion.forces.append(MotionComponent.Force(acceleration: alignment, multiplier: settings.alignmentWeight, name: "al"))
            motion.forces.append(MotionComponent.Force(acceleration: cohesion, multiplier: settings.cohesionWeight, name: "coh"))

            // If there is a flock leader, follow them for a bit. This prevents the fish from flocking straight in one direction forever.
            if let leader = leader {
                var steer = normalize(leader.position - entity.position)
                steer *= settings.topSpeed
                motion.forces.append(MotionComponent.Force(acceleration: steer, multiplier: settings.cohesionWeight, name: "leader"))
            }

            entity.components[MotionComponent.self] = motion
        }
    }

    private func separate(from entity1: Entity, _ entities: QueryResult<Entity>) -> SIMD3<Float> {
        guard let motion = entity1.components[MotionComponent.self] as? MotionComponent,
        let settings = (entity1.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return .zero }

        var steer = SIMD3<Float>.zero

        var numEntities = 0

        let desiredSeparation = settings.desiredSeparation

        for entity2 in entities where entity2 != entity1 {

            let distance = entity1.distance(from: entity2)

            if distance < desiredSeparation {
                var diff = entity1.transform.translation - entity2.transform.translation

                diff = normalize(diff)
                if distance > 0 {
                    diff /= distance
                } else {
                    // If they're in exactly the same position, choose a random vector.
                    diff = SIMD3<Float>.random(in: -settings.maxSteeringForce..<settings.maxSteeringForce)
                }
                steer += diff
            }

            numEntities += 1
        }

        if numEntities > 0 {
            steer *= (1.0 / Float(numEntities))
        }

        if simd_length(steer) > 0 {
            steer = normalize(steer)
            steer *= settings.topSpeed
            steer -= motion.velocity
            steer.clamp(lowerBound: -settings.maxSteeringForceVector, upperBound: settings.maxSteeringForceVector)
        }

        return steer
    }

    private func align(from entity1: Entity, _ entities: QueryResult<Entity>) -> SIMD3<Float> {
        guard let velocity = (entity1.components[MotionComponent.self] as? MotionComponent)?.velocity else { return .zero }
        guard let settings = (entity1.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return .zero }

        var sum = SIMD3<Float>.zero
        var numNeighbors = 0
        for entity2 in entities where entity2 != entity1 {
            guard let otherMotionComponent = entity2.components[MotionComponent.self] as? MotionComponent else { continue }

            if entity1.isDistanceWithinThreshold(from: entity2, max: settings.maxNeighborDistance) {
                sum += otherMotionComponent.velocity
                numNeighbors += 1
            }
        }

        if numNeighbors > 0 && sum.length > 0 {
            sum /= Float(numNeighbors)
            sum = normalize(sum)
            sum *= settings.topSpeed
            var steer: SIMD3<Float> = sum - velocity
            steer.clamp(lowerBound: -settings.maxSteeringForceVector, upperBound: settings.maxSteeringForceVector)
            return steer
        } else {
            return .zero
        }
    }

    private func cohere(from entity1: Entity, _ entities: QueryResult<Entity>) -> SIMD3<Float> {
        guard let settings = (entity1.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return .zero }
        var sum = SIMD3<Float>.zero
        var numNeighbors = 0

        for entity2 in entities where entity2 != entity1 {
            if entity1.isDistanceWithinThreshold(from: entity2, max: settings.maxNeighborDistance) {
                sum += entity2.transform.translation
                numNeighbors += 1
            }
        }

        if numNeighbors > 0 {
            sum /= Float(numNeighbors)
            return entity1.seek(sum)
        } else {
            return .zero
        }
    }

}

extension Entity {

    func seek(_ target: SIMD3<Float>) -> SIMD3<Float> {
        guard let velocity = (self.components[MotionComponent.self] as? MotionComponent)?.velocity else { return .zero }
        guard let settings = (self.components[SettingsComponent.self] as? SettingsComponent)?.settings else { return .zero }
        var desired = target - self.position
        desired = normalize(desired)
        desired *= settings.topSpeed

        var steer = desired - velocity
        steer.clamp(lowerBound: -settings.maxSteeringForceVector, upperBound: settings.maxSteeringForceVector)
        return steer
    }
}
