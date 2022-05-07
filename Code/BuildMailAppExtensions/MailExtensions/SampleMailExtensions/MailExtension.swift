/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The mail extension.
*/

import MailKit

class MailExtension: NSObject, MEExtension {
    func handlerForContentBlocker() -> MEContentBlocker {
        // Use a shared instance for all messages because there's
        // no state associated with a content blocker.
        return ContentBlocker.shared
    }

    func handlerForMessageActions() -> MEMessageActionHandler {
        // Use a shared instance for all message because there's
        // no state associated with performing actions.
        return MessageActionHandler.shared
    }

    func handler(for session: MEComposeSession) -> MEComposeSessionHandler {
        // Create a unique instance because each compose window is separate.
        return ComposeSessionHandler()
    }

    func handlerForMessageSecurity() -> MEMessageSecurityHandler {
        // Use a shared instance for all messages because there's
        // no state associated with the security handler.
        return MessageSecurityHandler.shared
    }

}

