/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Fish movement component.
*/

import RealityKit

struct MotionComponent: RealityKit.Component {

    struct Force {
        let acceleration: SIMD3<Float>
        let multiplier: Float
        let name: String
    }

    var forces = [Force]()

    var velocity: SIMD3<Float> = SIMD3<Float>.zero
}
