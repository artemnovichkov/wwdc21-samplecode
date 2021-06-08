/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Deals with adding fish to the scene, and handles their collisions.
*/

import RealityKit
import Foundation

extension UnderwaterView {

    @discardableResult
    func addFish(_ entity: Entity, numberToSpawn: Int, debugName: String, spawnRadius: Float, spawnDelay: TimeInterval) -> [Entity] {
        guard numberToSpawn > 0 else { return [] }

        var fishes = [Entity]()
        fishes.append(entity)

        entity.transform.scale = SIMD3<Float>(repeating: 0.01)

        entity.components[MotionComponent.self] = MotionComponent()

        for _ in 1..<numberToSpawn {
            let clone = entity.clone(recursive: true)
            fishes.append(clone)
        }

        var spawnOrder: TimeInterval = 0

        for fish in fishes {

            spawnOrder += 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + (spawnDelay * spawnOrder)) {
                self.fishAnchor.addChild(fish)

                fish.name = "\(debugName) \(fish.id)"

                // Distribute the fish randomly near the origin to start.
                fish.transform.translation = .spawnPoint(from: Settings.fishOrigin, radius: spawnRadius)

                if let anim = fish.availableAnimations.first {

                    // Play the swimming animation and store it in a component
                    // then adjust the animation speed based on the fish's velocity.
                    let animationController = fish.playAnimation(anim.repeat())
                    let animSpeedComponent = AnimationSpeedComponent(animationController: animationController)
                    fish.components[AnimationSpeedComponent.self] = animSpeedComponent
                }

                // Watch this fish for collisions.
                self.arView.scene.subscribe(to: CollisionEvents.Began.self, on: fish) { [weak self] event in
                    self?.handleFishCollision(event: event, fish: event.entityA, other: event.entityB)
                }.storeWhileEntityActive(fish)
                self.arView.scene.subscribe(to: CollisionEvents.Updated.self, on: fish) { [weak self] event in
                    self?.handleFishCollision(event: event, fish: event.entityA, other: event.entityB)
                }.storeWhileEntityActive(fish)

            }

        }

        return fishes
    }

    func addClownFish(_ entity: Entity) {
        entity.components[HungerComponent.self] = HungerComponent()
        entity.components[WanderAimlesslyComponent.self] = WanderAimlesslyComponent()
        entity.components[PlanktonEaterComponent.self] = PlanktonEaterComponent()
        entity.components[SettingsComponent.self] = SettingsComponent(settings: self.settings)

        addFishCollider(childName: "fish_clown_bind", entity: entity)
        addFish(entity, numberToSpawn: 7, debugName: "Clownfish", spawnRadius: 0.7, spawnDelay: 0)
    }

    func addYellowtang(_ entity: Entity) {
        entity.components[FlockingComponent.self] = FlockingComponent()
        entity.components[HungerComponent.self] = HungerComponent()
        entity.components[AlgaeEaterComponent.self] = AlgaeEaterComponent()
        entity.components[SettingsComponent.self] = SettingsComponent(settings: self.settings)
        entity.components[FearComponent.self] = FearComponent()

        addFishCollider(childName: "fish_yellowtang", entity: entity)
        addFish(entity, numberToSpawn: 10, debugName: "Yellowtang", spawnRadius: self.settings.desiredSeparation, spawnDelay: 0.5)

        if features.contains(.flockLeader) {
            // Make an invisible flock leader for the flockers to follow.
            let leader = Entity()
            fishAnchor.addChild(leader)
            leader.name = "Incorporeal leader"
            leader.position = .spawnPoint(from: Settings.fishOrigin, radius: 0)
            leader.components[SettingsComponent.self] = SettingsComponent(settings: self.settings)
            leader.components[MotionComponent.self] = MotionComponent()
            leader.components[FlockLeader.self] = FlockLeader()
            leader.components[WanderAimlesslyComponent.self] = WanderAimlesslyComponent()
        }
    }

    private func addFishCollider(childName: String, entity: Entity) {
        // Create collision shapes for all this entity's children, then replace
        // the root entity's CollisionComponent with a collider.
        entity.generateCollisionShapes(recursive: true)

        if let colliderChild = entity.findEntity(named: childName) {
            var collisionComponent = colliderChild.components[CollisionComponent.self] as? CollisionComponent
            collisionComponent?.filter = CollisionFilter(group: .fishGroup, mask: [.sceneUnderstanding, .foodGroup])
            entity.components[CollisionComponent.self] = collisionComponent
        }
    }

    static let hungryQuery = EntityQuery(where: .has(HungerComponent.self))

    private func handleFishCollision(event: Event, fish: Entity, other: Entity) {

        if let hungerComponent = fish.components[HungerComponent.self] as? HungerComponent,
           let target = hungerComponent.currentFoodTarget,
           other == target {
            // This fish got to its food target - eat it.
            self.foodPool.foodWasEaten(other)

            // Any other fish that was gunning for this same food is out of luck.
            scene.performQuery(Self.hungryQuery).forEach { hungryCreature in
                guard hungryCreature.components[HungerComponent.self]?.currentFoodTarget == target else { return }
                hungryCreature.components[HungerComponent.self]?.currentFoodTarget = nil
            }
        } else if other is HasSceneUnderstanding,
           other.components.has(CollisionComponent.self),
           var motion = fish.components[MotionComponent.self] as? MotionComponent {

            if let collisionUpdated = (event as? CollisionEvents.Began) {

                // Clear out all the other forces, just for this frame, and send
                // the fish away from this real-world object.
                motion.forces.removeAll()
                motion.velocity = .zero
                var steer = SIMD3<Float>.zero
                let results = scene.raycast(origin: fish.position,
                                            direction: normalize(fish.position.vector(to: collisionUpdated.position)),
                                            length: 1.0,
                                            query: .nearest,
                                            mask: .sceneUnderstanding,
                                            relativeTo: nil)

                if let result = results.first {
                    steer = normalize(result.normal)

                    motion.forces.append(MotionComponent.Force(acceleration: steer, multiplier: settings.bonkWeight, name: "bonk"))
                    
                    fish.components[MotionComponent.self] = motion
                }
            }

        }
    }
}
