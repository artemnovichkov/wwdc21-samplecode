/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A controller for a mock authentication view.
*/

import Cocoa
import Common
import Extension
import FileProviderUI
import os.log

class AuthenticationViewController: NSViewController, ConcreteActionViewController {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "auth")

    private let port: in_port_t

    init() {
        self.port = defaultPort

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var nibName: NSNib.Name? {
         return NSNib.Name("AuthenticationViewController")
    }

    var actionViewController: ActionViewController! {
        return parent as? ActionViewController
    }

    func prepareForDisplay() {

    }

    @IBAction func authenticate(_ sender: Any) {
        async {
            // Look up the secret via the server and set it.
            // This is meant to be a demonstration of authentication related flows,
            // and is intentionally insecure.
            let conn = DomainConnection(domainIdentifier: self.actionViewController.domain.identifier.rawValue, secret: "",
                                              hostname: UserDefaults.sharedContainerDefaults.hostname, port: self.port)
            let avc = self.actionViewController!
            let domain = avc.domain
            do {
                let resp = try await conn.makeJSONCall(AccountService.ListAccountParameter())
                // Find the secret for the domain being authenticated.
                guard let account = resp.accounts.first(where: { $0.identifier == domain.identifier.rawValue }) else {
                    throw CommonError.domainNotFound
                }
                UserDefaults.sharedContainerDefaults.set(secret: account.secret, for: NSFileProviderDomainIdentifier(rawValue: account.identifier))

                guard let manager = NSFileProviderManager(for: domain) else {
                    throw CommonError.domainNotFound
                }

                do {
                    try await manager.signalErrorResolved(NSFileProviderError(.notAuthenticated))
                    self.logger.info("✅ succeeded to signal insufficientQuota error as resolved for \(domain.displayName)")
                    avc.extensionContext.completeRequest()
                } catch let error as NSError {
                    self.logger.error("❌ failed to signal insufficientQuota error as resolved for \(domain.displayName): \(error)")
                    throw error
                }
            } catch {
                avc.extensionContext.cancelRequest(withError: error)
            }
        }
    }

    @IBAction func cancel(_ sender: Any) {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.actionViewController.extensionContext.cancelRequest(withError: error)
    }
}
