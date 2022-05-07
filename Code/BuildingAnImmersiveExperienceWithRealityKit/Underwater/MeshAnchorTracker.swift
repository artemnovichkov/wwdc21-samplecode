/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages mesh anchors.
*/

import ARKit
import RealityKit
import Combine

struct MeshAnchorTracker {

    var entries: [ARMeshAnchor: Entry] = [:]
    weak var arView: ARView?

    init(arView: ARView) {
        self.arView = arView
    }

    class Entry {
        var entity: AnchorEntity
        private var currentTask: Cancellable?
        var nextTask: LoadRequest<MeshResource>? {
            didSet {
                scheduleNextTask()
            }
        }

        static let material: RealityKit.Material = {
            return OcclusionMaterial(receivesDynamicLighting: true)
        }()

        func scheduleNextTask() {
            guard let task = nextTask else { return }
            guard currentTask == nil else { return }
            self.nextTask = nil
            currentTask = task
                .sink(
                    receiveCompletion: { result in
                    switch result {
                    case .failure(let error): assertionFailure("\(error)")
                    default: return
                    }
                    },
                    receiveValue: { [weak self] mesh in
                    self?.currentTask = nil
                    self?.entity.components[ModelComponent.self] = ModelComponent(
                        mesh: mesh,
                        materials: [Self.material]
                    )
                    self?.scheduleNextTask()
                    }
                )
        }

        init(entity: AnchorEntity) {
            self.entity = entity
        }
    }

    mutating func update(_ anchor: ARMeshAnchor) {
        let tracker: Entry = {
            if let tracker = entries[anchor] { return tracker }
            let entity = AnchorEntity(world: SIMD3<Float>())
            let tracker = Entry(entity: entity)
            entries[anchor] = tracker
            arView?.scene.addAnchor(entity)
            return tracker
        }()

        let entity = tracker.entity

        do {
            entity.transform = .init(matrix: anchor.transform)
            let geom = anchor.geometry
            var desc = MeshDescriptor()
            let posValues = geom.vertices.asSIMD3(ofType: Float.self)
            desc.positions = .init(posValues)
            let normalValues = geom.normals.asSIMD3(ofType: Float.self)
            desc.normals = .init(normalValues)
            do {
                desc.primitives = .polygons(
                    (0..<geom.faces.count).map { _ in UInt8(geom.faces.indexCountPerPrimitive) },
                    (0..<geom.faces.count * geom.faces.indexCountPerPrimitive).map {
                    geom.faces.buffer.contents()
                        .advanced(by: $0 * geom.faces.bytesPerIndex)
                        .assumingMemoryBound(to: UInt32.self).pointee
                    }
                )
            }

            tracker.nextTask = MeshResource.generateAsync(from: [desc])
        }
    }

    mutating func remove(_ anchor: ARMeshAnchor) {
        if let entity = self.entries[anchor] {
            entity.entity.removeFromParent()
            self.entries[anchor] = nil
        }
    }
}

extension ARGeometrySource {

    func asArray<T>(ofType: T.Type) -> [T] {
        dispatchPrecondition(condition: .onQueue(.main))
        assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
        return (0..<self.count).map {
            buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
        }
    }

    // SIMD3 has the same storage as SIMD4.
    func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}
