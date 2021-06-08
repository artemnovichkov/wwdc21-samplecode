/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import ReplayKit
import AVFAudio
import AudioToolbox

class ViewController: UIViewController, RPPreviewViewControllerDelegate {
    
    // MARK: - Properties -
    @IBOutlet var arView: ARView!
    @IBOutlet weak var button: UIButton!
    
    let recorder = RPScreenRecorder.shared()
    var isRecording = false
    
    /// An array of materials, one for each framework image to display.
    var frameworkMaterials: [UnlitMaterial] = []
    
    /// A reference to the anchor loaded from the RealityComposer file.
    var faceAnchor: Experience.Face?
    
    // MARK: - Constants -
    
    /// The number of times the timer gets called before displaying image. This adds a delay for the
    /// question mark to spin before the frameworks start displaying.
    let maxTimerCount: Int = 45
    
    /// The number of seconds between timer closure calls.
    let timerInterval: TimeInterval = 0.15
    
    // MARK: - Set Up -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMaterials()

        recorder.isMicrophoneEnabled = true
        arView.renderOptions = .disableCameraGrain
        
        // Load the "Face" scene from the "Experience" Reality File.
        if let faceScene = try? Experience.loadFace() {
            faceAnchor = faceScene
            arView.scene.anchors.append(faceScene)
        }
        
        let arConfig = ARFaceTrackingConfiguration()
        arView.session.run(arConfig)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Inform the user if they are on a device that doesn't support AR
        // face tracking.
        if !ARFaceTrackingConfiguration.isSupported {
            
            let alertController = UIAlertController(title: "Face Tracking Unavailable",
                                                    message: "Freestyle Framework requires an iPhone X or later.",
                                                    preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "Okay",
                                              style: .default)
            alertController.addAction(defaultAction)
            present(alertController, animated: true) {}
        }
    }
    
    /// This sets up an array of `UnlitMaterial` instances, one for each of the framework images.
    func setupMaterials() {
        
        // Load the list of image texture names from the plist file.
        guard let fileUrl = Bundle.main.url(forResource: "images", withExtension: "plist"), let data = try? Data(contentsOf: fileUrl) else {
            fatalError("Error loading images plist.")
        }
        
        // Parse the plist into an array of strings.
        guard let textureNames = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] else {
            fatalError("Error parsing images plist.")
        }
        
        // Create an array of materials from the list of names.
        frameworkMaterials = textureNames.map({ (imageName: String) -> UnlitMaterial in
            return createUnlitMaterialWithTexture(named: imageName)
        })
    }
    
    // MARK: - User Interaction -
    
    @IBAction func toggleRecording(sender: AnyObject) {
        guard let sender = sender as? UIButton else { return }
        
        if !sender.state.contains(.selected) {
            sender.isSelected = true
            startRecording()
        } else {
            sender.isSelected = false
            stopRecording()
        }
    }
    
    /// Starts the ReplayKit recording and display random images over the user's head.
    private func startRecording() {
        RPScreenRecorder.shared().startRecording { error in
            
            if let error = error {
                print(error)
            } else {
                print("Started recording"...)
                
                self.isRecording = true
                self.faceAnchor?.notifications.spinAction.post()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.7) {
                    print("Queue image sequence...")
                    
                    self.faceAnchor?.questionMark?.isEnabled = false
                    self.faceAnchor?.frameworkImageFrame?.isEnabled = true
                    
                    // Texture switch animation.
                    self.handleImageAnimationsSequence()
                }
            }
        }
    }
    
    /// Stops the ReplayKit recording.
    private func stopRecording() {
        RPScreenRecorder.shared().stopRecording(handler: { (preview, error) in
            
            if let unwrappedPreview = preview {
                unwrappedPreview.previewControllerDelegate = self
                self.present(unwrappedPreview, animated: true)
                
                print("Stopped recording...")
                self.isRecording = false
                
                self.faceAnchor?.questionMark?.isEnabled = true
                self.faceAnchor?.frameworkImageFrame?.isEnabled = false
            }
            
            if let error = error {
                print(error)
            }
        })
    }
    
    /// Changes the image displayed on the frameworkFrame by pulling random materials from
    ///  `frameworkMaterials` repeatedly on a timer.
    func handleImageAnimationsSequence() {
        
        var timerCounter = 0
        
        Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { timer in
            
            guard let frameworkModel = self.faceAnchor?.frameworkImageFrame?.children.first as? ModelEntity,
                  var modelComponent = frameworkModel.model,
                  let material = self.frameworkMaterials.getRandomElement() else { return }
            
            modelComponent.materials = [material]
            frameworkModel.model = modelComponent
            
            timerCounter += 1
            
            if timerCounter == self.maxTimerCount || self.isRecording == false {
                timer.invalidate()
                
                if self.isRecording == true {
                    self.faceAnchor?.notifications.textBounce.post()
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
            }
        }
    }
}

// MARK: - Private Methods -

extension ViewController {
    
    /// This private function creates an `UnlitMaterial` from a filename. It is used to populate the
    /// array of unlit materials used to display the framwork icons.
    private func createUnlitMaterialWithTexture(named name: String) -> UnlitMaterial {
        var material = UnlitMaterial()
        
        if let msgResource = try? TextureResource.load(named: name) {
            let color = MaterialParameters.Texture(msgResource)
            material.color = .init(tint: .init(white: 1.0, alpha: 0.9999),
                                   texture: color)
        } else {
            // If one of the bundle images fails to load, it means there's a
            // bad name in the array. Log it and crash.
            print("Unable to create texture from \(name)")
            exit(1)
        }
        return material
    }
}

// MARK: - RPPreviewViewControllerDelegate -

extension ViewController {
    
    /// This is the delegate callback for the ReplayKit preview controller.
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
}
