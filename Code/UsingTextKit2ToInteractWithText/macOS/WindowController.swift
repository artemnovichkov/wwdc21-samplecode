/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main window controller for this sample.
*/

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // NSWindows loaded from the storyboard will be cascaded based on the original frame of the window in the storyboard.
        shouldCascadeWindows = true
    }

    override func windowTitle(forDocumentDisplayName displayName: String) -> String {
        return "Layout Text with TextKit 2"
    }
}
