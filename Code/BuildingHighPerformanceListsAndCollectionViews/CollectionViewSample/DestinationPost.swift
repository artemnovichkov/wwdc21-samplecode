/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The post object.
*/

import UIKit

struct Section: Identifiable {
    
    enum Identifier: String, CaseIterable {
        case featured = "Featured"
        case all = "All"
    }
    
    var id: Identifier
    var posts: [DestinationPost.ID]
}

struct Asset: Identifiable {
    static let noAsset: Asset = Asset(id: "none", isPlaceholder: false, image: UIImage(systemName: "airplane.circle.fill")!)
    
    var id: String
    var isPlaceholder: Bool
    
    var image: UIImage
    
    func withImage(_ image: UIImage) -> Asset {
        var this = self
        this.image = image
        return this
    }
}

struct DestinationPost: Identifiable {
    
    var id: String
    
    var region: String
    var subregion: String?
    
    var numberOfLikes: Int
    
    var assetID: Asset.ID
    
    init(id: String, region: String, subregion: String? = nil, numberOfLikes: Int, assetID: Asset.ID) {
        self.id = id
        self.region = region
        self.subregion = subregion
        self.numberOfLikes = numberOfLikes
        self.assetID = assetID
    }
}
