/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A struct that represents a JSON Web Signature (JWS).
*/

import Foundation

/**
  A JSON Web Signature as defined by https://tools.ietf.org/html/rfc7515.
 */
struct JWS: Codable {
    
    public let header: String
    
    public let payloadString: String
    
    public let payload: Data
    
    public let signature: String
    
    public init(from compactSerialization: String) throws {
        let (headerString, payloadString, signatureString) = try Self.split(compactSerialization: compactSerialization)
        
        let headerData = try Base64URL.decode(headerString)
        let jsonDecoder = JSONDecoder()
        let parsedHeader = try jsonDecoder.decode(JWSHeader.self, from: headerData)
        
        var payload = try Base64URL.decode(payloadString)
        if parsedHeader.zip == .deflate {
            payload = try payload.decompress()
        }
        
        self.init(header: headerString, payloadString: payloadString, payload: payload, signature: signatureString)
    }
    
    public init(header: String, payloadString: String, payload: Data, signature: String) {
        self.header = header
        self.payloadString = payloadString
        self.payload = payload
        self.signature = signature
    }
    
    private static func split(compactSerialization: String) throws -> (String, String, String) {
        let parts = compactSerialization.split(separator: ".").map { String($0) }
        guard parts.count == 3 else {
            throw JWSError.invalidNumberOfSegments(parts.count)
        }
        
        return (parts[0], parts[1], parts[2])
    }
}

struct JWSHeader: Codable {
    
    public let alg: SignatureAlgorithm
    
    public let kid: String
    
    public let typ: String?
    
    public let zip: CompressionAlgorithm
}
