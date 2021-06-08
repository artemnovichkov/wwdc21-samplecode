/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extension for custom questions.
*/

import Foundation

extension Question {
    
    static let allQuestions = [
        Question(title: "Question 1", offset: 14),
        Question(title: "Question 1 (#1)", offset: 21, equation: Equation(lhs: .red(1))),
        Question(title: "Question 1 (#2)", offset: 25, equation: Equation(lhs: .red(1), rhs: .green(3))),
        Question(title: "Answer 1",
                       offset: 31,
                       equation: Equation(lhs: .red(1), rhs: .green(3), operation: .addition),
                       answerRange: 1...5,
                       requiresAnswer: true),
        Question(title: "Question 2", offset: 47),
        Question(title: "Question 2 (#1)", offset: 54, equation: Equation(lhs: .red(2))),
        Question(title: "Question 2 (#2)", offset: 57, equation: Equation(lhs: .red(2), rhs: .green(2))),
        Question(title: "Answer 2",
                       offset: 63,
                       equation: Equation(lhs: .red(2), rhs: .green(2), operation: .addition),
                       answerRange: 1...5,
                       requiresAnswer: true),
        Question(title: "Question 3", offset: 81),
        Question(title: "Question 3 (#1)", offset: 93, equation: Equation(lhs: .mix(red: 2, green: 3))),
        Question(title: "Question 3 (#2)", offset: 99, equation: Equation(lhs: .mix(red: 2, green: 3), rhs: .red(2))),
        Question(title: "Answer 3",
                       offset: 105,
                       equation: Equation(lhs: .mix(red: 2, green: 3), rhs: .red(2), operation: .subtraction),
                       answerRange: 1...5,
                       requiresAnswer: true),
        Question(title: "Question 4", offset: 121),
        Question(title: "Question 4 (#1)", offset: 130, equation: Equation(lhs: .image(.fourteenApplesImage, value: 14))),
        Question(title: "Question 4 (#2)",
                       offset: 162,
                       equation: Equation(lhs: .image(.fourteenApplesImage, value: 14),
                                          rhs: .image(.twentyEightApplesImage, value: 28))),
        Question(title: "Answer 4",
                       offset: 191,
                       equation: Equation(lhs: .image(.fourteenApplesImage, value: 14),
                                          rhs: .image(.twentyEightApplesImage, value: 28), operation: .addition),
                       answerRange: 40...45,
                       requiresAnswer: true)
    ]
}
