/*
See LICENSE folder for this sample’s licensing information.

Abstract:
RealityKit system that implements hunger behavior.
*/
import RealityKit

struct HungerComponent: RealityKit.Component {
    var currentFoodTarget: Entity?
}

struct AlgaeEaterComponent: RealityKit.Component { }
struct PlanktonEaterComponent: RealityKit.Component { }

struct FoodComponent: RealityKit.Component { }
struct AlgaeComponent: RealityKit.Component { }
struct PlanktonComponent: RealityKit.Component { }

class EatingSystem: RealityKit.System {
    required init(scene: RealityKit.Scene) { }

    // Food-seeking behavior runs after flocking finishes, but before the
    // MovementSystem applies acceleration to move the fish.
    static var dependencies: [SystemDependency] = [.after(FlockingSystem.self), .before(MotionSystem.self)]

    static let planktonLoverQuery = EntityQuery(where: .has(HungerComponent.self) && .has(MotionComponent.self) && .has(PlanktonEaterComponent.self))
    static let algaeLoverQuery = EntityQuery(where: .has(HungerComponent.self) && .has(MotionComponent.self) && .has(AlgaeEaterComponent.self))

    static let planktonQuery = EntityQuery(where: .has(PlanktonComponent.self))
    static let algaeQuery = EntityQuery(where: .has(AlgaeComponent.self))

    func update(context: SceneUpdateContext) {

        let algae = context.scene.performQuery(Self.algaeQuery).map { $0 }
        let plankton = context.scene.performQuery(Self.planktonQuery).map { $0 }

        // If there's no food in the scene, don't do anything.
        guard !(algae.isEmpty && plankton.isEmpty) else { return }

        let planktonLovers = context.scene.performQuery(Self.planktonLoverQuery).map { $0 }
        let algaeLovers = context.scene.performQuery(Self.algaeLoverQuery).map { $0 }

        let eaters = algaeLovers + planktonLovers

        for eater in eaters {
            guard var motion = eater.components[MotionComponent.self] as? MotionComponent else { continue }
            guard var hungerComponent = eater.components[HungerComponent.self] as? HungerComponent else { continue }
            guard let settings = (eater.components[SettingsComponent.self] as? SettingsComponent)?.settings else { continue }

            // Pick a random food for the fish follow if it's not already following food.
            if hungerComponent.currentFoodTarget == nil {

                if eater.components.has(PlanktonEaterComponent.self) {
                    hungerComponent.currentFoodTarget = plankton.randomElement()
                }

                if hungerComponent.currentFoodTarget == nil, eater.components.has(AlgaeEaterComponent.self) {
                    hungerComponent.currentFoodTarget = algae.randomElement()
                }
            }

            // If there's no food available, there's nothing to do.
            guard let food = hungerComponent.currentFoodTarget else { continue }

            // This fish should steer toward the food.
            var steer = normalize(food.position - eater.position)
            steer *= settings.topSpeed
            steer -= motion.velocity
            motion.forces.append(MotionComponent.Force(acceleration: steer, multiplier: settings.hungerWeight, name: "hunger"))

            // Store changes to the MotionComponent and HungerComponent
            // back into the entity's components collection.
            eater.components[MotionComponent.self] = motion
            eater.components[HungerComponent.self] = hungerComponent
        }
    }
}
