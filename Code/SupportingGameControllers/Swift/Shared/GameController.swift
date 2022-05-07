/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class serves as the game's source of control flow.
*/

import GameController
import GameplayKit
import SceneKit
import CoreHaptics

import os

// Collision Bit Masks
struct Bitmask: OptionSet {
    let rawValue: Int
    static let character = Bitmask(rawValue: 1 << 0) // The main character.
    static let collision = Bitmask(rawValue: 1 << 1) // The ground and walls.
    static let enemy = Bitmask(rawValue: 1 << 2) // The enemies.
    static let trigger = Bitmask(rawValue: 1 << 3) // The box that triggers camera changes and other actions.
    static let collectable = Bitmask(rawValue: 1 << 4) // The collectables (gems and key).
}

#if os( iOS )
    typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate & MenuDelegate
        & PadOverlayDelegate & ButtonOverlayDelegate
#else
    typealias ExtraProtocols = SCNSceneRendererDelegate & SCNPhysicsContactDelegate & MenuDelegate
#endif

enum ParticleKind: Int {
    case collect = 0
    case collectBig
    case keyApparition
    case enemyExplosion
    case unlockDoor
    case totalCount
}

enum AudioSourceKind: Int {
    case collect = 0
    case collectBig
    case unlockDoor
    case hitEnemy
    case totalCount
}
class GameController: NSObject, ExtraProtocols {

    // Global Settings
    static let DefaultCameraTransitionDuration = 1.0
    static let NumberOfFiends = 100
    static let CameraOrientationSensitivity: Float = 0.05

    private var scene: SCNScene?
    private weak var sceneRenderer: SCNSceneRenderer?

    // Overlay
    private var overlay: Overlay?

    // Character
    private var character: Character?

    // Camera and Targets
    private var cameraNode = SCNNode()
    private var lookAtTarget = SCNNode()
    private var lastActiveCamera: SCNNode?
    private var lastActiveCameraFrontDirection = simd_float3.zero
    private var activeCamera: SCNNode?
    private var playingCinematic: Bool = false

    // Triggers
    private var lastTrigger: SCNNode?
    private var firstTriggerDone: Bool = false

    // Enemies
    private var enemy1: SCNNode?
    private var enemy2: SCNNode?

    // Friends
    private var friends = [SCNNode](repeating: SCNNode(), count: NumberOfFiends)
    private var friendsSpeed = [Float](repeating: 0.0, count: NumberOfFiends)
    private var friendCount: Int = 0
    private var friendsAreFree: Bool = false

    // Collected Objects
    private var collectedKeys: Int = 0
    private var collectedGems: Int = 0
    private var keyIsVisible: Bool = false

    // Particles
    private var particleSystems = [[SCNParticleSystem]](repeatElement([SCNParticleSystem()], count: ParticleKind.totalCount.rawValue))

    // Audio Sources
    private var audioSources = [SCNAudioSource](repeatElement(SCNAudioSource(), count: AudioSourceKind.totalCount.rawValue))

    // GameplayKit Scenes
    private var gkScene: GKScene?

    // Game Controller Properties
    private var gamePadCurrent: GCController?
    private var gamePadLeft: GCControllerDirectionPad?
    private var gamePadRight: GCControllerDirectionPad?
    
    // Virtual Onscreen Controller
#if os( iOS )
    private var _virtualController: Any?
    @available(iOS 15.0, *)
    public var virtualController: GCVirtualController? {
      get { return self._virtualController as? GCVirtualController }
      set { self._virtualController = newValue }
    }
#endif

    // Update the delta time.
    private var lastUpdateTime = TimeInterval()

// MARK: -
// MARK: Setup

    func setupGameController() {
        if #available(iOS 14.0, OSX 10.16, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleMouseDidConnect),
                                                   name: NSNotification.Name.GCMouseDidBecomeCurrent, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleMouseDidDisconnect),
                                                   name: NSNotification.Name.GCMouseDidStopBeingCurrent, object: nil)
            if let mouse = GCMouse.mice().first {
                registerMouse(mouse)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleKeyboardDidConnect),
                                               name: NSNotification.Name.GCKeyboardDidConnect, object: nil)
        
        NotificationCenter.default.addObserver(
                self, selector: #selector(self.handleControllerDidConnect),
                name: NSNotification.Name.GCControllerDidBecomeCurrent, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(self.handleControllerDidDisconnect),
            name: NSNotification.Name.GCControllerDidStopBeingCurrent, object: nil)
        
#if os( iOS )
        if #available(iOS 15.0, *) {
            let virtualConfiguration = GCVirtualControllerConfiguration()
            virtualConfiguration.elements = [GCInputLeftThumbstick,
                                             GCInputRightThumbstick,
                                             GCInputButtonA,
                                             GCInputButtonB]
            virtualController = GCVirtualController(configuration: virtualConfiguration)
            
            // Connect to the virtual controller if no physical controllers are available.
            if GCController.controllers().isEmpty {
                virtualController?.connect()
            }
        }
