/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's application delegate.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    /*	Pre-load the stack view window controller and its content view controller.
     	Used for state restoration and opening its window via the "Show Stack View" button.
    */
    var stackViewWindowController =
        NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "WindowController") as? WindowController
}

