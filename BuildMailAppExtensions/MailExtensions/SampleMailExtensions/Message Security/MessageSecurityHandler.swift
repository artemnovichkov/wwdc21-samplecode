/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The message security handler.
*/

import MailKit

class MessageSecurityHandler: NSObject, MEMessageSecurityHandler {

    static let shared = MessageSecurityHandler()
    
    enum MessageSecurityError: Error {
        case unverifiedEmails(emailAdresses: [String])
        case noEncodableData
        var errorReason: String {
            switch self {
            case .unverifiedEmails(let emailAdresses):
                return "Invalid email addresses detected.\n\(emailAdresses)"
            case .noEncodableData:
                return "No encodable data found."
            }
        }
    }

    // MARK: - Encoding Messages

    func getEncodingStatus(for message: MEMessage, completionHandler: @escaping (MEOutgoingMessageEncodingStatus) -> Void) {
        // Indicate whether you support signing, encrypting, or both. If the
        // message contains recipients that you can't sign or encrypt for,
        // specify an error and include the addresses in the
        // addressesFailingEncryption array parameter. Update this code with
        // the options your extension supports.
        let invalidRecipients = message.allRecipientAddresses.filter({ address in
            return !SpecialProjectHandler.verifiedEmails.contains(address)
        })
        if !invalidRecipients.isEmpty {
            completionHandler(MEOutgoingMessageEncodingStatus(
                canSign: false,
                canEncrypt: false,
                securityError: MessageSecurityError.unverifiedEmails(emailAdresses: invalidRecipients),
                addressesFailingEncryption: invalidRecipients))
        } else {
            let encoder = MockEncoder.sharedInstance
            let encodingStatus = encoder.securityStatus(for: message)
            completionHandler(encodingStatus)
        }
    }
    
    func encode(_ message: MEMessage, shouldSign: Bool, shouldEncrypt: Bool) async -> MEMessageEncodingResult {
        // The result of the encoding operation. This object contains
        // the encoded message or an error to indicate what failed.
        // The encoder returns an MEMessageEncodingResult populated with either
        // encoded message data or an error.
        return MockEncoder.sharedInstance.encodedMessage(
            for: message,
               shouldSign: shouldSign,
               shouldEncrypt: shouldEncrypt)
    }
          
    // MARK: - Decoding Messages
    
    func decodedMessage(forMessageData data: Data) -> MEDecodedMessage? {
        let decoder = ExampleDecoder.sharedInstance
        // Only decode the message if it is necessary.
        if decoder.shouldDecodeMessage(withData: data) {
            // The decoder returns an MEDecodedMessage populated with decrypted and
            // unsigned RFC822 message data as well as MESecurityInformation for
            // signing and encryption status.
            return decoder.decodedMessage(from: data)
        }
        return nil

    }
 
    // MARK: - Displaying Security Information
    
    func extensionViewController(signers messageSigners: [MEMessageSigner]) -> MEExtensionViewController? {
        
        let controller = ExampleSigningViewController.sharedInstance
        controller.signers = messageSigners
        return controller
    }
}
