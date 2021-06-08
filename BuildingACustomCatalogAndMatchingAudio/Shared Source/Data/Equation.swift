/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model object that describes the equation for each section in the video.
*/

import Foundation
import SwiftUI

enum EquationType: Equatable {
    case red(Int)
    case green(Int)
    case mix(red: Int, green: Int)
    case image(Image, value: Int)
    
    var value: Int {
        switch self {
        case .red(let value):
            return value
        case .green(let value):
            return value
        case .image(_, value: let value):
            return value
        case .mix(let red, let green):
            return red + green
        }
    }
    
    static func == (lhs: EquationType, rhs: EquationType) -> Bool {
        switch (lhs, rhs) {
        case (.red(let lhsValue), .red(let rhsValue)):
            return lhsValue == rhsValue
        case (.green(let lhsValue), .green(let rhsValue)):
            return lhsValue == rhsValue
        case (.image(_, value: let lhsValue), .image(_, value: let rhsValue)):
            return lhsValue == rhsValue
        case (.mix(let lhsRed, let lhsGreen), .mix(let rhsRed, let rhsGreen)):
            return (lhsRed + lhsGreen) == (rhsRed + rhsGreen)
        default:
            return false
        }
    }
}

enum EquationOperation {
    case addition, subtraction, multiplication, division
}

struct Equation: Equatable {
    let lhs: EquationType
    let rhs: EquationType?
    let operation: EquationOperation?
    
    init(lhs: EquationType, rhs: EquationType? = nil, operation: EquationOperation? = nil) {
        self.lhs = lhs
        self.rhs = rhs
        self.operation = operation
    }
    
    var result: Int {
        guard let operation = operation else {
            return lhs.value
        }
        
        guard let rhs = rhs else {
            return lhs.value
        }
        
        switch operation {
        case .addition:
            return lhs.value + rhs.value
        case .subtraction:
            return lhs.value - rhs.value
        case .multiplication:
            return lhs.value * rhs.value
        case .division:
            return lhs.value / rhs.value
        }
    }
    
    static func == (lhs: Equation, rhs: Equation) -> Bool {
        return lhs.lhs == rhs.lhs && lhs.rhs == rhs.rhs && lhs.operation == rhs.operation
    }
}
