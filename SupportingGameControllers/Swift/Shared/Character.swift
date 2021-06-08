/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class manages the main character of the game, including its animations, sounds, and direction.
*/

import Foundation
import SceneKit
import GameController
import CoreHaptics
import simd

// Returns the plane / ray intersection distance from the ray origin.
func planeIntersect(planeNormal: simd_float3, planeDist: Float, rayOrigin: simd_float3, rayDirection: simd_float3) -> Float {
    return (planeDist - simd_dot(planeNormal, rayOrigin)) / simd_dot(planeNormal, rayDirection)
}

#if os(macOS)
    typealias ControllerColor = NSColor
#else
    typealias ControllerColor = UIColor
#endif

class Character: NSObject {
    
    static private let speedFactor: CGFloat = 2.0
    static private let stepsCount = 10

    static private let initialPosition = simd_float3(0.1, -0.2, 0)
    
    // Character Constants
    static private let gravity = Float(0.004)
    static private let jumpImpulse = Float(0.1)
    static private let minAltitude = Float(-10)
    static private let enableFootStepSound = true
    static private let collisionMargin = Float(0.04)
    static private let modelOffset = simd_float3(0, -collisionMargin, 0)
    static private let collisionMeshBitMask = 8
    
    enum GroundType: Int {
        case grass
        case rock
        case water
        case inTheAir
        case count
    }
    
    // Character Handle Properties
    private var characterNode: SCNNode! // top-level node
    private var characterOrientation: SCNNode! // the node to rotate to orient the character
    private var model: SCNNode! // the model loaded from the character file
    
    // Physics Properties
    private var characterCollisionShape: SCNPhysicsShape?
    private var collisionShapeOffsetFromModel = simd_float3.zero
    private var downwardAcceleration: Float = 0
    
    // Jump Properties
    private var controllerJump: Bool = false
    private var jumpState: Int = 0
    private var groundNode: SCNNode?
    private var groundNodeLastPosition = simd_float3.zero
    var baseAltitude: Float = 0
    private var targetAltitude: Float = 0
    
    // Avoid playing the step sound too often.
    private var lastStepFrame: Int = 0
    private var frameCounter: Int = 0
    
    // Direction Properties
    private var previousUpdateTime: TimeInterval = 0
    private var controllerDirection = simd_float3.zero
    
    // Character States
    private var attackCount: Int = 0
    private var lastHitTime: TimeInterval = 0
    
    private var shouldResetCharacterPosition = false
    
    // Particle Systems Properties
    private var jumpDustParticle: SCNParticleSystem!
    private var fireEmitter: SCNParticleSystem!
    private var smokeEmitter: SCNParticleSystem!
    private var whiteSmokeEmitter: SCNParticleSystem!
    private var spinParticle: SCNParticleSystem!
    private var spinCircleParticle: SCNParticleSystem!

    private var spinParticleAttach: SCNNode!

    private var fireEmitterBirthRate: CGFloat = 0.0
    private var smokeEmitterBirthRate: CGFloat = 0.0
    private var whiteSmokeEmitterBirthRate: CGFloat = 0.0

    // Sound Effects Properties
    private var aahSound: SCNAudioSource!
    private var ouchSound: SCNAudioSource!
    private var hitSound: SCNAudioSource!
    private var hitEnemySound: SCNAudioSource!
    private var explodeEnemySound: SCNAudioSource!
    private var catchFireSound: SCNAudioSource!
    private var jumpSound: SCNAudioSource!
    private var attackSound: SCNAudioSource!
    private var steps = [SCNAudioSource](repeating: SCNAudioSource(), count: Character.stepsCount )
    
    private var lavaHapticsPlayers: [CHHapticPatternPlayer] = []
    
    private(set) var offsetedMark: SCNNode?
    
    // Actions Properties
    var isJump: Bool = false
    var direction = simd_float2()
    var physicsWorld: SCNPhysicsWorld?
    
    var runModifier: Float = 1.0
    
    // MARK: - Initialization
    init(scene: SCNScene) {
        super.init()

        loadCharacter()
        loadParticles()
        loadSounds()
        loadAnimations()
    }

