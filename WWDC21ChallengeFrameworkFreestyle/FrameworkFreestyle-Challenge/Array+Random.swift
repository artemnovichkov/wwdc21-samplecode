/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension on Array that returns a random element from the array.
*/

import Foundation

extension Array {
    /// Returns a randomly selected element from the array.
    @inlinable
    func getRandomElement() -> Element? {
        
        // If it's an empty array, return nil.
        guard !isEmpty else { return nil }
        
        // Otherwise, randomly select one element and return it.
        let randomIndex = Int.random(in: 0..<count)
        return self[randomIndex]
    }
}

