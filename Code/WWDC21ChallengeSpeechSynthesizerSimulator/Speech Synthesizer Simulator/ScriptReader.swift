/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The script reader. This file defines the Quote object that the Conversation class uses,
 and creates a reliable parsing solution to read scripts in this format:
 
 NAME: Text to be read.
 ...
 NAME: Final line.
*/

import Foundation

struct Quote {
    var speaker: String
    var line: String
}

struct ScriptReader {
    
    func parseFile() -> [Quote] {
        guard let filepath = Bundle.main.path(forResource: "conversation", ofType: "txt") else {
            // Return sample conversation, because file doesn't exist or is in the wrong format.
            return sampleConversation()
        }
        
        do {
            let contents = try String(contentsOfFile: filepath)
            let array = contents.components(separatedBy: "\n")
            return setupSpeakers(contents: array)
        } catch {
            // Return sample conversation, because conversation.txt file isn't in the main bundle.
            return sampleConversation()
        }

    }
    
    func setupSpeakers(contents: [String]) -> [Quote] {
        var quoteList = [Quote]()
        for item in contents {
            let components = item.components(separatedBy: ": ")
            let quote = Quote(speaker: components[0], line: components[1])
            quoteList.append(quote)
        }
        
        return quoteList
    }
    
    func sampleConversation() -> [Quote] {
        return [
            Quote(speaker: "Uno", line: "Hey there."),
            Quote(speaker: "Duo", line: "Oh hey, friend!"),
            Quote(speaker: "Uno", line: "How's the weather?"),
            Quote(speaker: "Duo", line: "It's a little chilly, actually."),
            Quote(speaker: "Uno", line: "Stay warm!")
        ]
    }
}