    private func loadCharacter() {
        // Load character from an external file.
        let scene = SCNScene( named: "Art.scnassets/character/max.scn")!
        model = scene.rootNode.childNode( withName: "Max_rootNode", recursively: true)
        model.simdPosition = Character.modelOffset

        /* Set up character hierarchy.
         character
         |_orientationNode
         |_model
         */
        characterNode = SCNNode()
        characterNode.name = "character"
        characterNode.simdPosition = Character.initialPosition

        characterOrientation = SCNNode()
        characterNode.addChildNode(characterOrientation)
        characterOrientation.addChildNode(model)

        let collider = model.childNode(withName: "collider", recursively: true)!
        collider.physicsBody?.collisionBitMask = Int(([ .enemy, .trigger, .collectable ] as Bitmask).rawValue)

        // Set up collision shape.
        let (min, max) = model.boundingBox
        let collisionCapsuleRadius = CGFloat(max.x - min.x) * CGFloat(0.4)
        let collisionCapsuleHeight = CGFloat(max.y - min.y)

        let collisionGeometry = SCNCapsule(capRadius: collisionCapsuleRadius, height: collisionCapsuleHeight)
        characterCollisionShape = SCNPhysicsShape(geometry: collisionGeometry, options: [.collisionMargin: Character.collisionMargin])
        collisionShapeOffsetFromModel = simd_float3(0, Float(collisionCapsuleHeight) * 0.51, 0.0)
    }

    private func loadParticles() {
        var particleScene = SCNScene( named: "Art.scnassets/character/jump_dust.scn")!
        let particleNode = particleScene.rootNode.childNode(withName: "particle", recursively: true)!
        jumpDustParticle = particleNode.particleSystems!.first!

        particleScene = SCNScene( named: "Art.scnassets/particles/burn.scn")!
        let burnParticleNode = particleScene.rootNode.childNode(withName: "particles", recursively: true)!

        let particleEmitter = SCNNode()
        characterOrientation.addChildNode(particleEmitter)

        fireEmitter = burnParticleNode.childNode(withName: "fire", recursively: true)!.particleSystems![0]
        fireEmitterBirthRate = fireEmitter.birthRate
        fireEmitter.birthRate = 0

        smokeEmitter = burnParticleNode.childNode(withName: "smoke", recursively: true)!.particleSystems![0]
        smokeEmitterBirthRate = smokeEmitter.birthRate
        smokeEmitter.birthRate = 0

        whiteSmokeEmitter = burnParticleNode.childNode(withName: "whiteSmoke", recursively: true)!.particleSystems![0]
        whiteSmokeEmitterBirthRate = whiteSmokeEmitter.birthRate
        whiteSmokeEmitter.birthRate = 0

        particleScene = SCNScene(named: "Art.scnassets/particles/particles_spin.scn")!
        spinParticle = (particleScene.rootNode.childNode(withName: "particles_spin", recursively: true)?.particleSystems?.first!)!
        spinCircleParticle = (particleScene.rootNode.childNode(withName: "particles_spin_circle", recursively: true)?.particleSystems?.first!)!

        particleEmitter.position = SCNVector3Make(0, 0.05, 0)
        particleEmitter.addParticleSystem(fireEmitter)
        particleEmitter.addParticleSystem(smokeEmitter)
        particleEmitter.addParticleSystem(whiteSmokeEmitter)

        spinParticleAttach = model.childNode(withName: "particles_spin_circle", recursively: true)
    }

