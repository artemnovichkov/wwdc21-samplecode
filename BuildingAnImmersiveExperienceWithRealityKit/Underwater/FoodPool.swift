/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements fish feeding.
*/

import Foundation
import RealityKit
import Combine
import UIKit
import AVKit

class FoodPool {

    enum FoodType {
        case plankton
        case algae

        static func forNumTouches(_ numTouches: Int) -> FoodType {
            if numTouches == 1 {
                return .plankton
            }
            return algae
        }
    }

    private var planktons = [Entity]()
    private var algae = [Entity]()

    private let arView: ARView
    private var scene: Scene { arView.scene }

    private var foodAnchor = AnchorEntity()

    private var cancellables = [AnyCancellable]()

    private let foodSize = Float(0.01)

    init(arView: ARView, krillModel: Entity) {
        self.arView = arView

        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        twoFingerTap.numberOfTouchesRequired = 2
        arView.addGestureRecognizer(twoFingerTap)

        scene.addAnchor(foodAnchor)

        let sphereMesh = MeshResource.generateSphere(radius: foodSize)

        let sphereCollision = ShapeResource.generateSphere(radius: foodSize)

        let planktonEntity = krillModel
        planktonEntity.components[PlanktonComponent.self] = PlanktonComponent()

        let algaeEntity = ModelEntity(mesh: sphereMesh, materials: [loadAlgaeMaterial()])
        algaeEntity.components[AlgaeComponent.self] = AlgaeComponent()

        addCollision(planktonEntity, collisionShape: sphereCollision)
        addCollision(algaeEntity, collisionShape: sphereCollision)

        for _ in 0..<25 {
            let foodClone = planktonEntity.clone(recursive: true)
            foodClone.components[FoodComponent.self] = FoodComponent()

            // Randomize their orientation so they look more natural.
            foodClone.look(at: .random(in: -1..<1), from: .random(in: -1..<1), relativeTo: nil)

            planktons.append(foodClone)
        }

        for _ in 0..<25 {
            let foodClone = algaeEntity.clone(recursive: true)
            foodClone.components[FoodComponent.self] = FoodComponent()
            algae.append(foodClone)
        }
    }

    func foodWasEaten(_ entity: Entity) {
        entity.removeFromParent()
        entity.stopAllAnimations(recursive: true)
    }

    private func addCollision(_ entity: Entity, collisionShape: ShapeResource) {

        // Add a collision component to the entity so that it can generate its own collision shape.
        var collision = CollisionComponent(shapes: [collisionShape])
        collision.filter = CollisionFilter(group: CollisionGroup.foodGroup, mask: [.sceneUnderstanding, .fishGroup])
        entity.components[CollisionComponent.self] = collision
        entity.generateCollisionShapes(recursive: true)
    }

    private func loadAlgaeMaterial() -> Material {
        var pbr = PhysicallyBasedMaterial()
        pbr.baseColor = .init(tint: #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1))
        pbr.roughness = 0.4
        pbr.anisotropyLevel = 0.8
        pbr.anisotropyAngle = 0.5
        pbr.sheen = .init(tint: #colorLiteral(red: 1, green: 1, blue: 0, alpha: 1))
        return pbr
    }

    private func foods(ofType: FoodType) -> [Entity] {
        switch ofType {
        case .plankton:
            return planktons
        case .algae:
            return algae
        }
    }

    func spawnFood(foodType: FoodType, at worldPos: SIMD3<Float>) {

        let foods = foods(ofType: foodType)

        var availableFoods = foods.filter { !$0.isAnchored }

        guard !availableFoods.isEmpty else { return }

        let food = availableFoods.removeFirst()
        food.transform.translation = worldPos
        foodAnchor.addChild(food)

        if let anim = food.availableAnimations.first {
            food.playAnimation(anim.repeat())
        }
    }

    @objc
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {

        let tapLocation = gestureRecognizer.location(in: gestureRecognizer.view)

        let featurePointResults = arView.hitTest(tapLocation, types: .featurePoint)

        guard let featurePoint = featurePointResults.first?.worldTransform else { return }

        let transform = Transform(matrix: featurePoint)

        // Bring the food a little bit closer to the camera and away from the wall/floor it landed on.
        var spawnPoint = transform.translation
        let cameraPoint = arView.cameraTransform.translation
        let vector = normalize(cameraPoint - spawnPoint) * 0.3
        spawnPoint += vector

        let foodType = FoodType.forNumTouches(gestureRecognizer.numberOfTouches)
        spawnFood(foodType: foodType, at: spawnPoint)

    }
}
