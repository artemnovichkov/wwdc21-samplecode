/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sprite helper for the SpriteKit implementation.
*/

import UIKit
import SpriteKit
import ARKit
import AVFoundation

extension ViewController: ARSKViewDelegate {
    func view(_ view: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        if count >= 2 {
            return nil
        }
        
        // Create and configure a node for the anchor added to the view's session.
        var imageNode = SKSpriteNode()
        
        // Use these two textures to handle when each bird is NOT speaking.
        let blueRest = SKTexture(imageNamed: "blue_speak_1")
        let redRest = SKTexture(imageNamed: "red_speak_1")
        
        if sceneView.scene?.children.count == 0 {
            imageNode = SKSpriteNode(texture: blueRest)
            imageNode.name = "blue"
        } else if sceneView.scene?.children.count == 1 {
            imageNode = SKSpriteNode(texture: redRest)
            imageNode.name = "red"
        }
        imageNode.size.width = 50
        imageNode.size.height = 50
        imageNode.position.y = 0
        imageNode.position.x = 0
                
        // Check if this is the first image node.
        count += 1
        
        return imageNode
    }
    
    func speakAnimator(assetBaseName: String) {
        // Generate a blink with 33% probability.
        
        let speakerAtlas = (isFirstSpeaker ? blueSpeakerAtlas : redSpeakerAtlas)
        
        var speakFrames = [SKTexture]()
        
        for frame in 1...6 {
            speakFrames.append(speakerAtlas.textureNamed("\(assetBaseName.lowercased())_speak_\(frame)"))
        }
        
        if isFirstSpeaker {
            firstSpeakerFrames = speakFrames
        } else {
            secondSpeakerFrames = speakFrames
        }
    }
    
    func animateSpeaker(assetBaseName: String) {
        
        guard let node = sceneView.scene?.childNode(withName: "\(assetBaseName.lowercased())") else {
            return
        }
        
        // Refresh the contents of the texture set for the animation.
        speakAnimator(assetBaseName: assetBaseName)
        
        let frameSet = isFirstSpeaker ? firstSpeakerFrames : secondSpeakerFrames
        
        let chat = SKAction.animate(with: frameSet,
                             timePerFrame: 0.1,
                             resize: false,
                             restore: true)
        
        node.run(SKAction.repeatForever(chat), withKey: "chirpyBird")
    }
}
