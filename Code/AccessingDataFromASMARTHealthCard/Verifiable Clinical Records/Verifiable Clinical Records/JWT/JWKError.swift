/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An error relating to handling JSON Web Keys.
*/

public enum JWKError: Error {
    case missingXComponent
    case missingYComponent
    // Elliptic curve (EC) keys should usually be the only type expected.
    case incorrectKeyType(expected: String, actual: String)
    case unsupportedCurve(crv: String?)
    case keyWithIDNotFound(String)
}
