/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The states for the underwater diver character.
*/

import Foundation
import RealityKit
import Combine
import GameplayKit

class CharacterState: GKState {
    let animationRoot: Entity
    let animationResource: AnimationResource
    let options: Character.Options
    let scene: RealityKit.Scene
    var animationCancellable: Cancellable?
    var animController: AnimationPlaybackController?

    init(jumpAnim: AnimationResource, options: Character.Options, scene: RealityKit.Scene, animationRoot: Entity) {
        self.options = options
        self.scene = scene
        self.animationResource = jumpAnim
        self.animationRoot = animationRoot
    }
}

class IdleState: CharacterState {
    override func didEnter(from previousState: GKState?) {
        var transitionDuration: Float = 0

        if previousState is WalkingState {
            transitionDuration = options.transitionDuration
        }

        animController = animationRoot.playAnimation(
            animationResource.repeat(),
            transitionDuration: TimeInterval(transitionDuration)
        )

    }
}

class WalkingState: CharacterState {
    override func didEnter(from previousState: GKState?) {
        animController = animationRoot.playAnimation(
            animationResource.repeat(),
            transitionDuration: TimeInterval(options.transitionDuration)
        )
    }
}

struct JumpTimings {
    static let jumpMiddleTime = 53.0 / 30.0 // frame / framerate
    static let middleDuration = 1E-6
}

class JumpingStartState: CharacterState {
    override init(jumpAnim: AnimationResource, options: Character.Options, scene: RealityKit.Scene, animationRoot: Entity) {

        guard let anim: AnimationResource = try? .generate(with: AnimationView(
            source: jumpAnim.definition,
            fillMode: .forwards,
            trimDuration: JumpTimings.jumpMiddleTime
        )) else {
            fatalError("Unable to create the Jump start animation")
        }
        super.init(jumpAnim: anim, options: options, scene: scene, animationRoot: animationRoot)
    }

    override func didEnter(from previousState: GKState?) {

        animController = animationRoot.playAnimation(
            animationResource,
            transitionDuration: 0.1 * TimeInterval(options.transitionDuration)
        )

        animationCancellable = scene.subscribe(to: AnimationEvents.PlaybackTerminated.self, on: animationRoot) { [weak self] event in
            print(event)
            guard let self = self, event.playbackController == self.animController else { return }
            self.stateMachine?.enter(JumpingMidState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is JumpingMidState.Type || stateClass is LandingState.Type
    }
}

class JumpingMidState: CharacterState {
    override init(jumpAnim: AnimationResource, options: Character.Options, scene: RealityKit.Scene, animationRoot: Entity) {

        guard let anim: AnimationResource = try? .generate(with: AnimationView(
            source: jumpAnim.definition,
            trimStart: JumpTimings.jumpMiddleTime,
            trimDuration: JumpTimings.middleDuration
        )) else {
            fatalError("Unable to create the Jump start animation")
        }
        super.init(jumpAnim: anim, options: options, scene: scene, animationRoot: animationRoot)
    }

    override func didEnter(from previousState: GKState?) {
        self.animationRoot.playAnimation(animationResource.repeat())
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is LandingState.Type
    }
}

class LandingState: CharacterState {

    override init(jumpAnim: AnimationResource, options: Character.Options, scene: RealityKit.Scene, animationRoot: Entity) {

        guard let anim: AnimationResource = try? .generate(with: AnimationView(
            source: jumpAnim.definition,
            fillMode: .forwards,
            trimStart: JumpTimings.jumpMiddleTime + JumpTimings.middleDuration
        )) else {
            fatalError("Unable to create the Jump start animation")
        }
        super.init(jumpAnim: anim, options: options, scene: scene, animationRoot: animationRoot)
    }

    override func didEnter(from previousState: GKState?) {
        animController = animationRoot.playAnimation(
            animationResource,
            transitionDuration: 0.1 * TimeInterval(options.transitionDuration)
        )

        animationCancellable = scene.subscribe(to: AnimationEvents.PlaybackTerminated.self, on: animationRoot) { [weak self] event in
            guard let self = self, event.playbackController == self.animController else { return }
            self.stateMachine?.enter(IdleState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is IdleState.Type || stateClass is WalkingState.Type
    }
}

