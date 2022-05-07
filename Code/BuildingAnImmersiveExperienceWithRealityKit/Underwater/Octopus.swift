/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages octopus entity.
*/
import RealityKit
import SwiftUI

struct OctopusComponent: RealityKit.Component {

    static let query = EntityQuery(where: .has(OctopusComponent.self))

    weak var settings: Settings?

    enum State {
        case hiding
        case swimming(Double)
    }
    var state: State = .hiding

    let animations: OctopusAnimations
}

struct OctopusAnimations {
    var crawl2Swim: AnimationResource
    var swim2crawl: AnimationResource
    var swim: AnimationResource

    enum Assets: String, AnimationAssetNames {

        case octopus_anim_crawl_to_swim
        case octopus_anim_swim_to_crawl
        case octopus_anim_swim

        var assetName: String { "Octopus/\(rawValue)" }
    }

    init(_ assets: [Assets: AnimationResource]) {
        let animationAssets = assets
        crawl2Swim = animationAssets[.octopus_anim_crawl_to_swim]!
        swim2crawl = animationAssets[.octopus_anim_swim_to_crawl]!
        swim = animationAssets[.octopus_anim_swim]!
    }
}

extension Entity {

    fileprivate func hidingLocationAdded() {
        if !isEnabled, let scene = scene {
            let hidingLocations = scene.performQuery(OctopusHidingLocationComponent.query)
            if let hidingLocation = hidingLocations.first(where: { _ in true }),
                hidingLocations.reduce(0, { count, _ in count + 1 }) >= 2 // There must be another spot to go to.
            {
                isEnabled = true
                transform = hidingLocation.transform
                scaleIn()
            }
        }
    }
}

struct OctopusOptions {

    var fearsCamera: Bool = false

    struct View: SwiftUI.View {

        var options: Binding<OctopusOptions>

        var body: some SwiftUI.View {
            Text("Octopus")
            Toggle("Afraid", isOn: options.fearsCamera)
        }
    }
}

struct OctopusSystem: RealityKit.System {

    init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        let scene = context.scene
        for octopus in scene.performQuery(OctopusComponent.query) {
            guard octopus.isEnabled else { continue }
            guard var component = octopus.components[OctopusComponent] as? OctopusComponent else { continue }
            guard component.settings?.octopus.fearsCamera ?? false else { return }
            switch component.state {
            case .hiding:
                guard let camera = scene.performQuery(CameraComponent.query).first(where: { _ in true }) else { continue }
                let fearDistance: Float = 1.0
                let distanceToCamera = octopus.distance(from: camera)

                guard distanceToCamera < fearDistance else { continue }
                guard let hidingLocation = scene.performQuery(OctopusHidingLocationComponent.query).max(by: {
                    $0.distance(from: camera) < $1.distance(from: camera)
                }) else { continue }

                let distance = octopus.distance(from: hidingLocation)
                guard distance > fearDistance else { continue }

                var duration = Double(distance) * 4

                // Animations
                do {
                    let fixedTime
                        = component.animations.crawl2Swim.definition.duration
                        + component.animations.swim2crawl.definition.duration
                    duration = max(fixedTime, duration)
                    let swimDuration = duration - fixedTime
                    let swimCycleDuration = component.animations.swim.definition.duration
                    let swimCycles = Int(swimDuration / swimCycleDuration)
                    duration = fixedTime + Double(swimCycles) * swimCycleDuration

                    if let animation = try? AnimationResource.sequence(with: [
                        component.animations.crawl2Swim,
                        component.animations.swim.repeat(count: swimCycles),
                        component.animations.swim2crawl
                    ]) {
                        octopus.playAnimation(animation)
                    }
                }

                octopus.move(to: hidingLocation.transform, relativeTo: nil, duration: duration)
                component.state = .swimming(duration)
            case .swimming(var time):
                time -= context.deltaTime
                component.state = time < 0 ? .hiding : .swimming(time)
            }
            octopus.components.set(component)
        }
    }
}

struct OctopusHidingLocationComponent: RealityKit.Component {

