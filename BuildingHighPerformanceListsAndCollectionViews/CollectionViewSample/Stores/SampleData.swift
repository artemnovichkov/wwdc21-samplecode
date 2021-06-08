/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample data.
*/

import Foundation

struct SampleData {
    static let sectionsStore = AnyModelStore([
        Section(id: .featured, posts: ["a", "b"]),
        Section(id: .all, posts: ["c", "d", "e", "f", "g", "h", "i", "j", "k", "l"])
    ])
    
    static let postsStore = AnyModelStore([
        DestinationPost(id: "a", region: "Peru", subregion: "Cusco", numberOfLikes: 31, assetID: "peru"),
        DestinationPost(id: "b", region: "Caribbean", subregion: "Saint Lucia", numberOfLikes: 25, assetID: "st-lucia"),
        
        DestinationPost(id: "c", region: "Japan", subregion: "Tokyo", numberOfLikes: 16, assetID: "japan"),
        DestinationPost(id: "d", region: "Iceland", subregion: "Reykjavík", numberOfLikes: 9, assetID: "iceland"),
        DestinationPost(id: "e", region: "France", subregion: "Paris", numberOfLikes: 14, assetID: "paris"),
        DestinationPost(id: "f", region: "Italy", subregion: "Capri", numberOfLikes: 11, assetID: "italy"),
        DestinationPost(id: "g", region: "Viet Nam", subregion: "Cat Ba", numberOfLikes: 17, assetID: "vietnam"),
        DestinationPost(id: "h", region: "New Zealand", subregion: nil, numberOfLikes: 5, assetID: "new-zealand"),
        DestinationPost(id: "i", region: "Indonesia", subregion: "Bali", numberOfLikes: 10, assetID: "bali"),
        DestinationPost(id: "j", region: "Ireland", subregion: "Cork", numberOfLikes: 21, assetID: "cork"),
        DestinationPost(id: "k", region: "Chile", subregion: "Patagonia", numberOfLikes: 9, assetID: "patagonia"),
        DestinationPost(id: "l", region: "Cambodia", subregion: nil, numberOfLikes: 14, assetID: "cambodia")
    ])
    
    static let assetsStore = AssetStore()
}
