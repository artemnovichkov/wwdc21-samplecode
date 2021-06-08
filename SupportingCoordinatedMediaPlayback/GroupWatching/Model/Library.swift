/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's library of movies.
*/

import Foundation

class Library {
    
    let movies: [Movie]
    static let shared = Library()
    
    private init() {
        movies = Library.load("Movies.json")
    }
    
    private static func load<T: Decodable>(_ filename: String, as type: T.Type = T.self) -> T {
        let data: Data
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
        }
    }
}
