/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Stack item view controller for a very simple UI with buttons.
*/

import Cocoa

class OtherViewController: BaseViewController {
    override func headerTitle() -> String { return NSLocalizedString("Other Header Title", comment: "") }
    
    // MARK: - Actions
    
    @IBAction func leftButtonAction(_ sender: AnyObject) {
        debugPrint("left button clicked")
    }
    
    @IBAction func rightButtonAction(_ sender: AnyObject) {
        debugPrint("right button clicked")
    }
    
}
