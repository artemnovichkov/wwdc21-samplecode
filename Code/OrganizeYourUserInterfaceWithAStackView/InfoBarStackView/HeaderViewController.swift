/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View Controller managing the header user interface for each stack item, containing the title and disclosure button.
*/

import Cocoa

class HeaderView: NSView {
    override func updateLayer () {
        // Update the color in case we switched beween light and dark mode.
        layer?.backgroundColor = NSColor(named: "HeaderColor")?.cgColor
    }
}

class HeaderViewController: NSViewController, StackItemHeader {
    @IBOutlet weak var headerTextField: NSTextField!
    @IBOutlet weak var showHideButton: NSButton!
    
    var disclose: (() -> Swift.Void)? // This state will be set by the stack item host.
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerTextField.stringValue = title!
        
#if !DisclosureTriangleAppearance
        // Track the mouse movement so we can show/hide the disclosure button.
        let trackingArea =
            NSTrackingArea(rect: self.view.bounds,
                           options: [NSTrackingArea.Options.mouseEnteredAndExited,
                                     NSTrackingArea.Options.activeAlways,
                                     NSTrackingArea.Options.inVisibleRect],
                           owner: self,
                           userInfo: nil)
        
        // For the non-triangle disclosure button header,
        // we want the button to auto hide/show on mouse tracking.
        view.addTrackingArea(trackingArea)
#endif
    }
    
    // MARK: - Actions
    
    @IBAction func showHidePressed(_ sender: AnyObject) {
        disclose?()
    }
    
    // MARK: - Mouse tracking
    
    override func mouseEntered(with theEvent: NSEvent) {
        // Mouse entered the header area, show disclosure button.
        super.mouseEntered(with: theEvent)
        showHideButton.isHidden = false
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        // Mouse exited the header area, hide disclosure button.
        super.mouseExited(with: theEvent)
        showHideButton.isHidden = true
    }
    
    // MARK: - StackItemHeader Procotol
    
    func update(toDisclosureState: NSControl.StateValue) {
     	showHideButton.state = toDisclosureState
    }
    
}
