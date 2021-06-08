/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Spawns and manages seaweed.
*/
import RealityKit

struct SeaweedComponent: RealityKit.Component {}

extension UnderwaterView {

    func setupSeaweed() {
        Entity.loadModelAsync(named: "seaweed/original/seaweed")
            .zip(Entity.loadModelAsync(named: "seaweed/low/seaweed_low"))
            .sink(receiveValue: { [weak self] high, low in
                self?.setupSeaweedScattering(high: high, low: low)
            }).store(in: &cancellables)
    }

    fileprivate func setupSeaweedScattering(high: ModelEntity, low: ModelEntity) {

        let geometryShader = CustomMaterial.GeometryModifier(
            named: "seaweedGeometry",
            in: MetalLibLoader.library
        )
        do {
            try high.set(geometryShader)
            try low.set(geometryShader)
        } catch {
            assertionFailure("Failed to set a custom shader on the sea weed \(error)")
        }

        guard let highModel = high.model, let lowModel = low.model else {
            assertionFailure("No mesh on the seaweed")
            return
        }

        let entity = low
        if self.features.contains(.highLevelsOfDetail) {
            entity.components.set(LevelOfDetailComponent([
                .init(maxDistance: 1.0, model: highModel),
                .init(maxDistance: 1E2, model: lowModel)
            ]))
        }

        entity.components[SeaweedComponent.self] = SeaweedComponent()

        scattering.add(Scattering.ScatteringSet(spawner: SeaweedSpawner(
            entity: entity,
            view: self
        )))
    }

    fileprivate struct SeaweedSpawner: ScatteringSpawner {

        private static let query = EntityQuery(where: .has(SeaweedComponent.self))

        let entity: Entity
        weak var view: UnderwaterView?

        mutating func randomize() {}

        func attempt(_ location: Scattering.CandidateLocation) -> Entity? {
            guard let view = self.view else { return nil }

            // Can't spawn too close to the other ones.
            guard view.scene.performQuery(Self.query).filter({
                $0.isDistanceWithinThreshold(from: location.position, max: 0.5)
            }).isEmpty else { return nil }

            // Only spawn on horizontal surfaces.
            guard location.normal.y > 0.7 else { return nil }

            let clone = entity.clone(recursive: true)
            clone.position = location.position
            clone.orientation *= simd_quatf(angle: .random(in: 0..<(2.0 * Float.pi)), axis: .up)
            return clone
        }
    }
}

internal extension Entity {

    func modifyMaterials(_ closure: (Material) throws -> Material) rethrows {
        try children.forEach { try $0.modifyMaterials(closure) }

        guard var comp = components[ModelComponent.self] as? ModelComponent else { return }
        comp.materials = try comp.materials.map { try closure($0) }
        components[ModelComponent.self] = comp
    }

    func set(_ modifier: CustomMaterial.GeometryModifier) throws {
        try modifyMaterials { try CustomMaterial(from: $0, geometryModifier: modifier) }
    }

    func set(_ shader: CustomMaterial.SurfaceShader) throws {
        try modifyMaterials { try CustomMaterial(from: $0, surfaceShader: shader) }
    }
}
