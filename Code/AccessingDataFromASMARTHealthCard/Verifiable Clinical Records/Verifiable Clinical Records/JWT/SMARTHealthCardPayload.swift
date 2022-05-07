/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The payload for a SMART health Card.
*/

import Foundation

struct SMARTHealthCardPayload: Codable {
    
    public struct VC: Codable {
        
        public let type: [String]
        
         public let credentialSubject: CredentialSubject
    }
    
    /// The "Issuer" field.
    public let iss: String
    
    /// The "Not before" field.
    public let nbf: Double?
    
    /// The "Expires at" field.
    public let exp: Double?
    
    /// The verifiable credential field.
    public let vc: VC
}

struct CredentialSubject: Codable {
    
    public let fhirVersion: String
    
    // Implement fhirBundle here using the FHIRModels Swift Package
}