#endif
        
        guard let controller = GCController.controllers().first else {
            return
        }
        registerGameController(controller)
    }

    func setupCharacter() {
        character = Character(scene: scene!)

        // Keep a reference to the physics world for the character because you need it when updating the character's position later.
        character!.physicsWorld = scene!.physicsWorld
        scene!.rootNode.addChildNode(character!.node!)
    }

    func setupPhysics() {
        // Make sure all objects collide with only the character.
        self.scene?.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            node.physicsBody?.collisionBitMask = Int(Bitmask.character.rawValue)
        })
    }

    func setupCollisions() {
        // Load the collision mesh from another scene and merge into main scene.
        let collisionsScene = SCNScene( named: "Art.scnassets/collision.scn" )
        collisionsScene!.rootNode.enumerateChildNodes { (_ child: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) in
            child.opacity = 0.0
            self.scene?.rootNode.addChildNode(child)
        }
    }

    // The follow camera behavior makes the camera follow the character with a constant distance, altitude, and smooth motion.
    func setupFollowCamera(_ cameraNode: SCNNode) {
        // Look at the target.
        let lookAtConstraint = SCNLookAtConstraint(target: self.lookAtTarget)
        lookAtConstraint.influenceFactor = 0.07
        lookAtConstraint.isGimbalLockEnabled = true

        // Set the distance constraints.
        let follow = SCNDistanceConstraint(target: self.lookAtTarget)
        let distance = CGFloat(simd_length(cameraNode.simdPosition))
        follow.minimumDistance = distance
        follow.maximumDistance = distance

        // Configure a constraint to maintain a constant altitude relative to the character.
        let desiredAltitude = abs(cameraNode.simdWorldPosition.y)
        weak var weakSelf = self

        let keepAltitude = SCNTransformConstraint.positionConstraint(inWorldSpace: true, with: {
            (_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                guard let strongSelf = weakSelf else { return position }
                var position = simd_float3(position)
                position.y = strongSelf.character!.baseAltitude + desiredAltitude
                return SCNVector3( position )
            })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearVelocity = 1500.0
        accelerationConstraint.maximumLinearAcceleration = 50.0
        accelerationConstraint.damping = 0.05

        // Use a custom constraint to let the user orbit the camera around the character.
        let transformNode = SCNNode()
        let orientationUpdateConstraint = SCNTransformConstraint(inWorldSpace: true) { (_ node: SCNNode, _ transform: SCNMatrix4) -> SCNMatrix4 in
            guard let strongSelf = weakSelf else { return transform }
            if strongSelf.activeCamera != node {
                return transform
            }

            // Slowly update the acceleration constraint influence factor to smoothly reenable the acceleration.
            accelerationConstraint.influenceFactor = min(1, accelerationConstraint.influenceFactor + 0.01)

            let targetPosition = strongSelf.lookAtTarget.presentation.simdWorldPosition
            let cameraDirection = strongSelf.cameraDirection

            // Disable the acceleration constraint.
            accelerationConstraint.influenceFactor = 0

            let characterWorldUp = strongSelf.character?.node?.presentation.simdWorldUp

            transformNode.transform = transform

            let cameraDirectionFloat3 = strongSelf.cameraDirectionFloat3
            if cameraDirectionFloat3.allZero() {
                if cameraDirection.allZero() {
                    return transform
                }
                let quat = simd_mul(
                    simd_quaternion(GameController.CameraOrientationSensitivity * cameraDirection.x, characterWorldUp!),
                    simd_quaternion(GameController.CameraOrientationSensitivity * cameraDirection.y, transformNode.simdWorldRight)
                )

                transformNode.simdRotate(by: quat, aroundTarget: targetPosition)
            } else {
                let quat1 = simd_quaternion(GameController.CameraOrientationSensitivity * cameraDirectionFloat3.x, transformNode.simdWorldRight)
                let quat2 = simd_quaternion(-GameController.CameraOrientationSensitivity * cameraDirectionFloat3.y, transformNode.simdWorldUp)

                transformNode.simdRotate(by: quat1, aroundTarget: targetPosition)
                transformNode.simdRotate(by: quat2, aroundTarget: targetPosition)
            }

            return transformNode.transform
        }

        cameraNode.constraints = [follow, keepAltitude, accelerationConstraint, orientationUpdateConstraint, lookAtConstraint]
    }

    // For the axis-aligned behavior, look at the character but remain aligned using a specified axis.
    func setupAxisAlignedCamera(_ cameraNode: SCNNode) {
        let distance: Float = simd_length(cameraNode.simdPosition)
        let originalAxisDirection = cameraNode.simdWorldFront

        self.lastActiveCameraFrontDirection = originalAxisDirection

        let symetricAxisDirection = simd_make_float3(-originalAxisDirection.x, originalAxisDirection.y, -originalAxisDirection.z)

        weak var weakSelf = self

        // Define a custom constraint for the axis alignment.
        let axisAlignConstraint = SCNTransformConstraint.positionConstraint(
            inWorldSpace: true, with: {(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
                guard let strongSelf = weakSelf else { return position }
                guard let activeCamera = strongSelf.activeCamera else { return position }

                let axisOrigin = strongSelf.lookAtTarget.presentation.simdWorldPosition
                let referenceFrontDirection =
                    strongSelf.activeCamera == node ? strongSelf.lastActiveCameraFrontDirection : activeCamera.presentation.simdWorldFront

                let axis = simd_dot(originalAxisDirection, referenceFrontDirection) > 0 ? originalAxisDirection: symetricAxisDirection

                let constrainedPosition = axisOrigin - distance * axis
                return SCNVector3(constrainedPosition)
            })

        let accelerationConstraint = SCNAccelerationConstraint()
        accelerationConstraint.maximumLinearAcceleration = 20
        accelerationConstraint.decelerationDistance = 0.5
        accelerationConstraint.damping = 0.05

        // look at constraint
        let lookAtConstraint = SCNLookAtConstraint(target: self.lookAtTarget)
        lookAtConstraint.isGimbalLockEnabled = true // keep horizon horizontal

        cameraNode.constraints = [axisAlignConstraint, lookAtConstraint, accelerationConstraint]
    }

    func setupCameraNode(_ node: SCNNode) {
        guard let cameraName = node.name else { return }

        if cameraName.hasPrefix("camTrav") {
            setupAxisAlignedCamera(node)
        } else if cameraName.hasPrefix("camLookAt") {
            setupFollowCamera(node)
        }
    }

    func setupCamera() {
        // Place the look-at-target node slightly above the character using a constraint.
        weak var weakSelf = self

        self.lookAtTarget.constraints = [ SCNTransformConstraint.positionConstraint(
                                        inWorldSpace: true, with: { (_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 in
            guard let strongSelf = weakSelf else { return position }

            guard var worldPosition = strongSelf.character?.node?.simdWorldPosition else { return position }
            worldPosition.y = strongSelf.character!.baseAltitude + 0.5
            return SCNVector3(worldPosition)
                                        })]

        self.scene?.rootNode.addChildNode(lookAtTarget)

        self.scene?.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if node.camera != nil {
                self.setupCameraNode(node)
            }
        })

        self.cameraNode.camera = SCNCamera()
        self.cameraNode.name = "mainCamera"
        self.cameraNode.camera!.zNear = 0.1
        self.scene!.rootNode.addChildNode(cameraNode)

        setActiveCamera("camLookAt_cameraGame", animationDuration: 0.0)
    }

    func setupEnemies() {
        self.enemy1 = self.scene?.rootNode.childNode(withName: "enemy1", recursively: true)
        self.enemy2 = self.scene?.rootNode.childNode(withName: "enemy2", recursively: true)

        let gkScene = GKScene()

        // Player
        let playerEntity = GKEntity()
        gkScene.addEntity(playerEntity)
        playerEntity.addComponent(GKSCNNodeComponent(node: character!.node))

        let playerComponent = PlayerComponent()
        playerComponent.isAutoMoveNode = false
        playerComponent.character = self.character
        playerEntity.addComponent(playerComponent)
        playerComponent.positionAgentFromNode()

        // Chaser
        let chaserEntity = GKEntity()
        gkScene.addEntity(chaserEntity)
        chaserEntity.addComponent(GKSCNNodeComponent(node: self.enemy1!))
        let chaser = ChaserComponent()
        chaserEntity.addComponent(chaser)
        chaser.player = playerComponent
        chaser.positionAgentFromNode()

        // Scared
        let scaredEntity = GKEntity()
        gkScene.addEntity(scaredEntity)
        scaredEntity.addComponent(GKSCNNodeComponent(node: self.enemy2!))
        let scared = ScaredComponent()
        scaredEntity.addComponent(scared)
        scared.player = playerComponent
        scared.positionAgentFromNode()

        // Animate the enemies by moving them up and down.
        let anim = CABasicAnimation(keyPath: "position")
        anim.fromValue = NSValue(scnVector3: SCNVector3(0, 0.1, 0))
        anim.toValue = NSValue(scnVector3: SCNVector3(0, -0.1, 0))
        anim.isAdditive = true
        anim.repeatCount = .infinity
        anim.autoreverses = true
        anim.duration = 1.2
        anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        self.enemy1!.addAnimation(anim, forKey: "")
        self.enemy2!.addAnimation(anim, forKey: "")

        self.gkScene = gkScene
    }

    func loadParticleSystems(atPath path: String) -> [SCNParticleSystem] {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()

        let fileName = url.lastPathComponent
        let ext: String = url.pathExtension

        if ext == "scnp" {
            return [SCNParticleSystem(named: fileName, inDirectory: directory.relativePath)!]
        } else {
            var particles = [SCNParticleSystem]()
            let scene = SCNScene(named: fileName, inDirectory: directory.relativePath, options: nil)
            scene!.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
                if node.particleSystems != nil {
                    particles += node.particleSystems!
                }
            })
            return particles
        }
    }

    func setupParticleSystem() {
        particleSystems[ParticleKind.collect.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/collect.scnp")
        particleSystems[ParticleKind.collectBig.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/key_apparition.scn")
        particleSystems[ParticleKind.enemyExplosion.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/enemy_explosion.scn")
        particleSystems[ParticleKind.keyApparition.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/key_apparition.scn")
        particleSystems[ParticleKind.unlockDoor.rawValue] = loadParticleSystems(atPath: "Art.scnassets/particles/unlock_door.scn")
    }

    func setupPlatforms() {
        let platformMoveOffset = Float(1.5)
        let platformMoveSpeed = Float(0.5)

        var alternate: Float = 1
        // This could be done in the editor using the action editor.
        scene!.rootNode.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            if node.name == "mobilePlatform" && !node.childNodes.isEmpty {
                node.simdPosition = simd_float3(
                    node.simdPosition.x - (alternate * platformMoveOffset / 2.0), node.simdPosition.y, node.simdPosition.z)

                let moveAction = SCNAction.move(by: SCNVector3(alternate * platformMoveOffset, 0, 0),
                                                duration: TimeInterval(1 / platformMoveSpeed))
                moveAction.timingMode = .easeInEaseOut
                node.runAction(SCNAction.repeatForever(SCNAction.sequence([moveAction, moveAction.reversed()])))

                alternate = -alternate // Alternate movement of platforms to desynchronize them.

                node.enumerateChildNodes({ (_ child: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) in
                    if child.name == "particles_platform" {
                        child.particleSystems?[0].orientationDirection = SCNVector3(0, 1, 0)
                    }
                })
            }
        })
    }

    // MARK: - Camera transitions

    // Transition to the specified camera.
    // This method reparents the main camera under the camera named "cameraNamed"
    // and triggers the animation to smoothly move from the current position to the new position.
    func setActiveCamera(_ cameraName: String, animationDuration duration: CFTimeInterval) {
        guard let camera = scene?.rootNode.childNode(withName: cameraName, recursively: true) else { return }
        if self.activeCamera == camera {
            return
        }

        self.lastActiveCamera = activeCamera
        if activeCamera != nil {
            self.lastActiveCameraFrontDirection = (activeCamera?.presentation.simdWorldFront)!
        }
        self.activeCamera = camera

        // Save old transform in world space.
        let oldTransform: SCNMatrix4 = cameraNode.presentation.worldTransform

        // Reparent the child node.
        camera.addChildNode(cameraNode)

        // Compute the old transform relative to your new parent node.
        let parentTransform = camera.presentation.worldTransform
        let parentInv = SCNMatrix4Invert(parentTransform)

        // With this new transform the position is unchanged in the work space. Reparented the node but didn't move it.
        cameraNode.transform = SCNMatrix4Mult(oldTransform, parentInv)

        // Now animate the transform to smoothly move to the new desired position.
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        cameraNode.transform = SCNMatrix4Identity

        if let cameraTemplate = camera.camera {
            cameraNode.camera!.fieldOfView = cameraTemplate.fieldOfView
            cameraNode.camera!.wantsDepthOfField = cameraTemplate.wantsDepthOfField
            cameraNode.camera!.sensorHeight = cameraTemplate.sensorHeight
            cameraNode.camera!.fStop = cameraTemplate.fStop
            cameraNode.camera!.focusDistance = cameraTemplate.focusDistance
            cameraNode.camera!.bloomIntensity = cameraTemplate.bloomIntensity
            cameraNode.camera!.bloomThreshold = cameraTemplate.bloomThreshold
            cameraNode.camera!.bloomBlurRadius = cameraTemplate.bloomBlurRadius
            cameraNode.camera!.wantsHDR = cameraTemplate.wantsHDR
            cameraNode.camera!.wantsExposureAdaptation = cameraTemplate.wantsExposureAdaptation
            cameraNode.camera!.vignettingPower = cameraTemplate.vignettingPower
            cameraNode.camera!.vignettingIntensity = cameraTemplate.vignettingIntensity
        }
        SCNTransaction.commit()
    }

    func setActiveCamera(_ cameraName: String) {
        setActiveCamera(cameraName, animationDuration: GameController.DefaultCameraTransitionDuration)
    }

    // MARK: - Audio

    func playSound(_ audioName: AudioSourceKind) {
        scene!.rootNode.addAudioPlayer(SCNAudioPlayer(source: audioSources[audioName.rawValue]))
    }

    func setupAudio() {
        // Get an arbitrary node to attach the sounds to.
        let node = scene!.rootNode

        // Ambience
        if let audioSource = SCNAudioSource(named: "audio/ambience.mp3") {
            audioSource.loops = true
            audioSource.volume = 0.8
            audioSource.isPositional = false
            audioSource.shouldStream = true
            node.addAudioPlayer(SCNAudioPlayer(source: audioSource))
        }
        // Volcano
        if let volcanoNode = scene!.rootNode.childNode(withName: "particles_volcanoSmoke_v2", recursively: true) {
            if let audioSource = SCNAudioSource(named: "audio/volcano.mp3") {
                audioSource.loops = true
                audioSource.volume = 5.0
                volcanoNode.addAudioPlayer(SCNAudioPlayer(source: audioSource))
            }
        }

        // Other Sounds
        audioSources[AudioSourceKind.collect.rawValue] = SCNAudioSource(named: "audio/collect.mp3")!
        audioSources[AudioSourceKind.collectBig.rawValue] = SCNAudioSource(named: "audio/collectBig.mp3")!
        audioSources[AudioSourceKind.unlockDoor.rawValue] = SCNAudioSource(named: "audio/unlockTheDoor.m4a")!
        audioSources[AudioSourceKind.hitEnemy.rawValue] = SCNAudioSource(named: "audio/hitEnemy.wav")!

        // Adjust volumes.
        audioSources[AudioSourceKind.unlockDoor.rawValue].isPositional = false
        audioSources[AudioSourceKind.collect.rawValue].isPositional = false
        audioSources[AudioSourceKind.collectBig.rawValue].isPositional = false
        audioSources[AudioSourceKind.hitEnemy.rawValue].isPositional = false

        audioSources[AudioSourceKind.unlockDoor.rawValue].volume = 0.5
        audioSources[AudioSourceKind.collect.rawValue].volume = 4.0
        audioSources[AudioSourceKind.collectBig.rawValue].volume = 4.0
    }

    // MARK: - Init

    init(scnView: SCNView) {
        super.init()
        
        sceneRenderer = scnView
        sceneRenderer!.delegate = self
        
        // Uncomment to show statistics such as fps and timing information.
        //scnView.showsStatistics = true
        
        // Set up overlay.
        overlay = Overlay(size: scnView.bounds.size, controller: self)
        scnView.overlaySKScene = overlay

        // Load the main scene.
        self.scene = SCNScene(named: "Art.scnassets/scene.scn")

        // Set up physics.
        setupPhysics()

        // Set up collisions.
        setupCollisions()

        // Load the character.
        setupCharacter()

        // Set up enemies.
        setupEnemies()

        // Set up friends.
        addFriends(3)

        // Set up platforms.
        setupPlatforms()

        // Set up particles.
        setupParticleSystem()

        // Set up lighting.
        let light = scene!.rootNode.childNode(withName: "DirectLight", recursively: true)!.light
        light!.shadowCascadeCount = 3  // Turn on cascade shadows.
        light!.shadowMapSize = CGSize(width: CGFloat(512), height: CGFloat(512))
        light!.maximumShadowDistance = 20
        light!.shadowCascadeSplittingFactor = 0.5
        
        // Set up camera.
        setupCamera()

        // Set up game controller.
        setupGameController()

        // Configure quality.
        configureRenderingQuality(scnView)

        // Assign the scene to the view.
        sceneRenderer!.scene = self.scene

        // Set up audio.
        setupAudio()

        // Select the point of view to use.
        sceneRenderer!.pointOfView = self.cameraNode

        // Register yourself as the physics contact delegate to receive contact notifications.
        sceneRenderer!.scene!.physicsWorld.contactDelegate = self
    }

    func resetPlayerPosition() {
        character!.queueResetCharacterPosition()
    }

    // MARK: - Cinematic

    func startCinematic() {
        playingCinematic = true
        character!.node!.isPaused = true
    }

    func stopCinematic() {
        playingCinematic = false
        character!.node!.isPaused = false
    }

    // MARK: - Particles

    func particleSystems(with kind: ParticleKind) -> [SCNParticleSystem] {
        return particleSystems[kind.rawValue]
    }

    func addParticles(with kind: ParticleKind, withTransform transform: SCNMatrix4) {
        let particles = particleSystems(with: kind)
        for particleSystem: SCNParticleSystem in particles {
            scene!.addParticleSystem(particleSystem, transform: transform)
        }
    }

    // MARK: - Triggers

    // The game executes triggers when a character enters a box with the collision mask BitmaskTrigger.
    func execTrigger(_ triggerNode: SCNNode, animationDuration duration: CFTimeInterval) {
        // Exec Trigger
        if triggerNode.name!.hasPrefix("trigCam_") {
            let cameraName = (triggerNode.name as NSString?)!.substring(from: 8)
            setActiveCamera(cameraName, animationDuration: duration)
        }
        // Trigger Action
        if triggerNode.name!.hasPrefix("trigAction_") {
            if collectedKeys > 0 {
                let actionName = (triggerNode.name as NSString?)!.substring(from: 11)
                if actionName == "unlockDoor" {
                    unlockDoor()
                }
            }
        }
    }

    func trigger(_ triggerNode: SCNNode) {
        if playingCinematic {
            return
        }
        if lastTrigger != triggerNode {
            lastTrigger = triggerNode

            // The first trigger must not animate (it's the initial camera position).
            execTrigger(triggerNode, animationDuration: firstTriggerDone ? GameController.DefaultCameraTransitionDuration: 0)
            firstTriggerDone = true
        }
    }

    // MARK: - Friends

    func updateFriends(deltaTime: CFTimeInterval) {
        let pathCurve: Float = 0.4

        // Update pandas.
        for idx in 0..<friendCount {
            let friend = friends[idx]

            var pos = friend.simdPosition
            let offsetx = pos.x - sinf(pathCurve * pos.z)

            pos.z += friendsSpeed[idx] * Float(deltaTime) * 0.5
            pos.x = sinf(pathCurve * pos.z) + offsetx

            friend.simdPosition = pos

            ensureNoPenetrationOfIndex(idx)
        }
    }

    func animateFriends() {
        // Animations
        let walkAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_walk.scn")

        SCNTransaction.begin()
        for idx in 0..<friendCount {
            // Unsynchronize.
            if let walk = walkAnimation.copy() as? SCNAnimationPlayer {
                walk.speed = CGFloat(friendsSpeed[idx])
                friends[idx].addAnimationPlayer(walk, forKey: "walk")
                walk.play()
            }
        }
        SCNTransaction.commit()
    }
    
    func addFriends(_ count: Int) {
        var count = count
        if count + friendCount > GameController.NumberOfFiends {
            count = GameController.NumberOfFiends - friendCount
        }

        let friendScene = SCNScene(named: "Art.scnassets/character/max.scn")
        guard let friendModel = friendScene?.rootNode.childNode(withName: "Max_rootNode", recursively: true) else { return }
        friendModel.name = "friend"

        var textures = [String](repeating: "", count: 3)
        textures[0] = "Art.scnassets/character/max_diffuseB.png"
        textures[1] = "Art.scnassets/character/max_diffuseC.png"
        textures[2] = "Art.scnassets/character/max_diffuseD.png"

        var geometries = [SCNGeometry](repeating: SCNGeometry(), count: 3)
        guard let geometryNode = friendModel.childNode(withName: "Max", recursively: true) else { return }

        geometryNode.geometry!.firstMaterial?.diffuse.intensity = 0.5

        if let geometryCopy = geometryNode.geometry!.copy() as? SCNGeometry {
            geometries[0] = geometryCopy
        }
        
        if let geometryCopy = geometryNode.geometry!.copy() as? SCNGeometry {
            geometries[1] = geometryCopy
        }
        
        if let geometryCopy = geometryNode.geometry!.copy() as? SCNGeometry {
            geometries[2] = geometryCopy
        }
        
        geometries[0].firstMaterial = geometries[0].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseB.png"

        geometries[1].firstMaterial = geometries[1].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseC.png"

        geometries[2].firstMaterial = geometries[2].firstMaterial?.copy() as? SCNMaterial
        geometryNode.geometry?.firstMaterial?.diffuse.contents = "Art.scnassets/character/max_diffuseD.png"

        // Remove physics from your friends.
        friendModel.enumerateHierarchy({(_ node: SCNNode, _ _: UnsafeMutablePointer<ObjCBool>) -> Void in
            node.physicsBody = nil
        })

        let friendPosition = simd_make_float3(-5.84, -0.75, 3.354)
        let friendAreaLength: Float = 5.0

        // Group them together.
        var friendsNode: SCNNode? = scene!.rootNode.childNode(withName: "friends", recursively: false)
        if friendsNode == nil {
            friendsNode = SCNNode()
            friendsNode!.name = "friends"
            scene!.rootNode.addChildNode(friendsNode!)
        }

        // Animations
        let idleAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_idle.scn")
        for _ in 0..<count {
            let friend = friendModel.clone()

            // Replace the texture.
            let geometryIndex = Int(arc4random_uniform(UInt32(3)))
            guard let geometryNode = friend.childNode(withName: "Max", recursively: true) else { return }
            geometryNode.geometry = geometries[geometryIndex]

            // Place your friend.
            friend.simdPosition = simd_make_float3(
                friendPosition.x + (1.4 * (Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX)) - 0.5),
                friendPosition.y,
                friendPosition.z - (friendAreaLength * (Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX))))

            // Unsynchronize.
            guard let idle = idleAnimation.copy() as? SCNAnimationPlayer else { continue }
            idle.speed = CGFloat(Float(1.5) + Float(1.5) * Float(arc4random_uniform(UInt32(RAND_MAX))) / Float(RAND_MAX))

            friend.addAnimationPlayer(idle, forKey: "idle")
            idle.play()
            friendsNode?.addChildNode(friend)

            self.friendsSpeed[friendCount] = Float(idle.speed)
            self.friends[friendCount] = friend
            self.friendCount += 1
        }

        for idx in 0..<friendCount {
            ensureNoPenetrationOfIndex(idx)
        }
    }
    
    // Iterate on every friend and move them if they intersect a friend at index i.
    func ensureNoPenetrationOfIndex(_ index: Int) {
        var pos = friends[index].simdPosition

        // Ensure there's no penetration.
        let pandaRadius: Float = 0.15
        let pandaDiameter = pandaRadius * 2.0
        for idx in 0..<friendCount {
            if idx == index {
                continue
            }

            let otherPos = simd_float3(friends[idx].position)
            let vec = otherPos - pos
            let dist = simd_length(vec)
            if dist < pandaDiameter {
                // Penetration
                let pen = pandaDiameter - dist
                pos -= simd_normalize(vec) * pen
            }
        }

        // Ensure they are within the box X[-6.662 -4.8] Z<3.354.
        if friends[index].position.z <= 3.354 {
            pos.x = max(pos.x, -6.662)
            pos.x = min(pos.x, -4.8)
        }
        friends[index].simdPosition = pos
    }

    // MARK: - Game Actions

    func unlockDoor() {
        HapticUtility.playHapticsFile(named: "AHAP/Boing")
        if friendsAreFree {  // Friends are already unlocked.
            return
        }

        startCinematic()  // Pause the scene.

        // Play sound.
        playSound(AudioSourceKind.unlockDoor)

        // Cinematic02
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        SCNTransaction.completionBlock = {() -> Void in
            // Trigger particles.
            let door: SCNNode? = self.scene!.rootNode.childNode(withName: "door", recursively: true)
            let particleDoor: SCNNode? = self.scene!.rootNode.childNode(withName: "particles_door", recursively: true)
            self.addParticles(with: .unlockDoor, withTransform: particleDoor!.worldTransform)

            // Audio
            self.playSound(.collectBig)

            // Add friends.
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.0
            self.addFriends(GameController.NumberOfFiends)
            SCNTransaction.commit()

            // Open the door.
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            SCNTransaction.completionBlock = {() -> Void in
                // Animate characters.
                self.animateFriends()

                // Update the state.
                self.friendsAreFree = true

                // Show the end screen.
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                    Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                    self.showEndScreen()
                })
            }
            door!.opacity = 0.0
            SCNTransaction.commit()
        }

        // Change the point of view.
        setActiveCamera("CameraCinematic02", animationDuration: 1.0)
        SCNTransaction.commit()
    }

    func showKey() {
        keyIsVisible = true

        // Get the key node.
        let key: SCNNode? = scene!.rootNode.childNode(withName: "key", recursively: true)

        // Sound fx
        playSound(AudioSourceKind.collectBig)

        // Particles
        addParticles(with: .keyApparition, withTransform: key!.worldTransform)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.completionBlock = {() -> Void in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                Double(Int64(2.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                self.keyDidAppear()
            })
        }
        key!.opacity = 1.0 // Show the key.
        SCNTransaction.commit()
    }

    func keyDidAppear() {
        execTrigger(lastTrigger!, animationDuration: 0.75) // Revert to previous camera.
        stopCinematic()
    }

    func keyShouldAppear() {
        startCinematic()

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        SCNTransaction.completionBlock = {() -> Void in
            self.showKey()
        }
        setActiveCamera("CameraCinematic01", animationDuration: 3.0)
        SCNTransaction.commit()
    }

    func collect(_ collectable: SCNNode) {
        if collectable.physicsBody != nil {

            // Collect the key.
            if collectable.name == "key" {
                HapticUtility.playHapticsFile(named: "AHAP/Sparkle")
                if !self.keyIsVisible { // The key isn't visible yet.
                    return
                }

                // Play sound.
                playSound(AudioSourceKind.collect)
                self.overlay?.didCollectKey()

                self.collectedKeys += 1
            }

            // Collect the gems.
            else if collectable.name == "CollectableBig" {
                HapticUtility.playHapticsFile(named: "AHAP/Sparkle")
                self.collectedGems += 1

                // Play sound.
                playSound(AudioSourceKind.collect)

                // Update the overlay.
                self.overlay?.collectedGemsCount = self.collectedGems

                if self.collectedGems == 1 {
                    // Collect a gem, and show the key after 1 second.
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
                        Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {() -> Void in
                        self.keyShouldAppear()
                    })
                }
            }

            collectable.physicsBody = nil // The item isn't collectable anymore.

            // Update the particles.
            addParticles(with: .keyApparition, withTransform: collectable.worldTransform)

            collectable.removeFromParentNode()
        }
    }

    // MARK: - Controlling the Character

    func controllerJump(_ controllerJump: Bool) {
        character!.isJump = controllerJump
    }

    func controllerAttack() {
        if !self.character!.isAttacking {
            self.character!.attack()
        }
    }

    var characterDirection: vector_float2 {
        get {
            return character!.direction
        }
        set {
            var direction = newValue
            let length = simd_length(direction)
            if length > 1.0 {
                direction *= 1 / length
            }
            character!.direction = direction
        }
    }
    
    var runModifier: Float {
        get {
            return character!.runModifier
        }
        set {
            character!.runModifier = newValue
        }
    }

    var cameraDirection = vector_float2.zero {
        didSet {
            let length = simd_length(cameraDirection)
            if length > 1.0 {
                cameraDirection *= 1 / length
            }
            cameraDirection.y = 0
        }
    }
    
    var cameraDirectionFloat3 = vector_float3.zero {
        didSet {
            let length = simd_length(cameraDirectionFloat3)
            if length > 1.0 {
                cameraDirectionFloat3 *= 1 / length
            }
        }
    }
    
    var delta: CGPoint = CGPoint.zero
    var keyboard: GCKeyboard? = nil
    
    // MARK: - Update

    static let accelerometerUpdateInterval: Double = 1.0 / 60.0
    static let lowPassKernelWidthInSeconds: Double = 4
    static let shakeDetectionThreshold: Double = 4.0
     
    static let lowPassFilterFactor: Double = accelerometerUpdateInterval / lowPassKernelWidthInSeconds
    static let lowPassFilterFactorVector: simd_double3 = simd_make_double3(lowPassFilterFactor, lowPassFilterFactor, lowPassFilterFactor)
    var lowPassValue: simd_double3 = simd_double3.zero
    var acceleration: simd_double3 = simd_double3.zero
    var deltaAcceleration: simd_double3 = simd_double3.zero
     
    func gcAccelerationToDouble3(_ acceleration: GCAcceleration) -> simd_double3 {
        return simd_make_double3(acceleration.x, acceleration.y, acceleration.z)
    }
    
    func gcRotationRateToDouble3(_ rotation: GCRotationRate) -> simd_double3 {
        return simd_make_double3(rotation.x, rotation.y, rotation.z)
    }
     
    var curController: GCController?
    func startShakeGestureDetection(_ motion: GCMotion) {
        motion.sensorsActive = true
        lowPassValue = gcAccelerationToDouble3(motion.acceleration)
    }
    
    func stopShakeGestureDetection(_ motion: GCMotion) {
        motion.sensorsActive = false
    }
     
    func updateShakeGestureDetection(_ motion: GCMotion) {
        acceleration = gcAccelerationToDouble3(motion.acceleration)
        lowPassValue = simd_mix(lowPassValue, acceleration, GameController.lowPassFilterFactorVector)
        deltaAcceleration = acceleration - lowPassValue
        
        if !(activeCamera?.name == "camLookAt_cameraStart" || activeCamera?.name == "camLookAt_cameraMountain") &&
            simd_length_squared(deltaAcceleration) >= GameController.shakeDetectionThreshold {
            print("Shake event detected")
            controllerAttack()
        }
    }
    
    func updateGyro(_ motion: GCMotion, deltaTime: TimeInterval) {
        let multiplier = 10.0
        let rotationRate = gcRotationRateToDouble3(motion.rotationRate)
        // See https://developer.apple.com/documentation/gamecontroller/gcmotion for info on the game controller's coordinate system.
        let rotationDelta = simd_make_double3(rotationRate.x * deltaTime * multiplier,
                                              -rotationRate.z * deltaTime * multiplier,
                                              0)
        
        if !(activeCamera?.name == "camLookAt_cameraStart" || activeCamera?.name == "camLookAt_cameraMountain") {
            cameraDirectionFloat3 = simd_make_float3(0, 0, 0)
        } else if simd_length_squared(rotationDelta) >= 0.0001 {
            cameraDirectionFloat3 = simd_make_float3(Float(rotationDelta.x),
                                                     Float(rotationDelta.y),
                                                     0)
        } else {
            cameraDirectionFloat3 = simd_make_float3(0, 0, 0)
        }
    }
    
    func pollInput() {
        if let gamePadRight = self.gamePadRight {
            self.cameraDirection = simd_make_float2(-gamePadRight.xAxis.value, gamePadRight.yAxis.value)
        } else {
            self.cameraDirection = simd_make_float2(0)
        }
        
        if let gamePadLeft = self.gamePadLeft {
            self.characterDirection = simd_make_float2(gamePadLeft.xAxis.value, -gamePadLeft.yAxis.value)
        } else {
            self.characterDirection = simd_make_float2(0)
        }
        
        // Virtual Pads
        #if os(iOS)
        if let padNode = overlay?.controlOverlay?.leftPad {
            characterDirection += simd_float2(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
        
        if let padNode = overlay?.controlOverlay?.rightPad {
            cameraDirection += simd_float2( -Float(padNode.stickPosition.x), Float(padNode.stickPosition.y))
        }
        #endif
        
        // Mouse
        let mouseSpeed: CGFloat = 0.02
        self.cameraDirection += simd_make_float2(-Float(self.delta.x * mouseSpeed), Float(self.delta.y * mouseSpeed))
        self.delta = CGPoint.zero
        
        // Keyboard
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            if keyboard.button(forKeyCode: .keyA)?.isPressed ?? false { self.characterDirection.x = -1.0 }
            if keyboard.button(forKeyCode: .keyD)?.isPressed ?? false { self.characterDirection.x = 1.0 }
            if keyboard.button(forKeyCode: .keyW)?.isPressed ?? false { self.characterDirection.y = -1.0 }
            if keyboard.button(forKeyCode: .keyS)?.isPressed ?? false { self.characterDirection.y = 1.0 }
            
            self.runModifier = (keyboard.button(forKeyCode: .leftShift)?.value ?? 0.0) + 1.0
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Compute the delta time.
        if lastUpdateTime == 0 {
            lastUpdateTime = time
        }
        let deltaTime: TimeInterval = time - lastUpdateTime
        lastUpdateTime = time
        
        self.pollInput()
        
        // Update internal current controller.
        if curController != GCController.current {
            if let motion = curController?.motion {
                stopShakeGestureDetection(motion)
            }
            
            curController = GCController.current
            
            if let motion = curController?.motion {
                startShakeGestureDetection(motion)
            }
        }
        
        if let motion = curController?.motion {
            updateShakeGestureDetection(motion)
            updateGyro(motion, deltaTime: deltaTime)
        }
        
        // Update shake gesture recognizer.

        // Update friends.
        if friendsAreFree {
            updateFriends(deltaTime: deltaTime)
        }

        // Stop here if cinematic.
        if playingCinematic == true {
            return
        }

        // Update characters.
        character!.update(atTime: time, with: renderer)

        // Update enemies.
        for entity: GKEntity in gkScene!.entities {
            entity.update(deltaTime: deltaTime)
        }
    }

    // MARK: - contact delegate

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        // Triggers
        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
            trigger(contact.nodeA)
        }
        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.trigger.rawValue {
            trigger(contact.nodeB)
        }

        // Collectables
        if contact.nodeA.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
            collect(contact.nodeA)
        }
        if contact.nodeB.physicsBody!.categoryBitMask == Bitmask.collectable.rawValue {
            collect(contact.nodeB)
        }
    }

    // MARK: - Congratulating the Player

    func showEndScreen() {
        // Play the congrats sound.
        guard let victoryMusic = SCNAudioSource(named: "audio/Music_victory.mp3") else { return }
        victoryMusic.volume = 0.5

        self.scene?.rootNode.addAudioPlayer(SCNAudioPlayer(source: victoryMusic))

        self.overlay?.showEndScreen()
    }

    // MARK: - Configure Rendering Quality

    func turnOffEXRForMAterialProperty(property: SCNMaterialProperty) {
        if var propertyPath = property.contents as? NSString {
            if propertyPath.pathExtension == "exr" {
                propertyPath = ((propertyPath.deletingPathExtension as NSString).appendingPathExtension("png")! as NSString)
                property.contents = propertyPath
            }
        }
    }

    func turnOffEXR() {
        self.turnOffEXRForMAterialProperty(property: scene!.background)
        self.turnOffEXRForMAterialProperty(property: scene!.lightingEnvironment)

        scene?.rootNode.enumerateChildNodes { (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    self.turnOffEXRForMAterialProperty(property: material.selfIllumination)
                }
            }
        }
    }

    func turnOffNormalMaps() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let materials = child.geometry?.materials {
                for material in materials {
                    material.normal.contents = SKColor.black
                }
            }
        })
    }

    func turnOffHDR() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsHDR = false
        })
    }

    func turnOffDepthOfField() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            child.camera?.wantsDepthOfField = false
        })
    }

    func turnOffSoftShadows() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let lightSampleCount = child.light?.shadowSampleCount {
                child.light?.shadowSampleCount = min(lightSampleCount, 1)
            }
        })
    }

    func turnOffPostProcess() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if let light = child.light {
                light.shadowCascadeCount = 0
                light.shadowMapSize = CGSize(width: 1024, height: 1024)
            }
        })
    }

    func turnOffOverlay() {
        sceneRenderer?.overlaySKScene = nil
    }

    func turnOffVertexShaderModifiers() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            if var shaderModifiers = child.geometry?.shaderModifiers {
                shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                child.geometry?.shaderModifiers = shaderModifiers
            }

            if let materials = child.geometry?.materials {
                for material in materials where material.shaderModifiers != nil {
                    var shaderModifiers = material.shaderModifiers!
                    shaderModifiers[SCNShaderModifierEntryPoint.geometry] = nil
                    material.shaderModifiers = shaderModifiers
                }
            }
        })
    }

    func turnOffVegetation() {
        scene?.rootNode.enumerateChildNodes({ (child: SCNNode, _: UnsafeMutablePointer<ObjCBool>) in
            guard let materialName = child.geometry?.firstMaterial?.name as NSString? else { return }
            if materialName.hasPrefix("plante") {
                child.isHidden = true
            }
        })
    }

    func configureRenderingQuality(_ view: SCNView) {
        
#if os( tvOS )
    self.turnOffEXR()  //tvOS doesn't support exr maps.
    // Configure for low-power device(s) only.
    self.turnOffNormalMaps()
    self.turnOffHDR()
    self.turnOffDepthOfField()
    self.turnOffSoftShadows()
    self.turnOffPostProcess()
    self.turnOffOverlay()
    self.turnOffVertexShaderModifiers()
    self.turnOffVegetation()
#endif

    }

    // MARK: - Debug Menu

    func fStopChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.fStop = value
    }

    func focusDistanceChanged(_ value: CGFloat) {
        sceneRenderer!.pointOfView!.camera!.focusDistance = value
    }

    func debugMenuSelectCameraAtIndex(_ index: Int) {
        if index == 0 {
            let key = self.scene?.rootNode .childNode(withName: "key", recursively: true)
            key?.opacity = 1.0
        }
        self.setActiveCamera("CameraDof\(index)")
    }

    // MARK: - Game Controller
    
    @objc
    func handleKeyboardDidConnect(_ notification: Notification) {
        guard let keyboard = notification.object as? GCKeyboard else {
            return
        }
        weak var weakController = self
        
        keyboard.keyboardInput?.button(forKeyCode: .spacebar)?.valueChangedHandler = {
            (_ button: GCDeviceButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerJump(pressed)
        }
    }
    
    @objc
    func handleMouseDidConnect(_ notification: Notification) {
        if #available(iOS 14.0, OSX 10.16, *) {
            guard let mouse = notification.object as? GCMouse else {
                return
            }
            
            unregisterMouse()
            registerMouse(mouse)
            
        }
    }
    
    @objc
    func handleMouseDidDisconnect(_ notification: Notification) {
        unregisterMouse()
    }
    
    func unregisterMouse() {
        delta = CGPoint.zero
    }
    
    func registerMouse(_ mouseDevice: GCMouse) {
        if #available(iOS 14.0, OSX 10.16, *) {
            guard let mouseInput = mouseDevice.mouseInput else {
                return
            }
            
            weak var weakController = self
            mouseInput.mouseMovedHandler = {(_ mouse: GCMouseInput, _ deltaX: Float, _ deltaY: Float) -> Void in
                guard let strongController = weakController else {
                    return
                }
                strongController.delta = CGPoint(x: CGFloat(deltaX), y: CGFloat(deltaY))
            }
            
            mouseInput.leftButton.valueChangedHandler = {
                (_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
                guard let strongController = weakController else {
                    return
                }
                
                strongController.controllerAttack()
            }
            
            mouseInput.scroll.valueChangedHandler = {
                (_ cursor: GCControllerDirectionPad, _ scrollX: Float, _ scrollY: Float) -> Void in
                guard let strongController = weakController else {
                    return
                }
                
                guard let camera = strongController.cameraNode.camera else {
                    return
                }
                camera.fieldOfView = CGFloat.maximum(CGFloat.minimum(120, camera.fieldOfView + CGFloat(scrollY)), 30)
            }
        }
    }

    @objc
    func handleControllerDidConnect(_ notification: Notification) {
        guard let gameController = notification.object as? GCController else {
            return
        }
        unregisterGameController()
        
#if os( iOS )
        if #available(iOS 15.0, *) {
            if gameController != virtualController?.controller {
                virtualController?.disconnect()
            }
        }
