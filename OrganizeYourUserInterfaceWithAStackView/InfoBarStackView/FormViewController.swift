/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Stack item view controller for an example "form" UI.
*/

import Cocoa

class FormViewController: BaseViewController, NSTextFieldDelegate {
    @IBOutlet weak var textField: NSTextField!
    
    override func headerTitle() -> String { return NSLocalizedString("Form Header Title", comment: "") }
    
    // MARK: - NSTextFieldDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        // Invalidate state restoration, which will in turn eventually call "encodeRestorableState".
        invalidateRestorableState()
    }
    
}

// MARK: - State Restoration

extension FormViewController {
    // Restorable key for the edit field.
    private static let formTextKey = "formTextKey"
    
/// - Tag: FormRestoration
    /// Encode state. Helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        
        coder.encode(textField.stringValue, forKey: FormViewController.formTextKey)
        super.encodeRestorableState(with: coder)
    }
    
    /// Decode state. Helps restore any previously stored state.
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        if let restoredText = coder.decodeObject(forKey: FormViewController.formTextKey) as? String {
            textField.stringValue = restoredText
        }
    }
    
}