    private func loadSounds() {
        lavaHapticsPlayers = HapticUtility.patternPlayersForHapticsFile(named: "AHAP/InLava")
            
        aahSound = SCNAudioSource( named: "audio/aah_extinction.mp3")!
        aahSound.volume = 1.0
        aahSound.isPositional = false
        aahSound.load()

        catchFireSound = SCNAudioSource(named: "audio/panda_catch_fire.mp3")!
        catchFireSound.volume = 5.0
        catchFireSound.isPositional = false
        catchFireSound.load()

        ouchSound = SCNAudioSource(named: "audio/ouch_firehit.mp3")!
        ouchSound.volume = 2.0
        ouchSound.isPositional = false
        ouchSound.load()

        hitSound = SCNAudioSource(named: "audio/hit.mp3")!
        hitSound.volume = 2.0
        hitSound.isPositional = false
        hitSound.load()

        hitEnemySound = SCNAudioSource(named: "audio/Explosion1.m4a")!
        hitEnemySound.volume = 2.0
        hitEnemySound.isPositional = false
        hitEnemySound.load()

        explodeEnemySound = SCNAudioSource(named: "audio/Explosion2.m4a")!
        explodeEnemySound.volume = 2.0
        explodeEnemySound.isPositional = false
        explodeEnemySound.load()

        jumpSound = SCNAudioSource(named: "audio/jump.m4a")!
        jumpSound.volume = 0.2
        jumpSound.isPositional = false
        jumpSound.load()

        attackSound = SCNAudioSource(named: "audio/attack.mp3")!
        attackSound.volume = 1.0
        attackSound.isPositional = false
        attackSound.load()

        for idx in 0..<Character.stepsCount {
            steps[idx] = SCNAudioSource(named: "audio/Step_rock_0\(UInt32(idx)).mp3")!
            steps[idx].volume = 0.5
            steps[idx].isPositional = false
            steps[idx].load()
        }
    }

    private func loadAnimations() {
        let idleAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_idle.scn")
        model.addAnimationPlayer(idleAnimation, forKey: "idle")
        idleAnimation.play()

        let walkAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_walk.scn")
        walkAnimation.speed = Character.speedFactor
        walkAnimation.stop()

        if Character.enableFootStepSound {
            walkAnimation.animation.animationEvents = [
                SCNAnimationEvent(keyTime: 0.1, block: { _, _, _ in self.playFootStep() }),
                SCNAnimationEvent(keyTime: 0.6, block: { _, _, _ in self.playFootStep() })
            ]
        }
        model.addAnimationPlayer(walkAnimation, forKey: "walk")

        let jumpAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_jump.scn")
        jumpAnimation.animation.isRemovedOnCompletion = false
        jumpAnimation.stop()
        jumpAnimation.animation.animationEvents = [SCNAnimationEvent(keyTime: 0, block: { _, _, _ in self.playJumpSound() })]
        model.addAnimationPlayer(jumpAnimation, forKey: "jump")

        let spinAnimation = Character.loadAnimation(fromSceneNamed: "Art.scnassets/character/max_spin.scn")
        spinAnimation.animation.isRemovedOnCompletion = false
        spinAnimation.speed = 1.5
        spinAnimation.stop()
        spinAnimation.animation.animationEvents = [SCNAnimationEvent(keyTime: 0, block: { _, _, _ in self.playAttackSound() })]
        model!.addAnimationPlayer(spinAnimation, forKey: "spin")
    }

    var node: SCNNode! {
        return characterNode
    }
        
    func queueResetCharacterPosition() {
        shouldResetCharacterPosition = true
    }
    
    // MARK: Audio
    
    func playFootStep() {
        if groundNode != nil && isWalking { // Character is in the air, so there's no sound to play.
            // Play a random step sound.
            let randSnd: Int = Int(Float(arc4random()) / Float(RAND_MAX) * Float(Character.stepsCount))
            let stepSoundIndex: Int = min(Character.stepsCount - 1, randSnd)
            characterNode.runAction(SCNAction.playAudio( steps[stepSoundIndex], waitForCompletion: false))
        }
    }
    
    func playJumpSound() {
        characterNode!.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
    }
    
    func playAttackSound() {
        characterNode!.runAction(SCNAction.playAudio(attackSound, waitForCompletion: false))
    }
    