#endif
        
        registerGameController(gameController)
        HapticUtility.initHapticsFor(controller: gameController)
        
        self.overlay?.showHints()
    }

    @objc
    func handleControllerDidDisconnect(_ notification: Notification) {
        unregisterGameController()
        
        guard let gameController = notification.object as? GCController else {
            return
        }
        
#if os( iOS )
        if #available(iOS 15.0, *) {
            if GCController.controllers().isEmpty {
                virtualController?.connect()
            }
        }
#endif
        
        HapticUtility.deinitHapticsFor(controller: gameController)
    }

    func registerGameController(_ gameController: GCController) {

        var buttonA: GCControllerButtonInput?
        var buttonB: GCControllerButtonInput?
        var rightTrigger: GCControllerButtonInput?

        weak var weakController = self
        
        if let gamepad = gameController.extendedGamepad {
            self.gamePadLeft = gamepad.leftThumbstick
            self.gamePadRight = gamepad.rightThumbstick
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonB
            rightTrigger = gamepad.rightTrigger
        } else if let gamepad = gameController.microGamepad {
            self.gamePadLeft = gamepad.dpad
            buttonA = gamepad.buttonA
            buttonB = gamepad.buttonX
        }
        
        buttonA?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerJump(pressed)
        }

        buttonB?.valueChangedHandler = {(_ button: GCControllerButtonInput, _ value: Float, _ pressed: Bool) -> Void in
            guard let strongController = weakController else {
                return
            }
            strongController.controllerAttack()
        }
        
        rightTrigger?.pressedChangedHandler = buttonB?.valueChangedHandler

#if os( iOS )
    if gamePadLeft != nil {
            overlay!.hideVirtualPad()
        }
#endif
    }

    func unregisterGameController() {
        gamePadLeft = nil
        gamePadRight = nil
        gamePadCurrent = nil
#if os( iOS )
        overlay!.showVirtualPad()
#endif
    }

#if os( iOS )
    // MARK: - PadOverlayDelegate

    func padOverlayVirtualStickInteractionDidStart(_ padNode: PadOverlay) {
    }

    func padOverlayVirtualStickInteractionDidChange(_ padNode: PadOverlay) {
    }

    func padOverlayVirtualStickInteractionDidEnd(_ padNode: PadOverlay) {
    }

    func willPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(true)
        }
        if button == overlay!.controlOverlay!.buttonB {
            controllerAttack()
        }
    }

    func didPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(false)
        }
    }
#endif
}
