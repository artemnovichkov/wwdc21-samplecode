/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class serves as the haptic provider.
*/

import Foundation
import GameController
import CoreHaptics

class HapticUtility {
    static var engines: [GCController: CHHapticEngine] = [:]
    
    // Initialize a new HapticUtility object.
    class func initHapticsFor(controller: GCController) {
        engines[controller] = controller.haptics?.createEngine(withLocality: .default)
    }
    
    class func deinitHapticsFor(controller: GCController) {
        engines.removeValue(forKey: controller)
    }
    
    class func patternPlayersForHapticsFile(named filename: String) -> [CHHapticPatternPlayer] {

        guard let controller = GCController.current else { return [] }
        
        guard let engine = engines[controller] else { return [] }
        
        // Express the path to the AHAP file before attempting to load it.
        guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else {
            return []
        }
        
        guard let patternData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("Failed to parse json data")
            return []
        }
        
        guard let patternSerialized = try? JSONSerialization.jsonObject(with: patternData, options: []) else {
            print("Failed to deserialize json data")
            return []
        }
        
        guard let patternDictionary = patternSerialized as? [CHHapticPattern.Key: Any] else {
            print("Failed to deserialize json data as NSDictionary")
            return []
        }
        
        do {
            // Start the engine in case it's idle.
            var players: [CHHapticPatternPlayer] = []
            try engine.start()
            // Tell the engine to play a pattern.
            let pattern = try CHHapticPattern(dictionary: patternDictionary)
            let player = try engine.makePlayer(with: pattern)
            players.append(player)
            return players
        } catch { // Process engine startup errors.
            print("An error occured playing \(filename): \(error).")
            return []
        }
    }
    
    class func playHapticsFile(named filename: String) {
        guard let controller = GCController.current else { return }
        
        guard let engine = engines[controller] else { return }
        
        // Express the path to the AHAP file before attempting to load it.
        guard let path = Bundle.main.path(forResource: filename, ofType: "ahap") else {
            return
        }
        
        do {
            // Start the engine in case it's idle.
            try engine.start()
            // Tell the engine to play a pattern.
            try engine.playPattern(from: URL(fileURLWithPath: path))
        } catch { // Process engine startup errors.
            print("An error occured playing \(filename): \(error).")
        }
    }
}
