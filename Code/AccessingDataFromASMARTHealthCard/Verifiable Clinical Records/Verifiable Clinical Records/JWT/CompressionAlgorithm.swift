/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An enumeration representing the supported JSON Web Signature (JWS) compression algorithms.
*/

public enum CompressionAlgorithm: String, Codable {
    
    /// DEFLATE, also known as ZLIB.
    /// For more information, see https://tools.ietf.org/html/rfc1951.
    case deflate = "DEF"
}
