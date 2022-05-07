/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension that calculates entity distances.
*/

import RealityKit

extension Entity {
    func distance(from other: Entity) -> Float {
        transform.translation.distance(from: other.transform.translation)
    }
    
    func distance(from point: SIMD3<Float>) -> Float {
        transform.translation.distance(from: point)
    }

    func isDistanceWithinThreshold(from other: Entity, max: Float) -> Bool {
        isDistanceWithinThreshold(from: transform.translation, max: max)
    }

    func isDistanceWithinThreshold(from point: SIMD3<Float>, max: Float) -> Bool {
        transform.translation.distance(from: point) < max
    }
}