    let second: Double = 1_000_000
    func modifyLavaLightFlash() {
        var elapsedTime: Double = 0
        var lastUpdate = DispatchTime.now()
        let prevColor = GCController.current?.light?.color
        while playingLavaLightFlash {
            let currentTime = DispatchTime.now()
            elapsedTime += (Double(currentTime.uptimeNanoseconds - lastUpdate.uptimeNanoseconds) / Double(1_000_000_000))

            let hue = min(1, (fabsf(sinf(Float(elapsedTime * 8.5))) * 0.1) + 0.018)
            let saturation: Float = 1
            let value: Float = 1
            let rgb = ControllerColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(value), alpha: 1.0)
            
            var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
            rgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            GCController.current?.light?.color = GCColor(red: Float(red), green: Float(green), blue: Float(blue))

            usleep(useconds_t(0.015 * second)) // Sleep for 15 ms.
            lastUpdate = currentTime
        }
        
        guard let color = prevColor else {
            return
        }
        
        GCController.current?.light?.color = color
    }
    
    var lightQueue = DispatchQueue(label: "lavaLightFlash", qos: .default)
    var playingLavaLightFlash: Bool = false
    func playLavaLightFlash() {
        if playingLavaLightFlash {
            return
        }

        self.playingLavaLightFlash = true

        lightQueue.async {
            self.modifyLavaLightFlash()
        }
    }
    
    var curController: GCController?
    func playLavaHaptics() {
        
        if GCController.current != curController {
            curController = GCController.current
            lavaHapticsPlayers = HapticUtility.patternPlayersForHapticsFile(named: "AHAP/InLava")
        }
        
        do {
            playLavaLightFlash()

            for player in lavaHapticsPlayers {
                try player.start(atTime: CHHapticTimeImmediate)
            }
            
            let lavaHapticsLoopDeadline: DispatchTime = DispatchTime.now() + 1.5
            DispatchQueue.main.asyncAfter(deadline: lavaHapticsLoopDeadline) {
                if self.isBurning {
                    self.playLavaHaptics()
                }
            }
        } catch {
            
        }
    }
    
    func stopLavaHaptics() {
        do {
            playingLavaLightFlash = false

            for player in lavaHapticsPlayers {
                try player.stop(atTime: CHHapticTimeImmediate)
            }
        } catch {
            
        }
    }
    
    var isBurning: Bool = false {
        didSet {
            if isBurning == oldValue {
                return
            }
            // Walk faster when burning.
            let oldSpeed = walkSpeed
            walkSpeed = oldSpeed
            
            if isBurning {
                playLavaHaptics()
                model.runAction(SCNAction.sequence([
                    SCNAction.playAudio(catchFireSound, waitForCompletion: false),
                    SCNAction.playAudio(ouchSound, waitForCompletion: false),
                    SCNAction.repeatForever(SCNAction.sequence([
                        SCNAction.fadeOpacity(to: 0.01, duration: 0.1),
                        SCNAction.fadeOpacity(to: 1.0, duration: 0.1)
                        ]))
                    ]))
                whiteSmokeEmitter.birthRate = 0
                fireEmitter.birthRate = fireEmitterBirthRate
                smokeEmitter.birthRate = smokeEmitterBirthRate
            } else {
                stopLavaHaptics()
                model.removeAllAudioPlayers()
                model.removeAllActions()
                model.opacity = 1.0
                model.runAction(SCNAction.playAudio(aahSound, waitForCompletion: false))
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.0
                whiteSmokeEmitter.birthRate = whiteSmokeEmitterBirthRate
                fireEmitter.birthRate = 0
                smokeEmitter.birthRate = 0
                SCNTransaction.commit()
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 5.0
                whiteSmokeEmitter.birthRate = 0
                SCNTransaction.commit()
            }
        }
    }
    
    // MARK: - Controlling the character
    
    private var directionAngle: CGFloat = 0.0 {
        didSet {
            characterOrientation.runAction(
                SCNAction.rotateTo(x: 0.0, y: directionAngle, z: 0.0, duration: 0.1, usesShortestUnitArc: true))
        }
    }
    
    func update(atTime time: TimeInterval, with renderer: SCNSceneRenderer) {
        frameCounter += 1
        
        if shouldResetCharacterPosition {
            shouldResetCharacterPosition = false
            resetCharacterPosition()
            return
        }
        
        var characterVelocity = simd_float3.zero
        
        // Set up the ground move.
        var groundMove = simd_float3.zero
        
        // Check if the ground moved.
        if groundNode != nil {
            let groundPosition = groundNode!.simdWorldPosition
            groundMove = groundPosition - groundNodeLastPosition
        }
        
        characterVelocity = simd_float3(groundMove.x, 0, groundMove.z)
        
        let direction = characterDirection(withPointOfView: renderer.pointOfView)
        
        if previousUpdateTime == 0.0 {
            previousUpdateTime = time
        }
        
        let deltaTime = time - previousUpdateTime
        let characterSpeed = CGFloat(deltaTime) * Character.speedFactor * walkSpeed
        let virtualFrameCount = Int(deltaTime / (1 / 60.0))
        previousUpdateTime = time
        
        // Move the character.
        if !direction.allZero() {
            characterVelocity = direction * Float(characterSpeed)
            walkSpeed = CGFloat(runModifier * simd_length(direction))
            
            // Set the angle of direction.
            directionAngle = CGFloat(atan2f(direction.x, direction.z))
            
            isWalking = true
        } else {
            isWalking = false
        }
        
        // Put the character on the ground.
        let upDirection = simd_float3(0, 1, 0)
        var wPosition = characterNode.simdWorldPosition
        // Apply the gravity.
        downwardAcceleration -= Character.gravity
        wPosition.y += downwardAcceleration
        let hitRange = Float(0.2)
        var point0 = wPosition
        var point1 = wPosition
        point0.y = wPosition.y + upDirection.y * hitRange
        point1.y = wPosition.y - upDirection.y * hitRange
        
        let options: [String: Any] = [
            SCNHitTestOption.backFaceCulling.rawValue: false,
            SCNHitTestOption.categoryBitMask.rawValue: Character.collisionMeshBitMask,
            SCNHitTestOption.ignoreHiddenNodes.rawValue: false]
        
        let hitFrom = SCNVector3(point0)
        let hitTo = SCNVector3(point1)
        let hitResult = renderer.scene!.rootNode.hitTestWithSegment(from: hitFrom, to: hitTo, options: options).first
        
        let wasTouchingTheGroup = groundNode != nil
        groundNode = nil
        var touchesTheGround = false
        let wasBurning = isBurning
        
        if let hit = hitResult {
            let ground = simd_float3(hit.worldCoordinates)
            if wPosition.y <= ground.y + Character.collisionMargin {
                wPosition.y = ground.y + Character.collisionMargin
                if downwardAcceleration < 0 {
                   downwardAcceleration = 0
                }
                groundNode = hit.node
                touchesTheGround = true
                
                // Check if the character is touching lava.
                isBurning = groundNode?.name == "COLL_lava"
            }
        } else {
            if wPosition.y < Character.minAltitude {
                wPosition.y = Character.minAltitude
                // Reset the character position.
                queueResetCharacterPosition()
            }
        }
        
        groundNodeLastPosition = (groundNode != nil) ? groundNode!.simdWorldPosition: simd_float3.zero
        
        // Jump the character. -------------------------------------------------------------
        if jumpState == 0 {
            if isJump && touchesTheGround {
                
                HapticUtility.playHapticsFile(named: "AHAP/JumpUp")
                
                downwardAcceleration += Character.jumpImpulse
                jumpState = 1
                
                model.animationPlayer(forKey: "jump")?.play()
            }
        } else {
            if jumpState == 1 && !isJump {
                jumpState = 2
            }
            
            if downwardAcceleration > 0 {
                for _ in 0..<virtualFrameCount {
                    downwardAcceleration *= jumpState == 1 ? 0.99: 0.2
                }
            }
            
            if touchesTheGround {
                if !wasTouchingTheGroup {
                    model.animationPlayer(forKey: "jump")?.stop(withBlendOutDuration: 0.1)
                    
                    // Trigger jump particles if the character is not touching lava.
                    if isBurning {
                        model.childNode(withName: "dustEmitter", recursively: true)?.addParticleSystem(jumpDustParticle)
                    } else {
                        // Jump in lava again.
                        if wasBurning {
                            playLavaHaptics()
                            characterNode.runAction(SCNAction.sequence([
                                SCNAction.playAudio(catchFireSound, waitForCompletion: false),
                                SCNAction.playAudio(ouchSound, waitForCompletion: false)
                                ]))
                        }
                    }
                }
                
                if !isJump {
                    jumpState = 0
                    HapticUtility.playHapticsFile(named: "AHAP/JumpDown")
                }
            }
        }
        
        if touchesTheGround && !wasTouchingTheGroup && !isBurning && lastStepFrame < frameCounter - 10 {
            // sound
            lastStepFrame = frameCounter
            characterNode.runAction(SCNAction.playAudio(steps[0], waitForCompletion: false))
        }
        
        if wPosition.y < characterNode.simdPosition.y {
            wPosition.y = characterNode.simdPosition.y
        }
        //------------------------------------------------------------------
        
        // Progressively update the elevation node when the character touches the ground.
        if touchesTheGround {
            targetAltitude = wPosition.y
        }
        baseAltitude *= 0.95
        baseAltitude += targetAltitude * 0.05
        
        characterVelocity.y += downwardAcceleration
        if simd_length_squared(characterVelocity) > 10E-4 * 10E-4 {
            let startPosition = characterNode!.presentation.simdWorldPosition + collisionShapeOffsetFromModel
            slideInWorld(fromPosition: startPosition, velocity: characterVelocity)
        }
    }
    
    // MARK: - Animating the character
    
    var isAttacking: Bool {
        return attackCount > 0
    }
    
    func attack() {
        attackCount += 1
        model.animationPlayer(forKey: "spin")?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.attackCount -= 1
        }
        
        if attackCount == 1 {
            HapticUtility.playHapticsFile(named: "AHAP/SpinAttack")
        }
        
        spinParticleAttach.addParticleSystem(spinCircleParticle)
    }
    
    var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                // Update the animation node.
                if isWalking {
                    model.animationPlayer(forKey: "walk")?.play()
                } else {
                    model.animationPlayer(forKey: "walk")?.stop(withBlendOutDuration: 0.2)
                }
            }
        }
    }
    
    var walkSpeed: CGFloat = 1.0 {
        didSet {
            let burningFactor: CGFloat = isBurning ? 2: 1
            model.animationPlayer(forKey: "walk")?.speed = Character.speedFactor * walkSpeed * burningFactor
        }
    }
    
    func characterDirection(withPointOfView pointOfView: SCNNode?) -> simd_float3 {
        let controllerDir = self.direction
        if controllerDir.allZero() {
            return simd_float3.zero
        }
        
        var directionWorld = simd_float3.zero
        if let pov = pointOfView {
            let point1 = pov.presentation.simdConvertPosition(simd_float3(controllerDir.x, 0.0, controllerDir.y), to: nil)
            let point2 = pov.presentation.simdConvertPosition(simd_float3.zero, to: nil)
            directionWorld = point1 - point2
            directionWorld.y = 0
            if simd_any(directionWorld != simd_float3.zero) {
                let minControllerSpeedFactor = Float(0.2)
                let maxControllerSpeedFactor = Float(1.0)
                let speed = simd_length(controllerDir) * (maxControllerSpeedFactor - minControllerSpeedFactor) + minControllerSpeedFactor
                directionWorld = speed * simd_normalize(directionWorld)
            }
        }
        return directionWorld
    }
    
    func resetCharacterPosition() {
        characterNode.simdPosition = Character.initialPosition
        downwardAcceleration = 0
    }
    
    // MARK: Enemy
    
    func didHitEnemy() {
        HapticUtility.playHapticsFile(named: "AHAP/Boing")
        model.runAction(SCNAction.group(
            [SCNAction.playAudio(hitEnemySound, waitForCompletion: false),
             SCNAction.sequence(
                [SCNAction.wait(duration: 0.5),
                 SCNAction.playAudio(explodeEnemySound, waitForCompletion: false)
                ])
            ]))
    }
    
    func wasTouchedByEnemy() {
        let time = CFAbsoluteTimeGetCurrent()
        if time > lastHitTime + 1 {
            HapticUtility.playHapticsFile(named: "AHAP/DamageTaken")
            lastHitTime = time
            model.runAction(SCNAction.sequence([
                SCNAction.playAudio(hitSound, waitForCompletion: false),
                SCNAction.repeat(SCNAction.sequence([
                    SCNAction.fadeOpacity(to: 0.01, duration: 0.1),
                    SCNAction.fadeOpacity(to: 1.0, duration: 0.1)
                    ]), count: 4)
                ]))
        }
    }
    
    // MARK: Utils
    
    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // Find the top-level animation.
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
    
    // MARK: - Physics Contact
    func slideInWorld(fromPosition start: simd_float3, velocity: simd_float3) {
        let maxSlideIteration: Int = 4
        var iteration = 0
        var stop: Bool = false

        var replacementPoint = start

        var start = start
        var velocity = velocity
        let options: [SCNPhysicsWorld.TestOption: Any] = [
            SCNPhysicsWorld.TestOption.collisionBitMask: Bitmask.collision.rawValue,
            SCNPhysicsWorld.TestOption.searchMode: SCNPhysicsWorld.TestSearchMode.closest]
        while !stop {
            var fromMatrix = matrix_identity_float4x4
            fromMatrix.position = start

            var toMatrix = matrix_identity_float4x4
            toMatrix.position = start + velocity

            let contacts = physicsWorld!.convexSweepTest(
                with: characterCollisionShape!,
                from: SCNMatrix4(fromMatrix),
                to: SCNMatrix4(toMatrix),
                options: options)
            if !contacts.isEmpty {
                (velocity, start) = handleSlidingAtContact(contacts.first!, position: start, velocity: velocity)
                iteration += 1

                if simd_length_squared(velocity) <= (10E-3 * 10E-3) || iteration >= maxSlideIteration {
                    replacementPoint = start
                    stop = true
                }
            } else {
                replacementPoint = start + velocity
                stop = true
            }
        }
        characterNode!.simdWorldPosition = replacementPoint - collisionShapeOffsetFromModel
    }

    private func handleSlidingAtContact(_ closestContact: SCNPhysicsContact, position start: simd_float3, velocity: simd_float3)
        -> (computedVelocity: simd_float3, colliderPositionAtContact: simd_float3) {
        let originalDistance: Float = simd_length(velocity)

        let colliderPositionAtContact = start + Float(closestContact.sweepTestFraction) * velocity

        // Compute the sliding plane.
        let slidePlaneNormal = simd_float3(closestContact.contactNormal)
        let slidePlaneOrigin = simd_float3(closestContact.contactPoint)
        let centerOffset = slidePlaneOrigin - colliderPositionAtContact

        // Compute the destination relative to the point of contact.
        let destinationPoint = slidePlaneOrigin + velocity

        // Project the destination point onto the sliding plane.
        let distPlane = simd_dot(slidePlaneOrigin, slidePlaneNormal)

        // Project onto the plane.
        var distance = planeIntersect(planeNormal: slidePlaneNormal, planeDist: distPlane,
                               rayOrigin: destinationPoint, rayDirection: slidePlaneNormal)

        let normalizedVelocity = velocity * (1.0 / originalDistance)
        let angle = simd_dot(slidePlaneNormal, normalizedVelocity)

        var frictionCoeff: Float = 0.3
        if abs(angle) < 0.9 {
            distance += 10E-3
            frictionCoeff = 1.0
        }
        let newDestinationPoint = (destinationPoint + distance * slidePlaneNormal) - centerOffset

        // Advance start position to nearest point without collision.
        let computedVelocity = frictionCoeff * Float(1.0 - closestContact.sweepTestFraction)
            * originalDistance * simd_normalize(newDestinationPoint - start)

        return (computedVelocity, colliderPositionAtContact)
    }

}
