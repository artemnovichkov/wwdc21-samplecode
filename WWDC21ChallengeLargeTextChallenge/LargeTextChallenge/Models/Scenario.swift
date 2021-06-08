/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Scenario models for tracking the lessons and their results.
*/

import SwiftUI

/// Scenario model that presents the information for the lesson.
struct Scenario: Hashable, Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let exercise: ScenarioKey
    let feedback: [ScenarioFeedback]
}

/// Model that represents the possible choices in a scenario.
struct ScenarioFeedback: Hashable, Codable, Identifiable {
    let id: Int
    let property: ScenarioPropertyKey
    let enabled: String
    let disabled: String
}

/// Model that tracks the choices made in a scenario for the specified ScenarioFeedback.
struct ScenarioFeedbackResult: Identifiable {
    var id: Int {
        return self.feedback.id
    }
    let feedback: ScenarioFeedback
    let result: Bool
}

// The scenario exercise key to determine which View to load.
enum ScenarioKey: String, RawRepresentable, Codable {
    case textWithButton
    case textWithImage
    case textFieldSideView
    case listWithIcons
    case textureGrid
    case profilePage
}

// The properties that can change throughout the exercises.
enum ScenarioPropertyKey: String, RawRepresentable, Codable {
    case allowsScrolling
    case atTextSize
    case presentLargerImage
    case limitImageSize
    case limitCellHeight
    case useScaledMetric
    case replaceHStackWithLabel
    case stackVertically
    
    var displayName: String {
        switch self {
        case .allowsScrolling:
            return "Allows Scrolling"
        case .atTextSize:
            return "Text Size"
        case .presentLargerImage:
            return "Present Larger Image"
        case .limitImageSize:
            return "Limit Image Size"
        case .limitCellHeight:
            return "Limit Cell Height"
        case .useScaledMetric:
            return "Scaled Metric"
        case .replaceHStackWithLabel:
            return "Use Label instead of HStack"
        case .stackVertically:
            return "Stack Views Vertically"
        }
    }
}
