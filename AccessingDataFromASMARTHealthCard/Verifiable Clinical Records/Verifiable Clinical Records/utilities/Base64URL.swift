/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility class that provides a simple Base64URL decoding implementation.
*/

import Foundation

/**
 A simple implementation of Base64URL decoding.
 For more information, see https://tools.ietf.org/html/rfc4648#section-5.
 */
public struct Base64URL {
    
    public static func decode(_ value: String) throws -> Data {
        var base64 = value
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        
        // Properly pad the string.
        switch base64.count % 4 {
        case 0: break
        case 2: base64 += "=="
        case 3: base64 += "="
        default: throw Base64URLError.invalidBase64
        }
        
        guard let data = Data(base64Encoded: base64) else {
            throw Base64URLError.unableToCreateDataFromBase64String(base64)
        }
        return data
    }
}

public enum Base64URLError: Error {
    case invalidBase64
    case unableToCreateDataFromBase64String(String)
}
