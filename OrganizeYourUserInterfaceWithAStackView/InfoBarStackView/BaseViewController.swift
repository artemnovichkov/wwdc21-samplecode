/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Base view controller to be subclassed for any view controller in the stack view.
*/

import Cocoa

class BaseViewController: NSViewController, StackItemBody {
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    
    // The original expanded height of this view controller (used to adjust height between disclosure states).
    var savedDefaultHeight: CGFloat = 0
    
    // Subclasses determine the header title.
    func headerTitle() -> String { return "" }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remember the default height for disclosing later (subclasses can determine this value in their own viewDidLoad).
        savedDefaultHeight = view.bounds.height
    }
    
    // MARK: - StackItemContainer
    lazy var stackItemContainer: StackItemContainer? = {
        /*	We conditionally decide what flavor of header disclosure to use by "DisclosureTriangleAppearance" compilation flag,
			which is defined in “Active Compilation Conditions” Build Settings (for passing conditional compilation
         	flags to the Swift compiler). If you want to use the non-triangle disclosure version, remove that flag.
		*/
        var storyboardIdentifier: String
#if DisclosureTriangleAppearance
        storyboardIdentifier = "HeaderTriangleViewController"
#else
        storyboardIdentifier = "HeaderViewController"
#endif
        let storyboard = NSStoryboard(name: "HeaderViewController", bundle: nil)
        guard let headerViewController = storyboard.instantiateController(withIdentifier: storyboardIdentifier) as? HeaderViewController else {
            return .none
        }
        
        headerViewController.title = self.headerTitle()
        
        return StackItemContainer(header: headerViewController, body: self)
    }()
    
}

extension BaseViewController {
    
    /// Encode state. Helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        // Encode the disclosure state.
        if let container = stackItemContainer {
            // Use the header's title as the encoding key.
            coder.encode(container.state, forKey: String(describing: headerTitle()))
        }
        super.encodeRestorableState(with: coder)
    }
    
    /// Decode state. Helps restore any previously stored state.
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
 
        // Restore the disclosure state, use the header's title as the decoding key.
        if let disclosureState = coder.decodeObject(forKey: headerTitle()) as? NSControl.StateValue {
            if let container = stackItemContainer {
                container.state = disclosureState

                // Expand/collapse the container's body view controller.
                switch container.state {
                case .on:
                    container.body.show(animated: false)
                case .off:
                    container.body.hide(animated: false)
                default: break
                }
                // Update the header's disclosure.
                container.header.update(toDisclosureState: container.state)
            }
        }
    }
    
}

