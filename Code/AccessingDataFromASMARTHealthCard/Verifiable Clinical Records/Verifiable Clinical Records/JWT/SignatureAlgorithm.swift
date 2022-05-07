/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An enumeration representing the supported signature algorithms for the JSON Web Signature (JWS).
*/

/*
 The supported signature algorithms.
 For more information, see https://datatracker.ietf.org/doc/html/rfc7518#section-3.1.
 */
enum SignatureAlgorithm: String, Codable {
    case es256 = "ES256"
}
