/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vector math utilities.
*/

import RealityKit

extension SIMD3 where Scalar == Float {
    func distance(from other: SIMD3<Float>) -> Float {
        return simd_distance(self, other)
    }

    var printed: String {
        String(format: "(%.8f, %.8f, %.8f)", x, y, z)
    }

    static func spawnPoint(from: SIMD3<Float>, radius: Float) -> SIMD3<Float> {
        from + (radius == 0 ? .zero : SIMD3<Float>.random(in: Float(-radius)..<Float(radius)))
    }

    func angle(other: SIMD3<Float>) -> Float {
        atan2f(other.x - self.x, other.z - self.z) + Float.pi
    }

    var length: Float { return distance(from: .init()) }

    var isNaN: Bool {
        x.isNaN || y.isNaN || z.isNaN
    }

    var normalized: SIMD3<Float> {
        return self / length
    }

    static let up: Self = .init(0, 1, 0)

    func vector(to b: SIMD3<Float>) -> SIMD3<Float> {
        b - self
    }

    var isVertical: Bool {
        dot(self, Self.up) > 0.9
    }
}

extension SIMD2 where Scalar == Float {
    func distance(from other: Self) -> Float {
        return simd_distance(self, other)
    }

    var length: Float { return distance(from: .init()) }
}

extension BoundingBox {

    var volume: Float { extents.x * extents.y * extents.z }
}
