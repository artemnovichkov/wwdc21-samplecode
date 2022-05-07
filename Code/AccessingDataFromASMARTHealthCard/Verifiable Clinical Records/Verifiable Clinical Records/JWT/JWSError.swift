/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An error relating to handling a JSON Web Signature (JWS).
*/

enum JWSError: Error {
    
    // A JWS should have 3 segments: header, payload, and signature.
    case invalidNumberOfSegments(Int)
}
