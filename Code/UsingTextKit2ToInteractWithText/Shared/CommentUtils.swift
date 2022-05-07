/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Reaction button symbol names and accessibility labels.
*/

import Foundation

extension NSAttributedString.Key {
    public static var commentDepth: NSAttributedString.Key {
        return NSAttributedString.Key("TK2DemoCommentDepth")
    }
}

enum Reaction: Int {
    case none = 0, thumbsUp, smilingFace, questionMark, thumbsDown
    
    var symbolName: String {
        switch self {
            case .thumbsUp: return "hand.thumbsup.fill"
            case .smilingFace: return "face.smiling.fill"
            case .questionMark: return "questionmark.circle.fill"
            case .thumbsDown: return "hand.thumbsdown.fill"
            default: return ""
        }
    }
    
    var accessibilityLabel: String {
        switch self {
            case .thumbsUp: return "Thumbs Up Reaction"
            case .smilingFace: return "Smiling Face Reaction"
            case .questionMark: return "Question Mark Reaction"
            case .thumbsDown: return "Thumbs Down Reaction"
            default: return ""
        }
    }
}
