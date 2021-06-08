/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model object describing the product displayed in both main and results tables.
*/

import Foundation
import UIKit

struct Product: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case title
        case yearIntroduced
        case introPrice
        case color
    }
    
    enum ColorKind: Int {
        case red = 0
        case green = 1
        case blue = 2
        case undedefined = 3
    }

    // MARK: - Properties
    
    var title: String
    var yearIntroduced: Date
    var introPrice: Double
    var color: Int
    
    private let priceFormatter = NumberFormatter()
    private let yearFormatter = DateFormatter()

    // MARK: - Initializers

    func setup() {
        priceFormatter.numberStyle = .currency
        priceFormatter.formatterBehavior = .default
        
        yearFormatter.dateFormat = "yyyy"
    }
    
    init(title: String, yearIntroduced: Date, introPrice: Double, color: ColorKind) {
        self.title = title
        self.yearIntroduced = yearIntroduced
        self.introPrice = introPrice
        self.color = color.rawValue
        setup()
    }
    
    // MARK: - Formatters
    
    func formattedPrice() -> String? {
        /** Build the price string.
            Use the priceFormatter to obtain the formatted price of the product.
        */
        return priceFormatter.string(from: NSNumber(value: introPrice))
    }
    
    func formattedDate() -> String? {
        /** Build the date string.
            Use the yearFormatter to obtain the formatted year introduced.
        */
        return yearFormatter.string(from: yearIntroduced)
    }
    
    // MARK: - Codable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(yearIntroduced, forKey: .yearIntroduced)
        try container.encode(introPrice, forKey: .introPrice)
        try container.encode(color, forKey: .color)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        yearIntroduced = try values.decode(Date.self, forKey: .yearIntroduced)
        introPrice = try values.decode(Double.self, forKey: .introPrice)
        color = try values.decode(Int.self, forKey: .color)
        setup()
    }
    
}
