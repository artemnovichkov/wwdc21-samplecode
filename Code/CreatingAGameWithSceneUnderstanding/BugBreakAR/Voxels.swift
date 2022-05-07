/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Voxels
*/

import UIKit
import RealityKit
import Combine

// class for managing world voxels
class Voxels {
    public static let voxelsPerMeter: Float = 20
    public static let voxelSize: Float = 1 / Voxels.voxelsPerMeter

    public var arView: ARView?

    // voxels are either in the voxelPool or in the list of activeVoxels
    private var activeVoxels = [simd_int3: Voxel?]()
    private var voxelPool = [Voxel?]()
    private var newVoxels = [Voxel?]()

    public weak var voxelEntity: VoxelEntity?
    public var voxelMaterial: SimpleMaterial?

    init(gameManager: GameManager) {
        self.arView = gameManager.viewController?.arView
        self.voxelEntity = gameManager.assets?.voxelEntity
        self.voxelMaterial = gameManager.assets?.voxelMaterial
    }

    public func getCoordinates(_ point: SIMD3<Float>) -> simd_int3 {
        if point.x.isNaN { return .zero }
        return simd_int3(
            Int32(roundf(point.x * Voxels.voxelsPerMeter)),
            Int32(roundf(point.y * Voxels.voxelsPerMeter)),
            Int32(roundf(point.z * Voxels.voxelsPerMeter))
        )
    }

    public func getPosition(_ coordinates: simd_int3) -> SIMD3<Float> {
        return SIMD3<Float>(Float(coordinates.x) / Voxels.voxelsPerMeter,
                            Float(coordinates.y) / Voxels.voxelsPerMeter,
                            Float(coordinates.z) / Voxels.voxelsPerMeter)
    }

    @discardableResult
    public func getVoxel(_ coordinates: simd_int3,
                         entranceTime: Double = 0.1,
                         idleTime: Double = 0.5,
                         exitTime: Double = 0.25) -> Voxel {

        // Is there already a Voxel active at that coordinate?
        if let activeVoxel = activeVoxels[coordinates] {
            activeVoxel!.hide()
        }

        // Is there already a Voxel in the pool?
        if !voxelPool.isEmpty {
            let existingVoxel = voxelPool[0]
            existingVoxel!.reinitialize(coordinates,
                                       entranceTime: entranceTime,
                                       idleTime: idleTime,
                                       exitTime: exitTime)
            activeVoxels[existingVoxel!.coordinates] = existingVoxel
            voxelPool.removeFirst()
            newVoxels.append(existingVoxel)
            return existingVoxel!
        } else {
            let newVoxel = Voxel(coordinates,
                                 entranceTime: entranceTime,
                                 idleTime: idleTime,
                                 exitTime: exitTime,
                                 voxels: self)
            activeVoxels[newVoxel.coordinates] = newVoxel
            newVoxels.append(newVoxel)
            return newVoxel
        }
    }

    public func updateVoxelColorsFromFrameBuffer(arView: ARView) {
        guard !newVoxels.isEmpty, let frame = arView.session.currentFrame else { return }

        guard let buffer = ScreenBuffer.makeRGGBuffer(frame.capturedImage) else { return }

        for index in 0..<newVoxels.count {
            guard let scenePoint = arView.project(newVoxels[index]!.anchorEntity.transform.translation) else {
                continue
            }

            let percentages = CGPoint(x: CGFloat(scenePoint.x) / arView.frame.size.width,
                                      y: CGFloat(scenePoint.y) / arView.frame.size.height)
            // Sample the color at this ratio on the screen
            guard let sampledColor = buffer.getColor(at: percentages) else { continue }
            // Get channel values from sample
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            sampledColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            // Premult by the chief gray value in our Voxel texture
            let greyValue = Constants.voxelBaseColorGreyValue
            // The engine handles unclamped values in a very interesting way! Currently, that
            // handling loses its appeal after RGB values of 1.5.
            let upperClampValue: CGFloat = 1.5
            red = clampValue(red * 1 / greyValue, 0, upperClampValue)
            green = clampValue(green * 1 / greyValue, 0, upperClampValue)
            blue = clampValue(blue * 1 / greyValue, 0, upperClampValue)
            let premultColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            newVoxels[index]!.setMaterialColor(premultColor)
            arView.scene.addAnchor(newVoxels[index]!.anchorEntity)
            newVoxels[index]!.show()
        }
        buffer.pointer.deallocate()
        newVoxels.removeAll()
    }

    public func returnToPool(_ voxel: Voxel) {
        // If it wasn't being tracked, it's because it had Physics properties.
        // Toggling the Physics properties on entities seems buggy, so we will
        // just destroy those instead of putting them back in the pool.
        if let voxel = activeVoxels.removeValue(forKey: voxel.coordinates) {
            // Recycle
            voxelPool.append(voxel)
        } else {
            // Destroy
            voxel.modelEntity?.removeFromParent()
            voxel.anchorEntity.removeFromParent()
        }
    }

    public func stopTrackingVoxel(_ voxel: Voxel) {
        activeVoxels.removeValue(forKey: voxel.coordinates)
    }

    public func addRandomVoxelsNearEntity(_ entity: Entity) {
        var yValue: Float = 0
        let range = 4 * Voxels.voxelSize
        for _ in 0..<2 {
            let angle = Float.random(in: 0...Float.pi * 2)
            let xValue = cos(angle) * range
            let zValue = sin(angle) * range
            while yValue < Voxels.voxelSize * 4 {
                let worldspacePosition = entity.convert(position: SIMD3<Float>(xValue,
                                                                               yValue,
                                                                               zValue),
                                                        to: nil)
                let coordinates = getCoordinates(worldspacePosition)
                getVoxel(coordinates)
                yValue += Voxels.voxelSize
            }
        }
    }

    public func removeAllVoxels() {
        activeVoxels.removeAll()
        voxelPool.removeAll()
        newVoxels.removeAll()
        voxelEntity = nil
    }
}
