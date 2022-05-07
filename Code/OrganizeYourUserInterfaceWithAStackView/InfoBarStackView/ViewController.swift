/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View Controller controlling the NSStackView.
*/

import Cocoa

class ViewController: NSViewController, StackItemHost {
    @IBOutlet weak var stackView: CustomStackView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load and install all the view controllers from the storyboard in the following order.
        addViewController(withIdentifier: "FormViewController")
        addViewController(withIdentifier: "TableViewController")
        addViewController(withIdentifier: "CollectionViewController")
        addViewController(withIdentifier: "OtherViewController")
    }

/// - Tag: Configure
    /// Used to add a particular view controller as an item to the stack view.
    private func addViewController(withIdentifier identifier: String) {
        let storyboard = NSStoryboard(name: "StackItems", bundle: nil)
        guard let viewController =
            storyboard.instantiateController(withIdentifier: identifier) as? BaseViewController else { return }

        // Set up the view controller's item container.
        let stackItemContainer = viewController.stackItemContainer!
        
        // Set the appropriate action function for toggling the disclosure state of each header.
        stackItemContainer.header.disclose = {
         	self.disclose(viewController.stackItemContainer!)
        }
        
        // Add the header view.
        stackView.addArrangedSubview(stackItemContainer.header.viewController.view)
        
        // Add the main body content view.
        stackView.addArrangedSubview(stackItemContainer.body.viewController.view)

        // Set the default disclosure states (state restoration may restore them to their requested value).
   		show(stackItemContainer, animated: false)
    }
    
}

// MARK: -

// To adjust the origin of stack view in its enclosing scroll view.
class CustomStackView: NSStackView {
    override var isFlipped: Bool { return true }
}
