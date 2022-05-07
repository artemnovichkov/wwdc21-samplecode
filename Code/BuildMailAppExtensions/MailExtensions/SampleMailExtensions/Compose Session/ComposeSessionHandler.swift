/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The compose session handler.
*/

import MailKit

class ComposeSessionHandler: NSObject, MEComposeSessionHandler {

    func mailComposeSessionDidBegin(_ session: MEComposeSession) {
        // Perform any setup necessary for handling the compose session.
    }
    
    func mailComposeSessionDidEnd(_ session: MEComposeSession) {
        // Perform any cleanup now that the compose session is over.
        SpecialProjectHandler.sharedHandler.selectedSpecialProject = nil
    }
    
    // MARK: - Annotating Address Tokens

    func annotateAddressesForSession(_ session: MEComposeSession) async -> [String: MEAddressAnnotation] {
        var annotations: [String: MEAddressAnnotation] = [:]
        
        // Iterate through all the recipients in the message.
        for address in session.mailMessage.allRecipientAddresses {
            // Annotate invalid recipients with an error.
            if !SpecialProjectHandler.verifiedEmails.contains(address) {
                let message = "\(SpecialProjectHandler.bannedDomain) is not a valid domain"
                let annotation = MEAddressAnnotation.error(withLocalizedDescription: message)
                
                // Add the annotation to the results dictionary.
                annotations[address] = annotation
            }
        }
        
        return annotations
    }

    // MARK: - Displaying Custom Compose Options

    func viewController(for session: MEComposeSession) -> MEExtensionViewController {
        return ComposeSessionViewController(nibName: "ComposeSessionViewController", bundle: Bundle.main)
    }
    
    // MARK: - Adding Custom Headers

    func additionalHeaders(for session: MEComposeSession) -> [String: [String]] {
        // To insert custom headers into a message, return a dictionary with
        // the key and an array of one or more values.
        guard let project = SpecialProjectHandler.sharedHandler.selectedSpecialProject else {
            return [:]
        }
        return [SpecialProjectHandler.specialProjectsHeader: [project.rawValue]]
    }
    
    // MARK: - Confirming Message Delivery

    enum ComposeSessionError: LocalizedError {
        case invalidRecipientDomain
        
        var errorDescription: String? {
            switch self {
            case .invalidRecipientDomain:
                return "(SpecialProjectHandler.bannedDomain) is not a valid recipient domain"
            }
        }
    }
    
    func allowMessageSendForSession(_ session: MEComposeSession) async throws {
        // Before Mail sends a message, your extension can validate the
        // contents of the compose session. If the message isn't ready to be
        // sent, throw an error.
        if session.mailMessage.allRecipientAddresses.contains(where: { $0.hasSuffix(SpecialProjectHandler.bannedDomain) }) {
            throw ComposeSessionError.invalidRecipientDomain
        }
    }
}

