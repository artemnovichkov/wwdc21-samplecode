/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A System and Component that handle changing the Model dynamically based on how far it is from the camera.
*/

import RealityKit

struct LevelOfDetailComponent: Component {

    static let query = EntityQuery(where: .has(Self.self))

    struct LOD {
        var maxDistance: Float
        var model: ModelComponent
    }
    var levelsOfDetail: [LOD]

    init(_ lods: [LOD]) {
        self.levelsOfDetail = lods.sorted(by: { $0.maxDistance < $1.maxDistance })
    }
}

struct LevelOfDetailSystem: System {

    init(scene: Scene) {}

    func update(context: SceneUpdateContext) {
        guard let camera = context.scene.performQuery(CameraComponent.query).first(where: { _ in true }) else { return }

        for entity in context.scene.performQuery(LevelOfDetailComponent.query) {
            guard let component = entity.components[LevelOfDetailComponent.self] as? LevelOfDetailComponent else { return }
            let distance = entity.distance(from: camera)
            let model: ModelComponent? = component.levelsOfDetail.first(where: { distance < $0.maxDistance })?.model
            if let model = model {
                entity.components.set(model)
            } else {
                entity.components.remove(ModelComponent.self)
            }
        }
    }
}
