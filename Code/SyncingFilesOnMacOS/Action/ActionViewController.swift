/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A controller that provide the user interface for actions.
*/

import Cocoa
import FileProviderUI
import Common
import Extension
import os.log

protocol ConcreteActionViewController: NSViewController {
    func prepareForDisplay()
}

public class ActionViewController: FPUIActionExtensionViewController {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "action")

    var domain: NSFileProviderDomain {
        guard let identifier = extensionContext.domainIdentifier else {
            fatalError("not expected to be called with default domain")
        }
        return NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(rawValue: identifier.rawValue), displayName: "")
    }

    func prepare(_ childViewController: ConcreteActionViewController) {
        addChild(childViewController)
        view.addSubview(childViewController.view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: childViewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: childViewController.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: childViewController.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: childViewController.view.bottomAnchor)
        ])

        childViewController.prepareForDisplay()
    }

    public override func prepare(forError error: Error) {
        prepare(AuthenticationViewController())
    }

    override public func loadView() {
        self.view = NSView()
    }

    public override func prepare(forAction actionIdentifier: String, itemIdentifiers: [NSFileProviderItemIdentifier]) {
        // Each action that is implemented must be added to this switch statement.
        switch actionIdentifier {
        case "com.example.apple-samplecode.FruitBasket.ConflictAction":
            prepare(ConflictViewController(itemIdentifiers))
        default:
            fatalError()
        }
    }
}
