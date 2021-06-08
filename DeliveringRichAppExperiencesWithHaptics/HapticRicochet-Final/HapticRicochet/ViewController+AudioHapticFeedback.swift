/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The haptics portion of the HapticRicochet app.
*/

import CoreHaptics
import AVFoundation

extension ViewController {
    
    func createAndStartHapticEngine() {
        guard supportsHaptics else { return }
        
        // Create and configure a haptic engine.
        do {
            engine = try CHHapticEngine(audioSession: .sharedInstance())
        } catch let error {
            fatalError("Engine Creation Error: \(error)")
        }
        
        // The stopped handler alerts engine stoppage.
        engine.stoppedHandler = { reason in
            print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
            switch reason {
            case .audioSessionInterrupt:
                print("Audio session interrupt.")
            case .applicationSuspended:
                print("Application suspended.")
            case .idleTimeout:
                print("Idle timeout.")
            case .notifyWhenFinished:
                print("Finished.")
            case .systemError:
                print("System error.")
            case .engineDestroyed:
                print("Engine destroyed.")
            case .gameControllerDisconnect:
                print("Controller disconnected.")
            @unknown default:
                print("Unknown error")
            }
            
            // Indicate that the next time the app requires a haptic, the app must call engine.start().
            self.engineNeedsStart = true
        }
        
        // The reset handler notifies the app that it must reload all of its content.
        // If necessary, it recreates all players and restarts the engine in response to a server restart.
        engine.resetHandler = {
            print("The engine reset --> Restarting now!")
            
            // Tell the app to start the engine the next time a haptic is necessary.
            self.engineNeedsStart = true
        }
        
        // Start the haptic engine to prepare it for use.
        do {
            try engine.start()
            
            // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
            engineNeedsStart = false
        } catch let error {
            print("The engine failed to start with error: \(error)")
        }
    }
    
    func initializeCollisionHaptics() {
        // Create a collision player for each ball state.
        let collisionPatternSmall = createPatternFromAHAP("CollisionSmall")!
        collisionPlayerSmall = try? engine.makePlayer(with: collisionPatternSmall)
        
        let collisionPatternLarge = createPatternFromAHAP("CollisionLarge")!
        collisionPlayerLarge = try? engine.makePlayer(with: collisionPatternLarge)
        
        let collisionPatternShield = createPatternFromAHAP("CollisionShield")!
        collisionPlayerShield = try? engine.makePlayer(with: collisionPatternShield)
    }
    
    func initializeTextureHaptics() {
        // Create a texture player.
        let texturePattern = createPatternFromAHAP("Texture")!
        texturePlayer = try? engine.makeAdvancedPlayer(with: texturePattern)
        texturePlayer?.loopEnabled = true
    }
    
    func initializeSpawnHaptics() {
        // Create a pattern from the spawn asset.
        let pattern = createPatternFromAHAP("Spawn")!
        
        // Create a player from the spawn pattern.
        spawnPlayer = try? engine.makePlayer(with: pattern)
    }
    
    func initializeGrowHaptics() {
        // Create a pattern from the grow asset.
        let pattern = createPatternFromAHAP("Grow")!
        
        // Create a player from the grow pattern.
        growPlayer = try? engine.makePlayer(with: pattern)
    }
    
    func initializeShieldHaptics() {
        // Create a pattern from the shield asset.
        let pattern = createPatternFromAHAP("ShieldContinuous")!
        
        // Create a player from the shield pattern.
        shieldPlayer = try? engine.makePlayer(with: pattern)
    }
    
    func initializeImplodeHaptics() {
        // Create a pattern from the implode asset.
        let pattern = createPatternFromAHAP("Implode")!
        
        // Create a player from the implode pattern.
        implodePlayer = try? engine.makePlayer(with: pattern)
    }
    
    private func createPatternFromAHAP(_ filename: String) -> CHHapticPattern? {
        // Get the URL for the pattern in the app bundle.
        let patternURL = Bundle.main.url(forResource: filename, withExtension: "ahap")!
        
        do {
            // Read JSON data from the URL.
            let patternJSONData = try Data(contentsOf: patternURL, options: [])
            
            // Create a dictionary from the JSON data.
            let dict = try JSONSerialization.jsonObject(with: patternJSONData, options: [])
            
            if let patternDict = dict as? [CHHapticPattern.Key: Any] {
                // Create a pattern from the dictionary.
                return try CHHapticPattern(dictionary: patternDict)
            }
        } catch let error {
            print("Error creating haptic pattern: \(error)")
        }
        return nil
    }
    
