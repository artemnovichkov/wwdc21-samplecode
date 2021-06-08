/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model object that represents the different types of classes.
*/

import Foundation

struct Episode: Identifiable {
    let id = UUID()
    let title: String
    let number: Int
    
    var subtitle: String {
        return "Episode \(number)"
    }
    
    static let allEpisodes = [
        Episode(title: "Addition & Subtraction", number: 1),
        Episode(title: "Multiplication & Division", number: 2),
        Episode(title: "Count on Me", number: 3),
        Episode(title: "Practice Makes Perfect", number: 4)
    ]
}
