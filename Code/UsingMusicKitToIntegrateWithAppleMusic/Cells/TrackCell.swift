/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell view for lists of `Track`s.
*/

import MusicKit
import SwiftUI

/// `TrackCell` is a view that can be used in a SwiftUI `List` to represent a `Track`.
struct TrackCell: View {
    
    // MARK: - Object lifecycle
    
    init(_ track: Track, from album: Album, action: @escaping () -> Void) {
        self.track = track
        self.album = album
        self.action = action
    }
    
    // MARK: - Properties
    
    let track: Track
    let album: Album
    let action: () -> Void
    
    private var subtitle: String {
        var subtitle = ""
        if track.artistName != album.artistName {
            subtitle = track.artistName
        }
        return subtitle
    }
    
    // MARK: - View
    
    var body: some View {
        Button(action: action) {
            MusicItemCell(
                artwork: nil,
                title: track.title,
                subtitle: subtitle
            )
            .frame(minHeight: 50)
        }
    }
}
