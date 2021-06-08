/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection of JWK's (JSON Web Keys).
*/

public struct JWKSet: Codable {
    
    public let keys: [JWK]
    
    /// Returns the key with the given id, if found. If not throws `JWKError.keyWithIDNotFound`.
    public func key(with id: String) throws -> JWK {
        guard let key = keys.first(where: { $0.kid == id }) else {
            throw JWKError.keyWithIDNotFound(id)
        }
        return key
    }
}
