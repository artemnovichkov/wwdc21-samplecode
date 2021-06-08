/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The group movie watching activity.
*/

import Foundation
import Combine
import GroupActivities
import LinkPresentation
import UniformTypeIdentifiers

// A type that represents a movie to watch with others.
struct Movie: Hashable, Codable {
    var url: URL
    var title: String
    var description: String
    var posterTime: TimeInterval
}

// A group activity to watch a movie together.
struct MovieWatchingActivity: GroupActivity {
    
    // The movie to watch.
    let movie: Movie
    
    // Metadata that the system displays to participants.
    func metadata(_ completion: @escaping (GroupActivityMetadata) -> Void) {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.fallbackURL = movie.url
        metadata.title = movie.title
        completion(metadata)
    }
}
