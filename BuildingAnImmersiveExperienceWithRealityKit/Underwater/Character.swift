/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The underwater diver character.
*/

import Combine
import RealityKit
import SwiftUI
import GameController
import GameplayKit

class Character {

    let stateMachine: GKStateMachine

    enum AnimationAssets: String, AnimationAssetNames {

        case diver_anim_stand_idle
        case diver_anim_walk
        case diver_anim_jumpdown_whole_noroot

        var assetName: String { "Diver/\(rawValue)" }
    }

    let entity: Entity
    let characterModel: Entity
    let animationRoot: Entity

    let height: Float = 0.3
    let animationScale: Float = 1.5 // scale from the rest pose to the animation
    var characterVerticalSpeed: Float = 0

    private var wasGravityActivated = false
    var isGravityActivated: Bool {
        if !wasGravityActivated, let scene = entity.scene {
            let position = entity.position(relativeTo: nil)
            if scene.raycast(from: position, to: position - .up)
                .contains(where: { $0.entity.components.has(SceneUnderstandingComponent.self) }) {
                wasGravityActivated = true
            }
        }
        return wasGravityActivated
    }

    struct Options {

        // independent from the character size
        var gravity: Float = 1.0 // (not yet) in N/Kg

        // relative to the character size
        var jumpSpeed: Float = 1.5
        var walkingSpeed: Float = 0.5
        var transitionDuration: Float = 1.0
        var angularSpeed: Float = 100.0
        var resetTransform: Bool = false
    }

    struct OptionsView: SwiftUI.View {

        var options: Binding<Options>

        var parameters: [ParameterView.Parameter] {
            [
                ("gravity", options.gravity),
                ("jump speed", options.jumpSpeed),
                ("walking speed", options.walkingSpeed),
                ("transition duration", options.transitionDuration),
                ("angular speed", options.angularSpeed)
            ].map { .init(id: $0.0, binding: $0.1) }
        }

        var body: some SwiftUI.View {

            VStack {
                ForEach(parameters) { parameter in
                    ParameterView(parameter: parameter)
                    Spacer()
                }
                Toggle("Reset transform", isOn: options.resetTransform)
            }
        }
    }

    let animations: [AnimationAssets: AnimationResource]

    var lastJump: UInt?
    var controllerJump = false
    var controllerLeftStick: SIMD2<Float> = .init()

