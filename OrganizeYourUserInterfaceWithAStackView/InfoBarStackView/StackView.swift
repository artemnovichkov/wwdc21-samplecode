/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Classes and protocols for handling NSStackView architecture.
*/

import Cocoa

// MARK: Protocol Delarations -

// The hosting object containing both the header and body.
protocol StackItemHost: AnyObject {
    func disclose(_ stackItem: StackItemContainer)
}

// The object containing the header portion.
protocol StackItemHeader: AnyObject {
    var viewController: NSViewController { get }
    var disclose: (() -> Swift.Void)? { get set }
    
    func update(toDisclosureState: NSControl.StateValue)
}

// The object containing the main body portion.
protocol StackItemBody: AnyObject {
    var viewController: NSViewController { get }
    
    func show(animated: Bool)
    func hide(animated: Bool)
}

// MARK: - Protocol implementations

extension StackItemHost {
    /// The action function for the disclosure button.
    func disclose(_ stackItem: StackItemContainer) {
        switch stackItem.state {
        case .on:
            hide(stackItem, animated: true)
            stackItem.state = .off
        case .off:
            show(stackItem, animated: true)
			stackItem.state = .on
        default: break
        }
    }
    
    func show(_ stackItem: StackItemContainer, animated: Bool) {
        // Show the stackItem's body content.
        stackItem.body.show(animated: animated)
        
        if let bodyViewController = stackItem.body.viewController as? BaseViewController {
            // Tell the view controller to update its disclosure state.
            // This will in turn eventually call "encodeRestorableState".
            bodyViewController.invalidateRestorableState()
        }
        
        // Update the stackItem's header disclosure button state.
        stackItem.header.update(toDisclosureState: .on)
    }
    
    func hide(_ stackItem: StackItemContainer, animated: Bool) {
        // Hide the stackItem's body content.
        stackItem.body.hide(animated: animated)
        
        if let bodyViewController = stackItem.body.viewController as? BaseViewController {
            // Tell the view controller to update its disclosure state.
            // This will in turn eventually call "encodeRestorableState".
            bodyViewController.invalidateRestorableState()
        }
        
        // Update the stackItem's header disclosure button state.
        stackItem.header.update(toDisclosureState: .off)
    }
    
}

// MARK: -

extension StackItemHeader where Self: NSViewController {
    var viewController: NSViewController { return self }
}

// MARK: -

extension StackItemBody where Self: NSViewController {
    var viewController: NSViewController { return self }
    
    func animateDisclosure(disclose: Bool, animated: Bool) {
        if let viewController = self as? BaseViewController {
            if let constraint = viewController.heightConstraint {
                let heightValue = disclose ? viewController.savedDefaultHeight : 0
                if animated {
                    NSAnimationContext.runAnimationGroup({ (context) -> Void in
                        context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                        constraint.animator().constant = heightValue
                        
                    }, completionHandler: { () -> Void in
                        // animation completed
                    })
                } else {
                    constraint.constant = heightValue
                }
            }
        }
    }
    
    func show(animated: Bool) {
        animateDisclosure(disclose: true, animated: animated)
    }
    
    func hide(animated: Bool) {
        animateDisclosure(disclose: false, animated: animated)
    }
    
}

// MARK: -

/// - Tag: Container
class StackItemContainer {
    // Disclosure state of this container.
    var state: NSControl.StateValue
    
    let header: StackItemHeader
    let body: StackItemBody
    
    init(header: StackItemHeader, body: StackItemBody) {
        self.header = header
        self.body = body
        self.state = .on
    }
    
}
