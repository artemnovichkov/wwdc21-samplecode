/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's delegate object.
*/

import Cocoa
import Vision

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, VisionViewDelegate, NSSearchFieldDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var imageView: VisionView!
    @IBOutlet weak var transcriptView: NSTextView!
    @IBOutlet weak var customWordsField: NSTextField!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var progressView: ProgressView!
    @IBOutlet weak var revisionsPopUpButton: NSPopUpButton!
    @IBOutlet weak var languagePopUpButton: NSPopUpButton!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = self
    }
    
    // MARK: Result Filtering and Highlighting
    @IBAction func highlightResults(_ sender: NSMenuItem) {
        // Toggle the menu state.
        if sender.state == .on {
            sender.state = .off
        } else {
            sender.state = .on
        }
        imageView.annotationLayer.isHidden = (sender.state == .off)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        // Update the image view.
        imageView.annotationLayer.textFilter = searchField.stringValue
        
        // Update the transcript.
        let stringRange = transcriptView.string.range(of: searchField.stringValue)
        if let range = stringRange {
            transcriptView.showFindIndicator(for: NSRange(range, in: transcriptView.string))
        }
    }
    
    func updateAvailableLanguages() {
        do {
            let supportedLanguages: [String] = try textRecognitionRequest.supportedRecognitionLanguages()
            languagePopUpButton.removeAllItems()
            
            var index = 0
            for currentLanguage in supportedLanguages {
                languagePopUpButton.addItem(withTitle: currentLanguage)
                languagePopUpButton.lastItem?.tag = index
                    
                index += 1
            }
        } catch {
            print("Unexpected error: \(error).")
        }
        
        languagePopUpButton.selectItem(withTitle: primaryLanguage)
    }
    
    // MARK: Request Cancelation
    @IBAction func cancelCurrentRequest(_ sender: NSButton) {
        textRecognitionRequest.cancel()
        progressView.isRunning = false
    }
    
    // MARK: Text Recognition Request Pptions
    var recognitionLevel: VNRequestTextRecognitionLevel = .accurate {
        didSet {
            performOCRRequest()
        }
    }
    
    @IBAction func changeRecognitionLevel(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem else {
            return
        }
        switch selectedItem.identifier!.rawValue {
        case "fast":
            recognitionLevel = .fast
        default:
            recognitionLevel = .accurate
        }
    }
    
    var requestRevision: UInt = 0 {
        didSet {
            performOCRRequest()
        }
    }
    @IBAction func changeRevision(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem else {
            return
        }
        requestRevision = UInt(selectedItem.tag)
    }
    
    var primaryLanguage: String = "en-US" {
        didSet {
            performOCRRequest()
        }
    }
    
    @IBAction func changePrimaryLanguage(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem else {
            return
        }
        primaryLanguage = selectedItem.title
    }
    
    var useCPUOnly: Bool = false {
        didSet { performOCRRequest() }
    }
    
    @IBAction func changeUseCPUOnly(_ sender: NSMenuItem) {
        // Toggle the menu item state.
        if sender.state == .on {
            sender.state = .off
        } else {
            sender.state = .on
        }
        useCPUOnly = (sender.state == .on)
    }
    
    var useLanguageModel: Bool = true {
        didSet { performOCRRequest() }
    }
    
    @IBAction func changeUseLanguageModel(_ sender: NSButton) {
        useLanguageModel = (sender.state == .on)
    }
    
    var minTextHeight: Float = 0 {
        didSet { performOCRRequest() }
    }
    
    @IBAction func changeMinTextHeight(_ sender: NSTextField) {
        minTextHeight = sender.floatValue
    }
    
    var useCustomWords: Bool = false {
        didSet {
            customWordsField!.isEnabled = useCustomWords
            performOCRRequest()
        }
    }
    
    @IBAction func changeUseCustomWords(_ sender: NSButton) {
        useCustomWords = (sender.state == .on)
    }
    
    var customWords: [String] = [] {
        didSet { performOCRRequest() }
    }
    
    @IBAction func changeCustomWords(_ sender: NSTextField) {
        let customWordsString = sender.stringValue
        let substrings = customWordsString.split(separator: " ")
        var result: [String] = []
        for substring in substrings {
            result.append(String(substring))
        }
        customWords = result
    }
    
    var results: [VNRecognizedTextObservation]?
    var requestHandler: VNImageRequestHandler?
    var textRecognitionRequest: VNRecognizeTextRequest!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set up the user interface.
        progressView.isRunning = false
        imageView.delegate = self
        imageView.setupLayers()
        window.makeFirstResponder(imageView)
        
        // Create the request.
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        
        // Set the request revision.
        requestRevision = UInt(textRecognitionRequest.revision)
        
        // Check for available revisions.
        let revisions = VNRecognizeTextRequest.supportedRevisions
        
        // Get the Revision UI prefix from the menu item.
        let revisionPrefix = revisionsPopUpButton.itemTitle(at: 0)
        revisionsPopUpButton.removeItem(at: 0)
        
        for currentRevision in revisions {
            let currentRevisionTitle = "\(revisionPrefix) \(currentRevision)"
            revisionsPopUpButton.addItem(withTitle: currentRevisionTitle)
            revisionsPopUpButton.lastItem?.tag = currentRevision
        }
        
        // Select the current revision.
        revisionsPopUpButton.selectItem(withTag: Int(requestRevision))
        
        // Get the default language.
        primaryLanguage = textRecognitionRequest.recognitionLanguages.first!
    }
    
    func imageDidChange(toImage image: NSImage?) {
        guard let newImage = image else { return }

        if let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            // Create the request handler.
            requestHandler = VNImageRequestHandler(cgImage: cgImage)
            
            // Perform the request.
            performOCRRequest()
        } else {
            // Clean up the Vision objects.
            textRecognitionRequest.cancel()
            requestHandler = nil
            
            // Reset the user interface state.
            imageView.annotationLayer.results = []
            progressView.isRunning = false
        }
    }
    
    func updateRequestParameters() {
        // Update the recognition level.
        switch recognitionLevel {
        case .fast:
            textRecognitionRequest.recognitionLevel = .fast
        default:
            textRecognitionRequest.recognitionLevel = .accurate
        }
        
        // Update the minimum text height.
        textRecognitionRequest.minimumTextHeight = minTextHeight
        
        // Update the language-based correction.
        textRecognitionRequest.usesLanguageCorrection = useLanguageModel
        
        // Update custom words, if any.
        if useCustomWords {
            textRecognitionRequest.customWords = customWords
        } else {
            textRecognitionRequest.customWords = []
        }
        
        // Update the CPU-only flag.
        textRecognitionRequest.usesCPUOnly = useCPUOnly
        
        // Set the request revision.
        textRecognitionRequest.revision = Int(requestRevision)
        
        // Set the primary language.
        textRecognitionRequest.recognitionLanguages = [primaryLanguage]
        
        // Update the the app's supported languages.
        updateAvailableLanguages()
    }
    
    func performOCRRequest() {
        // Reset the previous request.
        textRecognitionRequest.cancel()
        imageView.annotationLayer.results = []
        
        updateRequestParameters()

        if imageView.image != nil {
            progressView.isRunning = true
            
            DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
                do {
                    try self.requestHandler?.perform([self.textRecognitionRequest])
                } catch _ {}
            }
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            self.results = self.textRecognitionRequest.results
            
            // Update the progress view.
            self.progressView.isRunning = false
            
            // Update the results display in the image view.
            if let results = self.results {
                var displayResults: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = []
                for observation in results {
                    let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                    let candidateBounds = (observation.bottomLeft, observation.bottomRight, observation.topRight, observation.topLeft)
                    displayResults.append((candidateBounds, candidate.string))
                }
                
                self.imageView.annotationLayer.results = displayResults
            }
            
            // Update the transcript view.
            if let results = self.results {
                var transcript: String = ""
                for observation in results {
                    transcript.append(observation.topCandidates(1)[0].string)
                    transcript.append("\n")
                }
                self.transcriptView.string = transcript
            }
        }
    }
}

