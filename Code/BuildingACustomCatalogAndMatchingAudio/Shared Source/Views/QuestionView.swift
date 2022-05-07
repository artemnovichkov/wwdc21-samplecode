/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model showing the content of the equation on the board.
*/

import SwiftUI

struct QuestionView: View {
    let equation: Equation
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            AppleGridView(equation: equation.lhs)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut(duration: 0.6), value: equation)
            Spacer()
            if let operation = equation.operation {
                OperatorView(operation: operation)
                    .foregroundColor(Color.white)
            }
            if let rhs = equation.rhs {
                Spacer()
                AppleGridView(equation: rhs)
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut(duration: 0.6), value: equation)
            }
            Spacer()
        }.padding([.leading, .trailing], 57)
        .padding(.bottom, 20)
    }
}

private struct AppleGridView: View {
    let equation: EquationType
    
    private let rows = [GridItem(.fixed(180)), GridItem(.fixed(180))]
    
    var body: some View {
        switch equation {
        case .red(let value):
            LazyHGrid(rows: rows, alignment: .center, spacing: 15) {
                AppleGroupView(appleGroups: [AppleGroup(image: .smallRedAppleImage, amount: value)])
            }
        case .green(let value):
            LazyHGrid(rows: rows, alignment: .center, spacing: 15) {
                AppleGroupView(appleGroups: [AppleGroup(image: .smallGreenAppleImage, amount: value)])
            }
        case .image(let image, value: _):
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300)
        case .mix(let red, let green):
            LazyHGrid(rows: rows, alignment: .center, spacing: 15) {
                AppleGroupView(appleGroups: [
                    AppleGroup(image: .smallRedAppleImage, amount: red),
                    AppleGroup(image: .smallGreenAppleImage, amount: green)
                ])
            }
        }
    }
}

private struct AppleGroup {
    let id = UUID()
    let image: Image
    let amount: Int
}

private struct AppleGroupView: View {
    let appleGroups: [AppleGroup]
    
    var body: some View {
        ForEach(0..<appleGroups.count, id: \.self) { number in
            ForEach(0..<appleGroups[number].amount) { _ in
                appleGroups[number].image
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)
            }
        }
    }
}

private struct OperatorView: View {
    let operation: EquationOperation
    
    var body: some View {
        switch operation {
        case .addition:
            Image(systemName: "plus")
                .font(.system(size: 110, weight: .semibold, design: .rounded))
        case .subtraction:
            Image(systemName: "minus")
                .font(.system(size: 110, weight: .semibold, design: .rounded))
        case .multiplication:
            Image(systemName: "multiply")
                .font(.system(size: 110, weight: .semibold, design: .rounded))
        case .division:
            Image(systemName: "divide")
                .font(.system(size: 110, weight: .semibold, design: .rounded))
        }
    }
}

struct QuestionView_Previews: PreviewProvider {
    static let equation = Equation(lhs: .mix(red: 2, green: 3), rhs: .green(2), operation: .addition)
    static var previews: some View {
        QuestionView(equation: equation)
            .previewInterfaceOrientation(.landscapeRight)
    }
}
