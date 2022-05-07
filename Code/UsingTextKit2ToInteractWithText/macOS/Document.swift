/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSDocument subclass for this sample.
*/

import Cocoa

class Document: NSDocument {
    override class var autosavesInPlace: Bool { return true }
    
    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let windowController =
            storyboard.instantiateController(
                withIdentifier: NSStoryboard.SceneIdentifier("DocumentWindowController")) as? NSWindowController {
                    addWindowController(windowController)
                }
    }
}
