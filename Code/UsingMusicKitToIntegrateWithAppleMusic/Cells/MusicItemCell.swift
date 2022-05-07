/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell view for lists of `MusicItem`s.
*/

import MusicKit
import SwiftUI

/// `MusicItemCell` is a view that can be used in a SwiftUI `List` to represent a `MusicItem`.
struct MusicItemCell: View {
    
    // MARK: - Properties
    
    let artwork: Artwork?
    let title: String
    let subtitle: String
    
    // MARK: - View
    
    var body: some View {
        HStack {
            if let existingArtwork = artwork {
                VStack {
                    Spacer()
                    ArtworkImage(existingArtwork, width: 56)
                        .cornerRadius(6)
                    Spacer()
                }
            }
            VStack(alignment: .leading) {
                Text(title)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .padding(.top, -4.0)
                }
            }
        }
    }
}
