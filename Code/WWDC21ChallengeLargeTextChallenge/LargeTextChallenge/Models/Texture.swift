/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Texture model for loading the textures.json data.
*/

import SwiftUI

struct Texture: Hashable, Codable, Identifiable {
    let id: Int
    let name: String
    fileprivate let imageName: String
}

extension Texture {
    var image: Image {
        Image(imageName)
    }
}
