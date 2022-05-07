/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main window.
*/

import Cocoa

class VisionWindow: NSWindow {
    @IBOutlet weak var imageView: VisionView!
    
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        return imageView
    }
}
