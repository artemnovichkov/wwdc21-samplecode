/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model that creates a custom catalog with a reference signature and metadata.
*/

import ShazamKit

struct CatalogProvider {
    
    static func catalog() throws -> SHCustomCatalog? {
        guard let signaturePath = Bundle.main.url(forResource: "FoodMath", withExtension: "shazamsignature") else {
            return nil
        }
        
        let signatureData = try Data(contentsOf: signaturePath)
        let signature = try SHSignature(dataRepresentation: signatureData)
        
        let mediaItem = SHMediaItem(properties: [.title: "Learn with Neil", .subtitle: "Count on Me", .episode: 3, .teacher: "Neil Foley"])
        
        let customCatalog = SHCustomCatalog()
        try customCatalog.addReferenceSignature(signature, representing: [mediaItem])
        
        return customCatalog
    }
}