    static let query = EntityQuery(where: .has(OctopusHidingLocationComponent.self))

    struct Spawner: ScatteringSpawner {

        weak var scene: RealityKit.Scene?
        let bounds: BoundingBox

        init(scene: RealityKit.Scene, bounds: BoundingBox) {
            self.scene = scene
            self.bounds = bounds
        }

        mutating func randomize() {}

        func attempt(_ location: Scattering.CandidateLocation) -> Entity? {
            guard let scene = self.scene else { return nil }

            // Only spawn on horizontal surfaces.
            guard location.normal.y > 0.7 else { return nil }

            let orientation = simd_quatf(from: .init(0, 1, 0), to: location.normal) *
                .init(angle: Float.random(in: 0..<(2.0 * .pi)), axis: .up)

            // Check that it fits.
            do {
                let center = location.position + orientation.act(bounds.center)
                let corners: [SIMD3<Float>] = [
                    .init(bounds.min.x, bounds.min.y, bounds.min.z),
                    .init(bounds.max.x, bounds.min.y, bounds.min.z),
                    .init(bounds.max.x, bounds.min.y, bounds.max.z),
                    .init(bounds.min.x, bounds.min.y, bounds.max.z)
                ].map { location.position + orientation.act($0) }

                for corner in corners {
                    guard let raycast = scene.raycast(from: center, to: corner).first else { return nil }
                    let meshDistance = corner.distance(from: center)
                    if raycast.distance < 0.9 * meshDistance { return nil } // The model doesn't fit.
                    if raycast.distance > 1.5 * meshDistance { return nil } // The model would be floating.
                }
            }

            let hidingLocation = Entity()
            hidingLocation.position = location.position
            hidingLocation.orientation = orientation
            hidingLocation.components.set(OctopusHidingLocationComponent())
            scene.performQuery(OctopusComponent.query).forEach { $0.hidingLocationAdded() }
            return hidingLocation
        }
    }
}

extension UnderwaterView {

    func setUpOctopus() {

        Entity.loadModelAsync(named: "Octopus/octopus_posed.usdc")
            .zip(
                TextureResource.loadAsync(named: "Octopus/0/Octopus_mask"),
                TextureResource.loadAsync(named: "Octopus/0/Octopus_bc2")
            )
            .zip(Entity.loadModelAsync(OctopusAnimations.Assets.self))
            .sink({ [weak self] data in
            guard let self = self else { return }

            let octopusModel = data.0.0
            let mask = data.0.1
            let bc2 = data.0.2

            let animations = OctopusAnimations(data.1.mapValues { $0.availableAnimations.first! })

            let octopusEntity = Entity()
            octopusModel.scale *= .init(repeating: 4.0)
            octopusModel.generateCollisionShapes(recursive: true)
            octopusModel.position.y -= octopusModel.visualBounds(relativeTo: nil).min.y
            octopusEntity.addChild(octopusModel)
            octopusEntity.components.set(OctopusComponent(
                settings: self.settings,
                animations: animations
            ))
            octopusEntity.components.set(ScaryComponent())
            octopusEntity.isEnabled = false

            let anchor = AnchorEntity(world: SIMD3<Float>())
            anchor.addChild(octopusEntity)
            self.scene.addAnchor(anchor)

            do {
                let surfaceShader = CustomMaterial.SurfaceShader(
                    named: "octopusSurface",
                    in: MetalLibLoader.library
                )
                try octopusModel.modifyMaterials {
                    var mat = try CustomMaterial(from: $0, surfaceShader: surfaceShader)
                    mat.custom.texture = .init(mask)
                    mat.emissiveColor.texture = .init(bc2)
                    return mat
                }
            } catch {
                assertionFailure("Failed to set a custom shader on the octopus \(error)")
            }

            self.scattering.add(Scattering.ScatteringSet(
                spawner: OctopusHidingLocationComponent.Spawner(
                    scene: self.scene,
                    bounds: octopusEntity.visualBounds(relativeTo: nil)
                )
            ))
        }).store(in: &cancellables)
    }
}