    init(
        _ view: UnderwaterView,
        model originalModel: Entity,
        animations: [AnimationAssets: AnimationResource]
    ) {
        self.animations = animations

        let radius: Float
        characterModel = Entity()
        let clone = originalModel.clone(recursive: true)
        self.animationRoot = clone
        let unscaledModel = clone
        let bounds = unscaledModel.visualBounds(relativeTo: nil)
        let scale = height / bounds.extents.y / animationScale
        radius = sqrt(bounds.extents.x * bounds.extents.x + bounds.extents.z * bounds.extents.z) / 2 * scale
        unscaledModel.scale *= .init(repeating: scale)
        unscaledModel.position.y -= bounds.center.y * unscaledModel.scale.y
        characterModel.addChild(unscaledModel)
        characterModel.position.y -= height / 2

        let entity = Entity()
        self.entity = entity
        entity.position.y = height / 2
        entity.addChild(characterModel)
        let anchor = AnchorEntity(
            plane: .horizontal,
            classification: .any,
            minimumBounds: 1.0 * .init(radius, radius)
        )
        anchor.addChild(entity)
        view.scene.addAnchor(anchor)
        entity.components[CharacterControllerComponent.self] = CharacterControllerComponent(
            radius: radius,
            height: height
        )

        self.stateMachine = GKStateMachine(states: [

            IdleState(jumpAnim: animations[.diver_anim_stand_idle]!,
                      options: view.settings.character,
                      scene: view.scene,
                      animationRoot: animationRoot),
            WalkingState(jumpAnim: animations[.diver_anim_walk]!,
                         options: view.settings.character,
                         scene: view.scene,
                         animationRoot: animationRoot),
            JumpingStartState(jumpAnim: animations[.diver_anim_jumpdown_whole_noroot]!,
                              options: view.settings.character,
                              scene: view.scene,
                              animationRoot: animationRoot),
            JumpingMidState(jumpAnim: animations[.diver_anim_jumpdown_whole_noroot]!,
                            options: view.settings.character,
                            scene: view.scene,
                            animationRoot: animationRoot),
            LandingState(jumpAnim: animations[.diver_anim_jumpdown_whole_noroot]!,
                         options: view.settings.character,
                         scene: view.scene,
                         animationRoot: animationRoot)
        ])

        stateMachine.enter(IdleState.self)

        // Game controller (as an alternative to on-screen controls)
        do {
            if let controller = GCController.current {
                setup(controller)
            }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleControllerDidConnect),
                name: .GCControllerDidBecomeCurrent,
                object: nil
            )
        }

        let originalPosition = entity.position(relativeTo: nil)
        setupUpdate(view: view, originalPosition: originalPosition)
    }

    private func setupUpdate(view: UnderwaterView, originalPosition: SIMD3<Float>) {
        view.scene.subscribe(to: SceneEvents.Update.self, { [weak view, weak self] event in
            guard let view = view, let self = self else { return }

            let options = view.settings.character

            if options.resetTransform {
                self.entity.setPosition(originalPosition, relativeTo: nil)
            }

            let deltaTime = Float(event.deltaTime)
            let speed = self.updateSpeed(gameState: view.gameState,
                                         cameraTransform: view.cameraTransform,
                                         deltaTime: deltaTime,
                                         options: options)

            self.updateState(forSpeed: speed, options: options, deltaTime: deltaTime)

            // Don't slide across the floor while landing
            if self.stateMachine.currentState is LandingState {
                return
            }

            var tryingToJump = self.controllerJump
            self.controllerJump = false
            if self.lastJump != view.gameState.jumpIndex {
                self.lastJump = view.gameState.jumpIndex
                tryingToJump = true
            }
            if self.isGravityActivated {
                if self.entity.characterControllerState?.isOnGround == true {
                    self.characterVerticalSpeed = tryingToJump ? options.jumpSpeed * self.height : 0
                    switch self.stateMachine.currentState {
                    case is JumpingStartState, is JumpingMidState:
                        self.stateMachine.enter(LandingState.self)
                    default:
                        break
                    }
                    if tryingToJump {
                        self.stateMachine.enter(JumpingStartState.self)
                    }
                }
                self.characterVerticalSpeed += -options.gravity * self.height * deltaTime
            }
            let forces = SIMD3<Float>(
                speed.x * self.height * options.walkingSpeed,
                self.characterVerticalSpeed,
                speed.y * self.height * options.walkingSpeed
            )
            self.entity.moveCharacter(
                by: forces * deltaTime,
                deltaTime: deltaTime,
                relativeTo: nil
            )
        }).store(in: &view.cancellables)
    }

    private func updateSpeed(gameState: GameState, cameraTransform: Transform, deltaTime: Float, options: Options) -> SIMD2<Float> {

        // Speed in screen space
        let inputSpeed: SIMD2<Float> = {
            let controls = (gameState.characterSpeed ?? .init()) + self.controllerLeftStick
            if controls.length > 1 {
                return controls / controls.length
            } else {
                return controls
            }
        }()

        // Speed world space (oriented based on the camera)
        let speed: SIMD2<Float> = {
            let rotation = cameraTransform.rotation
            func projected(_ v: SIMD3<Float>) -> SIMD2<Float>? {
                let rotated = rotation.act(v)
                let rotated2D = SIMD2<Float>(rotated.x, rotated.z)
                let length = rotated2D.length
                guard length > 0 else { return nil }
                return rotated2D / length
            }
            guard let up = projected(.init(0, 0, 1)), let right = projected(.init(1, 0, 0)) else { return .init() }
            return inputSpeed.y * up + inputSpeed.x * right
        }()

        return speed
    }

    private func updateState(forSpeed speed: SIMD2<Float>, options: Options, deltaTime: Float) {
        let speedLength = speed.length
        if speedLength > 0 {
            // updating the rotation of the model
            do {
                let angle = atan2(-1 * speed.y, speed.x) + .pi / 2
                let angleBlend: Float = pow(0.9, options.angularSpeed * deltaTime * speedLength)
                characterModel.transform.rotation = simd_slerp(
                    .init(angle: angle, axis: .init(0, 1, 0)),
                    self.characterModel.transform.rotation,
                    angleBlend
                )
            }
            
            switch stateMachine.currentState {
            case is IdleState:
                stateMachine.enter(WalkingState.self)
            default:
                break
            }
        } else {
            switch stateMachine.currentState {
            case is WalkingState:
                stateMachine.enter(IdleState.self)
            default:
                break
            }
        }

        (stateMachine.currentState as? WalkingState)?.animController?.speed = speedLength
    }

    @objc
    func handleControllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        setup(controller)
    }

    func setup(_ controller: GCController) {
        guard let gamePad = controller.extendedGamepad else { return }
        gamePad.buttonA.pressedChangedHandler = { [weak self] pad, _, pressed in
            if pressed { self?.controllerJump = true }
        }
        gamePad.leftThumbstick.valueChangedHandler = { [weak self] pad, stickX, stickY in
            self?.controllerLeftStick = .init(stickX, -stickY)
        }
    }
}

extension UnderwaterView {

    func setupDiverCharacter() {
        Entity.loadModelAsync(Character.AnimationAssets.self).sink(receiveValue: {
            let idle = $0[.diver_anim_stand_idle]!
            self.character = Character(
                self,
                model: idle,
                animations: $0.mapValues { $0.availableAnimations.first! }
            )
        }).store(in: &cancellables)
    }
}

protocol AnimationAssetNames: Hashable, CaseIterable {
    var assetName: String { get }
}

extension Entity {

    static func loadAsync<T>(
        _ type: T.Type
    ) -> Publishers.Map<Publishers.Collect<Publishers.MergeMany<Publishers.Map<LoadRequest<Entity>, (T, Entity)>>>, [T: Entity]>
        where T: AnimationAssetNames {
        let anims = type.allCases.map { anim in Entity.loadAsync(named: anim.assetName).map { (anim, $0) } }
        return Publishers.MergeMany(anims).collect().map { [T: Entity](uniqueKeysWithValues: $0) }
    }

    static func loadModelAsync<T>(
        _ type: T.Type
    ) -> Publishers.Map<Publishers.Collect<Publishers.MergeMany<Publishers.Map<LoadRequest<ModelEntity>, (T, ModelEntity)>>>, [T: ModelEntity]>
        where T: AnimationAssetNames {
        let anims = type.allCases.map { anim in Entity.loadModelAsync(named: anim.assetName).map { (anim, $0) } }
        return Publishers.MergeMany(anims).collect().map { [T: ModelEntity](uniqueKeysWithValues: $0) }
    }
}
