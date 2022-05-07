/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A mock encoder and decoder for use with message security.
 See https://developer.apple.com/library/archive/technotes/tn2326/_index.html
 for information on creating certificates for testing.
*/

import MailKit
import Foundation

class MockEncoder {
    static let sharedInstance = MockEncoder()
    
    private func shouldEncode(_ message: MEMessage) -> Bool {
        true
    }
    
    func securityStatus(for message: MEMessage) -> MEOutgoingMessageEncodingStatus {
        MEOutgoingMessageEncodingStatus(
            canSign: true,
            canEncrypt: true,
            securityError: nil,
            addressesFailingEncryption: [])
    }
    
    func encodedMessage(for message: MEMessage, shouldSign: Bool, shouldEncrypt: Bool) -> MEMessageEncodingResult {
        guard let data = message.rawData, shouldEncode(message) == true else {
            return MEMessageEncodingResult(
                encodedMessage: nil,
                signingError: nil,
                encryptionError: MessageSecurityHandler.MessageSecurityError.noEncodableData)
        }
        return MEMessageEncodingResult(
            encodedMessage: MEEncodedOutgoingMessage(
                rawData: data,
                isSigned: true,
                isEncrypted: true),
            signingError: nil,
            encryptionError: nil)
        }
}

class ExampleDecoder {
    static let sharedInstance = ExampleDecoder()
    
    func shouldDecodeMessage(withData: Data) -> Bool {
        true
    }
    
    func decodedMessage(from data: Data) -> MEDecodedMessage {
        MEDecodedMessage(
            data: data,
            securityInformation: MEMessageSecurityInformation(
                signers: [],
                isEncrypted: true,
                signingError: nil,
                encryptionError: nil))
    }
}
