/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A structure that represents a JSON Web Key (JWK).
*/

import Foundation
import CryptoKit

public struct JWK: Codable {
    
    public let kty: String
    public let crv: String?
    public let alg: String?
    public let ext: Bool?
    public let e: String?
    public let n: String?
    public let x: String?
    public let y: String?
    public let kid: String?
    public let keyOps: [String]?
    public let use: String?
    
    // MARK: Conversion
    
    /// Returns the public key as a `Data` instance.
    public func asP256PublicKey() throws -> P256.Signing.PublicKey {
        
        guard kty == "EC" else {
            throw JWKError.incorrectKeyType(expected: "EC", actual: kty)
        }
        
        guard crv == "P-256" else {
            throw JWKError.unsupportedCurve(crv: crv)
        }
        
        let rawKey = try asRawPublicKey()
        return try P256.Signing.PublicKey(rawRepresentation: rawKey)
    }
    
    private func asRawPublicKey() throws -> Data {
        guard let x = x else {
            throw JWKError.missingXComponent
        }
        
        guard let y = y else {
            throw JWKError.missingYComponent
        }
        
        let xData = try Base64URL.decode(x)
        let yData = try Base64URL.decode(y)
        let pubkey = xData + yData
        return pubkey
    }
}
