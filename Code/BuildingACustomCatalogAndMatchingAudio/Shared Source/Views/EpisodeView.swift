/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model representing the main class content.
*/

import SwiftUI

struct EpisodeView: View {
    let question: Question?
    
    @State private var isAnswerCardVisible = false
    @State private var isAnswerCorrect = false
    
    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()
            ZStack(alignment: .bottom) {
                ZStack {
                    BoardView()
                    if let equation = question?.equation {
                        QuestionView(equation: equation)
                    } else if let title = question?.title {
                        Text(title)
                            .foregroundColor(.customTitleColor)
                            .font(.system(size: 80, weight: .black, design: .rounded))
                    }
                }.padding([.leading, .trailing], 80)
                .padding([.top, .bottom], 50)
                
                if let question = question, question.requiresAnswer {
                    NumberPadView(range: question.answerRange)
                        .onSelect { index in
                            isAnswerCardVisible = true
                            isAnswerCorrect = question.equation?.result == index
                        }.shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 2)
                }
            }
            
            // Show feedback UI after answering the question.
            // We show it only when we received an answer.
            if let shouldShowAnswer = question?.requiresAnswer,
               shouldShowAnswer, isAnswerCardVisible {
                if isAnswerCorrect {
                    CardView(title: "Correct", subtitle: "Well done, you got it right!", image: .awardImage, visible: $isAnswerCardVisible)
                } else {
                    CardView(title: "Oops!", subtitle: "Let's try again!", image: .smallRedAppleImage, visible: $isAnswerCardVisible)
                }
            }
        }
    }
}

private struct BoardView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 25.0, style: .continuous)
                    .fill(Color.cuttingBoardColor)
                    .frame(width: geometry.size.width, alignment: .center)
                    .ignoresSafeArea()
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 20)
                RoundedRectangle(cornerRadius: 25.0, style: .continuous)
                    .stroke(Color.cuttingBoardSecondaryColor, style: StrokeStyle(lineWidth: 30))
                    .ignoresSafeArea()
            }
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            LinearGradient.backgroundGradient(startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Path { path in
                path.move(to: CGPoint(x: 200, y: 0))
                path.addLine(to: CGPoint(x: 200, y: geometry.size.height))
                path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                path.move(to: CGPoint(x: geometry.size.width - 200, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width - 200, y: geometry.size.height))
                path.move(to: CGPoint(x: 0, y: geometry.size.height / 3))
                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 3))
                path.move(to: CGPoint(x: 0, y: 2 * geometry.size.height / 3))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 2 * geometry.size.height / 3))
            }.stroke(Color.kitchenTilesDividerColor, lineWidth: 20)
        }
    }
}

struct EpisodeView_Previews: PreviewProvider {
    static let equation = Equation(lhs: .red(4), rhs: .green(2), operation: .addition)
    static let question = Question(title: "Question 42", offset: 10, equation: equation, answerRange: 2...6, requiresAnswer: true)
    static var previews: some View {
        EpisodeView(question: question)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
