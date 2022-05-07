/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's primary view controller.
*/

import Cocoa

class MainViewController: NSViewController {
    /*	User wants to show the stack view window.
		Put this in the area of your project what wants to show the stack view.
 	*/
    @IBAction func showStackView(_ sender: AnyObject) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.stackViewWindowController?.showWindow(self)
        }
    }
    
}
