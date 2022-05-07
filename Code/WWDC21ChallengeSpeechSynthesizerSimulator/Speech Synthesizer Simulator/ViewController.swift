/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller. This class sets up the view elements, handles the SpriteKit
 implementation, and responds to the Conversation class's notification posting.
*/

import UIKit
import SpriteKit
import ARKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSKView!
    @IBOutlet var speakerLabel: UILabel!
    @IBOutlet var subtitleText: UITextView!
    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var speakerLabelView: UIView!
    @IBOutlet var subtitleLabelView: UIView!
    
    var firstSpeakerFrames: [SKTexture] = []
    var secondSpeakerFrames: [SKTexture] = []
    
    let redSpeakerAtlas = SKTextureAtlas(named: "REDTalking")
    let blueSpeakerAtlas = SKTextureAtlas(named: "BLUETalking")
    
    var isBlueSpeaking = false
    var isRedSpeaking = false
    
    var isFirstSpeaker = true
    
    var currentSpeaker = ""
    
    var count = 0
    var speechIndex = 0
    var scriptReader = ScriptReader()
    // Create an instance of Conversation as a view model to keep the AVSpeechSynthesizer
    // details abstracted for easier changes.
    var conversation = Conversation()
    
    // Determines whether the animation should trigger a blink.
    var isBlinking = false
    
    // Ensures uniform corner radii between the speaker label and the subtitle label.
    let labelCornerRadius: CGFloat = 8.0
    
    // Use this set of default insets for uniform padding
    // for both the speaker label and the subtitle label.
    let defaultInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeaker(_:)), name: Notification.Name("AVSpeakerData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLine(_:)), name: Notification.Name("AVLineData"), object: nil)
        
        // Set the view's delegate.
        sceneView.delegate = self
        sceneView.contentMode = .scaleAspectFit
        
        // Load the SKScene from 'Scene.sks'.
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
        
        subtitleText.text = "Speaker subtitles will appear here. Activate play button to start the conversation."
        speakerLabel.text = "Speaker name"
        
        playButton.accessibilityHint = "Activate the conversation."
        
        // Set the scene view to be an accessibility element
        // so the VoiceOver cursor and tap action work just
        // as a regular tap gesture would.
        sceneView.isAccessibilityElement = true
        sceneView.accessibilityLabel = "AR Scene View"
        sceneView.accessibilityHint = "Double tap to add a bird to the scene."
        
        // Set the subtitle label view as an accessibility
        // element so the VoiceOver cursor works properly.
        subtitleLabelView.isAccessibilityElement = true
        subtitleLabelView.accessibilityLabel = "Caption panel. \(String(describing: subtitleText.text))"
        
        // Set these values individually if you prefer to have
        // differing corner radii for both labels.
        speakerLabelView.layer.masksToBounds = true
        subtitleLabelView.layer.masksToBounds = true
        speakerLabelView.layer.cornerRadius = labelCornerRadius
        subtitleLabelView.layer.cornerRadius = labelCornerRadius
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration.
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session.
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session.
        sceneView.session.pause()
    }
    
    @IBAction func pressPlay(_ sender: Any) {
        guard sceneView.scene?.children.count == 2 else {
            subtitleText.text = "Please place two birds to run your conversation."
            return
        }
        
        guard let firstSpeaker = speakerLabel.text else { return }
        currentSpeaker = firstSpeaker
        
        if !conversation.synthesizer.isSpeaking {
            restoreStopButton()
            conversation.index = 0
            conversation.speakNow()
        } else {
            restorePlayButton()
            conversation.resetAll()
        }
    }
    
    @IBAction func pressReset(_ sender: Any) {
        conversation.resetAll()
        sceneView.scene?.removeAllChildren()
        restorePlayButton()
        count = 0
    }
    
    @IBAction func pressUndo(_ sender: Any) {
        switch sceneView.scene?.children.count {
        case 1:
            // Remove the first object.
            if let child = sceneView.scene?.childNode(withName: "blue") {
                child.removeFromParent()
                count -= 1
            }
        case 2:
            // Remove the second object.
            if let child = sceneView.scene?.childNode(withName: "red") {
                child.removeFromParent()
                count -= 1
            }
        default:
            print("no nodes present")
        }
    }
    
    @objc
    func updateSpeaker(_ obj: NSNotification) {
        
        guard let data = obj.object as? String else { return }
        routeSpeakers(receivedSpeaker: data)
        speakerLabel.text = data
    }
    
    @objc
    func updateLine(_ obj: NSNotification) {
        
        guard let data = obj.object as? String else { return }
        subtitleText.text = data
        subtitleLabelView.accessibilityLabel = subtitleText.text
    }
    
    func restorePlayButton() {
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal, barMetrics: UIBarMetrics.default)
    }
    
    func restoreStopButton() {
        playButton.setBackgroundImage(UIImage(systemName: "stop.fill"), for: UIControl.State.normal, barMetrics: UIBarMetrics.default)
        sceneView.scene?.removeAllActions()
    }
    
    func routeSpeakers(receivedSpeaker: String) {
        
        guard let redNode = sceneView.scene?.childNode(withName: "red") else { return }
        guard let blueNode = sceneView.scene?.childNode(withName: "blue") else { return }
        
        if currentSpeaker != receivedSpeaker {
            isFirstSpeaker.toggle()
            currentSpeaker = receivedSpeaker
        }
        
        if isFirstSpeaker {
            animateSpeaker(assetBaseName: "blue")
            redNode.removeAllActions()
        } else {
            animateSpeaker(assetBaseName: "red")
            blueNode.removeAllActions()
        }
    }
}
