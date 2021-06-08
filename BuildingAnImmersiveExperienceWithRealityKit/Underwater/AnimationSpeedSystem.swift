/*
See LICENSE folder for this sample’s licensing information.

Abstract:
System that adjusts animation speed to match movement speed.
*/

import RealityKit

struct AnimationSpeedComponent: RealityKit.Component {
    var animationController: AnimationPlaybackController
}

class AnimationSpeedSystem: RealityKit.System {

    private static let query = EntityQuery(where: .has(AnimationSpeedComponent.self) && .has(MotionComponent.self))

    required init(scene: Scene) { }

    static var dependencies: [SystemDependency] { [.after(MotionSystem.self)] }

    func update(context: SceneUpdateContext) {

        let animators = context.scene.performQuery(Self.query)

        for animator in animators {
            guard let animSpeedComponent = animator.components[AnimationSpeedComponent.self] as? AnimationSpeedComponent,
                  let motion = animator.components[MotionComponent.self] as? MotionComponent,
                  let settings = (animator.components[SettingsComponent.self] as? SettingsComponent)?.settings else { continue }

            let animationController = animSpeedComponent.animationController

            // Make the animation play faster when the fish is swimming fast,
            // slower when it's swimming slowly.
            var animationFramerate = motion.velocity.length
            animationFramerate *= settings.animationScalar

            animationController.speed = animationFramerate
        }
    }
}
