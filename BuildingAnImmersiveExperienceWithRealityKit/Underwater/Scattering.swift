/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Scatters entities around the scene.
*/

import ARKit
import RealityKit

/**

This utility randomly scatters objects in the scene. It places them in the environment, respecting estimated
 planes and meshes derived from the LiDAR sensor.

 Each set of objects provides a "validity function" that must pass before a spawn location
 is chosen.

 */
struct Scattering {

    typealias Spawner = ScatteringSpawner

    struct CandidateLocation {
        var position: SIMD3<Float>
        var normal: SIMD3<Float>
    }

    struct ScatteringSet {

        let spawner: Spawner
        var numberOfElementsPerCubeMeter: Int
        var maxNumberOfElements: Int

        init(
            spawner: Spawner,
            numberOfElementsPerCubeMeter: Int = 2,
            maxNumberOfElements: Int = 16
        ) {
            self.spawner = spawner
            self.numberOfElementsPerCubeMeter = numberOfElementsPerCubeMeter
            self.maxNumberOfElements = maxNumberOfElements
        }

        fileprivate var spawnedElementsCount: Int = 0

        func isFull(for boundingBox: BoundingBox) -> Bool {
            let maxElements = min(
                Int(Float(numberOfElementsPerCubeMeter) * boundingBox.volume),
                maxNumberOfElements
            )
            return !(spawnedElementsCount < maxElements)
        }
    }

    private var scatteringSets: [ScatteringSet] = []

    public mutating func add(_ scatteringSet: ScatteringSet) { scatteringSets.append(scatteringSet) }

    /// This method is called whenever the ARKit environment is updated.
    public mutating func update(from anchors: [ARAnchor], view: UnderwaterView) {

        // Computes the bounding box of the ARKit environment.
        let boundingBox = anchors.compactMap({ $0 as? ARMeshAnchor }).reduce(BoundingBox(), { $0.union($1.boundingBox) })

        let potentialSets = self.scatteringSets.enumerated().filter { !$0.element.isFull(for: boundingBox) }

        guard !potentialSets.isEmpty else { return }

        for _ in 0..<4 // Picks a random set for each attempt.
        {
            let scatteringSetIndex = potentialSets[Int.random(in: 0..<potentialSets.count)].offset
            let scatteringSet = scatteringSets[scatteringSetIndex]

            guard !scatteringSet.isFull(for: boundingBox) else { continue }

            let spawner: Spawner = {
                var spawner = scatteringSet.spawner
                spawner.randomize()
                return spawner
            }()

            for _ in 0..<8 // Performs a random raycast for each attempt.
            {
                // Raycasts from the camera in a random direction.
                let randomRaycast = view.scene.raycast(
                    from: view.cameraTransform.translation,
                    to: SIMD3<Float>.random(in: -100...100)
                )
                guard let result = randomRaycast.first else { continue }
                guard result.entity.components.has(SceneUnderstandingComponent.self) else { continue }

                let spawnCandidate = CandidateLocation(position: result.position, normal: result.normal)

                guard let spawnee = spawner.attempt(spawnCandidate) else { return }

                let anchorEntity = AnchorEntity(world: SIMD3<Float>())
                view.scene.addAnchor(anchorEntity)

                anchorEntity.addChild(spawnee)

                spawnee.scaleIn()

                scatteringSets[scatteringSetIndex].spawnedElementsCount += 1
                return
            }
        }
    }
}

protocol ScatteringSpawner {

    /// Randomize the spawning parameters.
    mutating func randomize()

    /// Tries to spawn an entity at the given location.
    func attempt(_ location: Scattering.CandidateLocation) -> Entity?
}

extension Entity {

    func scaleIn() {

        var transformWithZeroScale = transform
        transformWithZeroScale.scale = .zero

        if let animation = try? AnimationResource.generate(with: FromToByAnimation<Transform>(
            from: transformWithZeroScale,
            to: transform,
            duration: 1.0,
            targetPath: .transform
        )) {
            playAnimation(animation)
        }
    }
}
