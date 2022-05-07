/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This sample's main data model describing the product.
*/

import Foundation

struct Product: Hashable, Codable {

    // MARK: - Types

    private enum CoderKeys: String, CodingKey {
        case name
        case imageName
        case year
        case price
        case identifier
    }

    // MARK: - Properties
    
    var name: String
    var imageName: String
    var year: Int
    var price: Double
    var identifier: UUID
        
    // MARK: - Initializers
    
    init(identifier: UUID, name: String, imageName: String, year: Int, price: Double) {
        self.identifier = identifier
        self.name = name
        self.imageName = imageName
        self.year = year
        self.price = price
    }
    
    // MARK: - Data Representation
    
    // Given the endoded JSON representation, return a product instance.
    func decodedProduct(data: Data) -> Product? {
        var product: Product?
        let decoder = JSONDecoder()
        if let decodedProduct = try? decoder.decode(Product.self, from: data) {
            product = decodedProduct
        }
        return product
    }
    
    // MARK: - Codable
    
    // For NSUserActivity scene-based state restoration.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(year, forKey: .year)
        try container.encode(price, forKey: .price)
        try container.encode(identifier, forKey: .identifier)
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        name = try values.decode(String.self, forKey: .name)
        year = try values.decode(Int.self, forKey: .year)
        price = try values.decode(Double.self, forKey: .price)
        imageName = try values.decode(String.self, forKey: .imageName)

        let decodedIdentifier = try values.decode(String.self, forKey: .identifier)
        identifier = UUID(uuidString: decodedIdentifier)!
    }
    
}
