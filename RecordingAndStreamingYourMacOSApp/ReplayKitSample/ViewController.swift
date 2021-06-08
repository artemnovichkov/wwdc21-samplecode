/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main view controller object.
*/

import Cocoa
import ReplayKit
import Photos

class ViewController: NSViewController,
                      RPScreenRecorderDelegate,
                      RPPreviewViewControllerDelegate,
                      RPBroadcastControllerDelegate,
                      RPBroadcastActivityControllerDelegate {
    
    // IBOutlets for the record, capture, and broadcast buttons.
    @IBOutlet var recordButton: NSButton!
    @IBOutlet var captureButton: NSButton!
    @IBOutlet var broadcastButton: NSButton!
    @IBOutlet var cameraCheckBox: NSButton!
    @IBOutlet var microphoneCheckBox: NSButton!
    @IBOutlet var clipButton: NSButton!
    @IBOutlet var getClipButton: NSButton!
    
    // Internal state variables.
    private var isActive = false
    private var replayPreviewViewController: NSWindow!
    private var activityController: RPBroadcastActivityController!
    private var broadcastControl: RPBroadcastController!
    private var cameraView: NSView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the recording state.
        isActive = false
        
        // Initialize the screen recorder delegate.
        RPScreenRecorder.shared().delegate = self
        
        DispatchQueue.main.async {
            // Set the buttons' enabled states.
            self.recordButton.isEnabled = RPScreenRecorder.shared().isAvailable
            self.captureButton.isEnabled = RPScreenRecorder.shared().isAvailable
            self.broadcastButton.isEnabled = RPScreenRecorder.shared().isAvailable
            self.clipButton.isEnabled = RPScreenRecorder.shared().isAvailable
        }
    }
    
    // MARK: - Screen Recorder Microphone / Camera Property methods
    @IBAction func cameraButtonTapped(_ sender: NSButton) {
        if cameraCheckBox.state == .on {
            RPScreenRecorder.shared().isCameraEnabled = true
        } else {
            RPScreenRecorder.shared().isCameraEnabled = false
        }
    }
    
    @IBAction func microphoneButtonTapped(_ sender: NSButton) {
        if microphoneCheckBox.state == .on {
            RPScreenRecorder.shared().isMicrophoneEnabled = true
        } else {
            RPScreenRecorder.shared().isMicrophoneEnabled = false
        }
    }
    
    func setupCameraView() {
        DispatchQueue.main.async {
            // Validate that the camera preview view and camera are in an enabled state.
            if (RPScreenRecorder.shared().cameraPreviewView != nil) && RPScreenRecorder.shared().isCameraEnabled {
                // Set the camera view to the camera preview view of RPScreenRecorder.
                guard let cameraView = RPScreenRecorder.shared().cameraPreviewView else {
                    print("Unable to retrieve the cameraPreviewView from RPScreenRecorder. Returning.")
                    return
                }
                // Set the frame and position to place the camera preview view.
                cameraView.frame = NSRect(x: 0, y: self.view.frame.size.height - 100, width: 100, height: 100)
                // Ensure that the view is layer-backed.
                cameraView.wantsLayer = true
                // Add the camera view as a subview to the main view.
                self.view.addSubview(cameraView)
                
                self.cameraView = cameraView
            }
        }
    }
    
    func tearDownCameraView() {
        DispatchQueue.main.async {
            // Remove the camera view from the main view when tearing down the camera.
            self.cameraView?.removeFromSuperview()
        }
    }
    
    // MARK: - In-App Recording
    @IBAction func recordButtonTapped(_ sender: NSButton) {
        // Check the internal recording state.
        if isActive == false {
            // If a recording isn't currently underway, start it.
            startRecording()
        } else {
            // If a recording is active, the button stops it.
            stopRecording()
        }
    }
    
    func startRecording() {
        RPScreenRecorder.shared().startRecording { error in
            // If there is an error, print it and set the button title and state.
            if error == nil {
                // There isn't an error and recording starts successfully. Set the recording state.
                self.setRecordingState(active: true)
                
                // Set up the camera view.
                self.setupCameraView()
            } else {
                // Print the error.
                print("Error starting recording")
                
                // Set the recording state.
                self.setRecordingState(active: false)
            }
        }
    }
    
    func stopRecording() {
        RPScreenRecorder.shared().stopRecording { previewViewController, error in
            if error == nil {
                // There isn't an error and recording stops successfully. Present the view controller.
                print("Presenting Preview View Controller")
                if previewViewController != nil {
                    DispatchQueue.main.async {
                        // Set the internal preview view controller window.
                        self.replayPreviewViewController = NSWindow(contentViewController: previewViewController!)
                        
                        // Set the delegate so you know when to dismiss the preview view controller.
                        previewViewController?.previewControllerDelegate = self
                        
                        // Present the preview view controller from the main window as a sheet.
                        NSApplication.shared.mainWindow?.beginSheet(self.replayPreviewViewController, completionHandler: nil)
                    }
                } else {
                    // There isn't a preview view controller, so print an error.
                    print("No preview view controller to present")
                }
            } else {
                // There's an error stopping the recording, so print an error message.
                print("Error starting recording")
            }
            
            // Set the recording state.
            self.setRecordingState(active: false)
            
            // Tear down the camera view.
            self.tearDownCameraView()
            
        }
    }
    
    func setRecordingState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                print("started recording")
                self.recordButton.title = "Stop Recording"
            } else {
                // Set the button title.
                print("stopped recording")
                self.recordButton.title = "Start Recording"
            }
            
            // Set the internal recording state.
            self.isActive = active
            
            // Set the other buttons' isEnabled properties.
            self.captureButton.isEnabled = !active
            self.broadcastButton.isEnabled = !active
            self.clipButton.isEnabled = !active
        }
    }
    
    // MARK: - RPPreviewViewController Delegate
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        // This delegate method tells the app when the user finishes with the
        // preview view controller sheet (when the user exits or cancels the sheet).
        // End the presentation of the preview view controller here.
        DispatchQueue.main.async {
            NSApplication.shared.mainWindow?.endSheet(self.replayPreviewViewController)
        }
    }
    
    // MARK: - In-App Capture
    @IBAction func captureButtonTapped(_ sender: NSButton) {
        // Check the internal recording state.
        if isActive == false {
            // If a recording isn't active, the button starts the capture session.
            startCapture()
        } else {
            // If a recording is active, the button stops the capture session.
            stopCapture()
        }
    }
    
    func startCapture() {
        RPScreenRecorder.shared().startCapture { sampleBuffer, sampleBufferType, error in
            // The sample calls this handler every time ReplayKit is ready to give you a video, audio or microphone sample.
            // You need to check several things here so that you can process these sample buffers correctly.
            // Check for an error and, if there is one, print it.
            if error != nil {
                print("Error receiving sample buffer for in app capture")
            } else {
                // There isn't an error. Check the sample buffer for its type.
                switch sampleBufferType {
                case .video:
                    self.processAppVideoSample(sampleBuffer: sampleBuffer)
                case .audioApp:
                    self.processAppAudioSample(sampleBuffer: sampleBuffer)
                case .audioMic:
                    self.processAppMicSample(sampleBuffer: sampleBuffer)
                default:
                    print("Unable to process sample buffer")
                }
            }
        } completionHandler: { error in
            // The sample calls this handler when the capture session starts. It only calls it once.
            // Use this handler to set your started capture state and variables.
            if error == nil {
                // There's no error when attempting to start an in-app capture session. Update the capture state.
                self.setCaptureState(active: true)
                
                // Set up the camera view.
                self.setupCameraView()
            } else {
                // There's an error when attempting to start the in-app capture session. Print an error.
                print("Error starting in app capture session")
                
                // Update the capture state.
                self.setCaptureState(active: false)
            }
        }
    }
    
    func processAppVideoSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the video sample buffers as necessary.
        // The sample simply prints a message to the console.
        print("Received a video sample.")
    }
    
    func processAppAudioSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the audio sample buffers as necessary.
        // The sample simply prints a message to the console.
        print("Received an audio sample.")
    }
    
    func processAppMicSample(sampleBuffer: CMSampleBuffer) {
        // An app can modify the microphone audio sample buffers as necessary.
        // The sample simply prints a message to the console.
        print("Received a microphone audio sample.")
    }
    
    func stopCapture() {
        RPScreenRecorder.shared().stopCapture { error in
            // The sample calls the handler when the stop capture finishes. Update the capture state.
            self.setCaptureState(active: false)
            
            // Tear down the camera view.
            self.tearDownCameraView()
            
            // Check and print the error, if necessary.
            if error != nil {
                print("Encountered and error attempting to stop in app capture")
            }
        }
    }
    
    func setCaptureState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                self.captureButton.title = "Stop Capture"
            } else {
                // Set the button title.
                self.captureButton.title = "Start Capture"
            }
            
            // Set the internal recording state.
            self.isActive = active
            
            // Set the other buttons' isEnabled properties.
            self.recordButton.isEnabled = !active
            self.broadcastButton.isEnabled = !active
            self.clipButton.isEnabled = !active
        }
    }
    
    // MARK: - In-App Broadcast
    @IBAction func broadcastButtonTapped(_ sender: NSButton) {
        // Check the internal recording state.
        if isActive == false {
            // If not active, present the broadcast picker.
            presentBroadcastPicker()
        } else {
            // If currently active, the button stops the broadcast session.
            stopBroadcast()
        }
        
    }
    
    func presentBroadcastPicker() {
        // Set the origin point for the broadcast picker.
        let broadcastPickerOriginPoint = CGPoint.zero
        
        // Show the broadcast picker.
        RPBroadcastActivityController.showBroadcastPicker(at: broadcastPickerOriginPoint,
                                                          from: NSApplication.shared.mainWindow,
                                                          preferredExtensionIdentifier: nil) { broadcastActivtyController, error in
            if error == nil {
                // There isn't an error presenting the broadcast picker.
                // Save the broadcast activity controller reference.
                self.activityController = broadcastActivtyController
                
                // Set the broadcast activity controller delegate so that you
                // can get the RPBroadcastController when the user finishes with the picker.
                self.activityController.delegate = self
            } else {
                // There's an error when attempting to present the broadcast picker, so print the error.
                print("Error attempting to present broadcast activity controller")
            }
        }
    }
    
    func stopBroadcast() {
        broadcastControl.finishBroadcast { error in
            // Update the broadcast state.
            self.setBroadcastState(active: false)
            
            // Tear down the camera view.
            self.tearDownCameraView()
            
            // Check and print the error, if necessary.
            if error != nil {
                print("Error attempting to stop in app broadcast")
            }
        }
    }
    
    func setBroadcastState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                self.broadcastButton.title = "Stop Broadcast"
            } else {
                // Set the button title.
                self.broadcastButton.title = "Start Broadcast"
            }
            
            // Set the internal recording state.
            self.isActive = active
            
            // Set the other buttons' isEnabled properties.
            self.recordButton.isEnabled = !active
            self.captureButton.isEnabled = !active
            self.clipButton.isEnabled = !active
        }
    }
    
    // MARK: - In-App Clip Recording
    @IBAction func clipButtonTapped(_ sender: Any) {
        // Check the internal recording state.
        if isActive == false {
            // If the recording isn't active, the button starts the clip buffering session.
            startClipBuffering()
        } else {
            // If a recording is active, the button stops the clip buffering session.
            stopClipBuffering()
        }
    }
    
    @IBAction func generateClipPressed(_ sender: Any) {
        if self.isActive == true && self.getClipButton.isEnabled == true {
            exportClip()
        }
    }
    
    func startClipBuffering() {
        RPScreenRecorder.shared().startClipBuffering { (error) in
            if error != nil {
                print("Error attempting to start Clip Buffering")
                
                self.setClipState(active: false)
                
            } else {
                // There's no error when attempting to start a clip session. Update the clip state.
                self.setClipState(active: true)
                
                // Set up the camera view.
                self.setupCameraView()
            }
        }
    }
    
    func stopClipBuffering() {
        RPScreenRecorder.shared().stopClipBuffering { (error) in
            if error != nil {
                print("Error attempting to stop Clip Buffering")
            }
            // The sample calls this handler when stopClipBuffering finishes. Update the clip state.
            self.setClipState(active: false)
            
            // Tear down the camera view.
            self.tearDownCameraView()
        }
    }
    
    func setClipState(active: Bool) {
        DispatchQueue.main.async {
            if active == true {
                // Set the button title.
                self.clipButton.title = "Stop Clip"
            } else {
                // Set the button title.
                self.clipButton.title = "Start Clip"
            }
            
            // Set the internal recording state.
            self.isActive = active
            
            // Set the getClip button.
            self.getClipButton.isEnabled = active
            
            // Set the other buttons' isEnabled properties.
            self.recordButton.isEnabled = !active
            self.broadcastButton.isEnabled = !active
            self.captureButton.isEnabled = !active
        }
    }
    
    func exportClip() {
        let clipURL = getDirectory()
        let interval = TimeInterval(5)
    
        print("Generating clip at URL: ", clipURL)
        RPScreenRecorder.shared().exportClip(to: clipURL, duration: interval) { error in
            if error != nil {
                print("Error attempting to start Clip Buffering")
            } else {
                // There isn't an error, so save the clip at the URL to Photos.
                self.saveToPhotos(tempURL: clipURL)
            }
        }
    }
    
    func getDirectory() -> URL {
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let stringDate = formatter.string(from: Date())
        print(stringDate)
        tempPath.appendPathComponent(String.localizedStringWithFormat("output-%@.mp4", stringDate))
        return tempPath
    }
        
    func saveToPhotos(tempURL: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
        } completionHandler: { success, error in
            if success == true {
                print("Saved to photos")
            } else {
                print("Error exporting clip to Photos")
            }
        }
    }

    // MARK: - RPBroadcastActivityController Delegate
    func broadcastActivityController(_ broadcastActivityController: RPBroadcastActivityController,
                                     didFinishWith broadcastController: RPBroadcastController?,
                                     error: Error?) {
        if error == nil {
            // Assign the private variable to the broadcast controller that you pass so that you
            // can control the broadcast.
            broadcastControl = broadcastController
            
            // Start the broadcast.
            broadcastControl.startBroadcast { error in
                // Update the broadcast state.
                self.setBroadcastState(active: true)
                
                // Set up the camera view.
                self.setupCameraView()
            }
        } else {
            // Print an error.
            print("Error with broadcast activity controller delegate call didFinish")
        }
    }
    
    // MARK: - RPScreenRecorder Delegate
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        // This delegate call lets the developer know when the screen recorder's availability changes.
        DispatchQueue.main.async {
            self.recordButton.isEnabled = screenRecorder.isAvailable
            self.captureButton.isEnabled = screenRecorder.isAvailable
            self.broadcastButton.isEnabled = screenRecorder.isAvailable
            self.clipButton.isEnabled = screenRecorder.isAvailable
        }
    }
    
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        // This delegate call lets you know if any of the ongoing recording or capture stops.
        // If there's a preview view controller to give back, present it here.
        print("delegate didstoprecording with previewViewController")
        DispatchQueue.main.async {
            // Reset the UI state.
            print("inside delegate call")
            self.isActive = false
            self.recordButton.title = "Start Recording"
            self.captureButton.title = "Start Capture"
            self.broadcastButton.title = "Start Broadcast"
            self.clipButton.title = "Start Clips"
            self.recordButton.isEnabled = true
            self.captureButton.isEnabled = true
            self.broadcastButton.isEnabled = true
            self.clipButton.isEnabled = true
            self.getClipButton.isHidden = true
            self.getClipButton.isEnabled = false
            
            // Tear down the camera view.
            self.tearDownCameraView()
            
            // There isn't an error and the stop recording is successful. Present the view controller.
            if previewViewController != nil {
                // Set the internal preview view controller window.
                self.replayPreviewViewController = NSWindow(contentViewController: previewViewController!)
                
                // Set the delegate so you know when to dismiss the preview view controller.
                previewViewController?.previewControllerDelegate = self
                
                // Present the preview view controller from the main window as a sheet.
                NSApplication.shared.mainWindow?.beginSheet(self.replayPreviewViewController, completionHandler: nil)
            } else {
                // There isn't a preview view controller, so print an error.
                print("No preview view controller to present")
            }
        }
    }
}