    func startPlayer(_ player: CHHapticPatternPlayer) {
        guard supportsHaptics else { return }
        do {
            try startHapticEngineIfNecessary()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Error starting haptic player: \(error)")
        }
    }
    
    func stopPlayer(_ player: CHHapticPatternPlayer) {
        guard supportsHaptics else { return }
        
        do {
            try startHapticEngineIfNecessary()
            try player.stop(atTime: CHHapticTimeImmediate)
        } catch let error {
            print("Error stopping haptic player: \(error)")
        }
    }
    
    func startTexturePlayerIfNecessary() {
        guard supportsHaptics, rollingTextureEnabled else { return }
        
        // Create and send a dynamic parameter with zero intensity at the start of
        // the texture playback. The intensity dynamically modulates as the
        // sphere moves, but it starts from zero.
        let zeroIntensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                          value: 0,
                                                          relativeTime: 0)
        do {
            try startHapticEngineIfNecessary()
            try texturePlayer.sendParameters([zeroIntensityParameter], atTime: 0)
        } catch let error {
            print("Dynamic Parameter Error: \(error)")
        }
        
        startPlayer(texturePlayer)
    }
    
    func updateTexturePlayer(_ magnitude: Float) {
        // Create dynamic parameters for the updated intensity.
        let intensityValue = linearInterpolation(alpha: magnitude, min: 0.05, max: 0.45)
        let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                          value: intensityValue,
                                                          relativeTime: 0)
        // Send dynamic parameter to the haptic player.
        do {
            try startHapticEngineIfNecessary()
            
            switch sphereState {
            case .none:
                break
            case .small, .large, .shield:
                try texturePlayer.sendParameters([intensityParameter],
                                                        atTime: 0)
            }
        } catch let error {
            print("Dynamic Parameter Error: \(error)")
        }
    }
    
    private func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }
    
    func playCollisionHaptic(_ normalizedMagnitude: Float) {
        do {
            // Create dynamic parameters for the current magnitude.
            let intensityValue = linearInterpolation(alpha: normalizedMagnitude, min: 0.375, max: 1.0)
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                              value: intensityValue,
                                                              relativeTime: 0)
            let volumeValue = linearInterpolation(alpha: normalizedMagnitude, min: 0.1, max: 1.0)
            let volumeParameter = CHHapticDynamicParameter(parameterID: .audioVolumeControl,
                                                              value: volumeValue,
                                                              relativeTime: 0)
            
            try startHapticEngineIfNecessary()
            
            switch sphereState {
            case .small:
                try collisionPlayerSmall.sendParameters([intensityParameter, volumeParameter], atTime: CHHapticTimeImmediate)
                try collisionPlayerSmall.start(atTime: CHHapticTimeImmediate)
            case .large:
                try collisionPlayerLarge.sendParameters([intensityParameter, volumeParameter], atTime: CHHapticTimeImmediate)
                try collisionPlayerLarge.start(atTime: CHHapticTimeImmediate)
            case .shield:
                try collisionPlayerShield.sendParameters([intensityParameter, volumeParameter], atTime: CHHapticTimeImmediate)
                try collisionPlayerShield.start(atTime: CHHapticTimeImmediate)
            default:
                print("No action for the collision during: \(sphereState)")
            }
        } catch let error {
                print("Haptic Playback Error: \(error)")
        }
    }
    
    func startHapticEngineIfNecessary() throws {
        if engineNeedsStart {
            try engine.start()
            engineNeedsStart = false
        }
    }
    
    func restartHapticEngine() {
        self.engine.start { error in
            if let error = error {
                print("Haptic Engine Startup Error: \(error)")
                return
            }
            self.engineNeedsStart = false
        }
    }
    
    func stopHapticEngine() {
        self.engine.stop { error in
            if let error = error {
                print("Haptic Engine Shutdown Error: \(error)")
                return
            }
            self.engineNeedsStart = true
        }
    }
}
