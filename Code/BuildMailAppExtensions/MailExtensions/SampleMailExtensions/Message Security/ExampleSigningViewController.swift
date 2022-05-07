/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The message security view controller.
*/

import MailKit

class ExampleSigningViewController: MEExtensionViewController {
    
    static let sharedInstance = ExampleSigningViewController()
    
    var signers: [MEMessageSigner]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override var nibName: NSNib.Name? {
        return "ExampleSigningViewController"
    }

}

