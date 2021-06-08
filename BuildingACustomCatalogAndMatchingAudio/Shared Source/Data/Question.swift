/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model object that describes the question we show for the custom audio.
*/

import Foundation

struct Question: Comparable, Equatable {
    let title: String
    let offset: TimeInterval
    let equation: Equation?
    let answerRange: ClosedRange<Int>
    let requiresAnswer: Bool
    
    init(title: String, offset: TimeInterval, equation: Equation? = nil, answerRange: ClosedRange<Int> = 0...0, requiresAnswer: Bool = false) {
        self.title = title
        self.offset = offset
        self.equation = equation
        self.answerRange = answerRange
        self.requiresAnswer = requiresAnswer
    }
    
    static func < (lhs: Question, rhs: Question) -> Bool {
        return lhs.offset < rhs.offset
    }
    
    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.title == rhs.title && lhs.offset == rhs.offset
    }
}
