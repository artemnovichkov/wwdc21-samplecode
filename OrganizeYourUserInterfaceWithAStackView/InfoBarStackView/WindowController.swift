/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's application's primary window controller.
*/

import Cocoa

class WindowController: NSWindowController, NSWindowRestoration {
    
    // MARK: - Window Controller Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        /*	We support state restoration for this window and all its embedded view controllers.
        	In order for all the view controllers to be restored, this window must be restorable too.
         	This can also be done in the storyboard.
		*/
        window?.isRestorable = true
        window?.identifier = NSUserInterfaceItemIdentifier("StackWindow")
        
        // This will ensure restoreWindow will be called.
        window?.restorationClass = WindowController.self
    }
    
    // MARK: - Window Restoration
    
    /// Sent to request that this window be restored.
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier,
                              state: NSCoder,
                              completionHandler: @escaping (NSWindow?, Error?) -> Swift.Void) {
        let identifier = identifier.rawValue
        
        var restoreWindow: NSWindow? = nil
        if identifier == "StackWindow" { // This is the identifier for the NSWindow.
            // We didn't create the window, it was created from the storyboard.
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                restoreWindow = appDelegate.stackViewWindowController?.window
            }
        }
        completionHandler(restoreWindow, nil)
    }
}

