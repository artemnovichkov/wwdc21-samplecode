/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model for this sample containing the manager and model types.
*/

import UIKit

// Singleton data model.
class DataModelManager {
    static let sharedInstance: DataModelManager = {
        let instance = DataModelManager()
        instance.loadDataModel()
        return instance
    }()
    
    var dataModel: DataModel!
    
    private let dataFileName = "Products"
    
    private func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private func dataModelURL() -> URL {
        let docURL = documentsDirectory()
        return docURL.appendingPathComponent(dataFileName)
    }

    func saveDataModel() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(dataModel) {
            do {
                // Save the 'Products' data file to the Documents directory.
                try encoded.write(to: dataModelURL())
            } catch {
                print("Couldn't write to save file: " + error.localizedDescription)
            }
        }
    }
    
    func loadDataModel() {
        // Load the data model from the 'Products' data file in the Documents directory.
        guard let codedData = try? Data(contentsOf: dataModelURL()) else {
            // No data on disk, create a new data model.
            dataModel = DataModel()
            return
        }
        // Decode the JSON file into a DataModel object.
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(DataModel.self, from: codedData) {
            dataModel = decoded
        }
    }
    
    // MARK: - Accessors
    
    func products() -> [Product] {
        return dataModel.products
    }
    
    func product(fromTitle: String) -> Product? {
        let filteredProducts = dataModel.products.filter { product in
            let productTitle = product.name.lowercased()
            if productTitle == fromTitle.lowercased() { return true } else { return false }
        }
        if filteredProducts.count == 1 {
            return filteredProducts[0]
        } else {
            return nil
        }
    }
    
    func product(fromIdentifier: String) -> Product? {
        let filteredProducts = dataModel.products.filter { product in
            let productIdentifier = product.identifier.uuidString
            if productIdentifier == fromIdentifier { return true } else { return false }
        }
        if filteredProducts.isEmpty {
            fatalError("Can't find product from identifier.")
        }
        return filteredProducts[0]
    }
    
    // MARK: - Actions
     
    func remove(atLocation: Int) {
        dataModel.products.remove(at: atLocation)
    }
    
    func insert(product: Product, atLocation: Int) {
        dataModel.products.insert(product, at: atLocation)
    }

}

// MARK: - Data Model

struct DataModel: Codable {
    
    var products: [Product] = []
    
    private enum CodingKeys: String, CodingKey {
        case products
    }
    
    // MARK: - Codable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(products, forKey: .products)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        products = try values.decode(Array.self, forKey: .products)
    }
    
    init() {
        // No data on disk, read the products from the JSON file.
        products = Bundle.main.decode("products.json")
    }

}

// MARK: Bundle

extension Bundle {
    func decode(_ file: String) -> [Product] {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode([Product].self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }
        return loaded
    }
}

