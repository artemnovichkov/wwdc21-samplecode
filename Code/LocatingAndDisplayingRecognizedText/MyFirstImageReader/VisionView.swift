/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom view that renders the OCR results. It supports drag and drop and Continuity Camera.
*/

import Cocoa
import Vision

// A delegate protocol to communicates changes to the VisionView.
protocol VisionViewDelegate: AnyObject {
    func imageDidChange(toImage image: NSImage?)
}

class VisionView: NSView, NSServicesMenuRequestor {
    
    weak var delegate: (AppDelegate & VisionViewDelegate)?
    
    var image: NSImage? {
        didSet {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.0)
            
            // Update the view contents.
            imageLayer.contents = self.image
            if let newImage = image {
                let newSize = newImage.size
                updateContentSize(w: CGFloat(newSize.width), h: CGFloat(newSize.height))
            } else {
                updateContentSize(w: 0, h: 0)
            }
            
            CATransaction.commit()
            
            if let delegate = self.delegate {
                delegate.imageDidChange(toImage: image)
            }
        }
    }
    
    var imageLayer: CALayer = CALayer()
    var annotationLayer: AnnotationLayer = AnnotationLayer()
    
    // MARK: Initialization
    func commonInit() {
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL])
        wantsLayer = true
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: Layer Hierarchy
    func setupLayers() {
        guard let layer = self.layer else { return }
        imageLayer.frame = layer.bounds
        layer.addSublayer(imageLayer)
        
        annotationLayer.bounds = layer.bounds
        annotationLayer.opacity = 0.0
        layer.insertSublayer(annotationLayer, above: imageLayer)
    }
    
    func updateContentSize(w width: CGFloat, h height: CGFloat) {
        let newFrame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Update the image layer.
        imageLayer.frame = newFrame
        setFrameSize(NSSize(width: width, height: height))
        
        // Update the annotation layer.
        annotationLayer.frame = newFrame
        annotationLayer.setNeedsDisplay()
    }
    
    // MARK: Continuity Camera Support
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if let pasteboardType = returnType, NSImage.imageTypes.contains(pasteboardType.rawValue) {
            return self
        } else {
            return nil
        }
    }
    
    func readSelection(from pasteboard: NSPasteboard) -> Bool {
        guard pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else {
            return false
        }
        
        if let nsImage = NSImage(pasteboard: pasteboard) {
            self.image = nsImage
            return true
        }
        
        return false
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
    
    // MARK: NSDraggingDestination Protocol
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        guard
            pboard.canReadItem(withDataConformingToTypes: [kUTTypeFileURL as String]),
            let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [ NSURL ],
            let firstURL = urls.first
            else { return false }
        self.image = NSImage(contentsOf: firstURL as URL)
        return true
    }
}

