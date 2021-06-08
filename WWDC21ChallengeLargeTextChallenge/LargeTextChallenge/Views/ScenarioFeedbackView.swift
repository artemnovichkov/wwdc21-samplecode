/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Presents feedback for the choices taken in a particular scenario.
*/

import SwiftUI

/// Protocol that indicates the struct/class has results in which feedback can be presented.
protocol ScenarioFeedbackProtocol {
    func results() -> [ScenarioFeedbackResult]
}

/// Constructs the View that presents feedback to the user.
struct ScenarioFeedbackViewRow: View {
    let title: String
    let result: Bool
    let details: String
    
    init(result: ScenarioFeedbackResult) {
        self.title = result.feedback.property.displayName
        self.result = result.result
        self.details = result.result == true ? result.feedback.enabled : result.feedback.disabled
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // Determines the image to use based on the result presented.
                if result == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.green)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.red)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 2))
                }
            }
            
            Text(details)
        }
        .padding()
    }
}

/// Constructs all of the Feedback Rows.
struct ScenarioFeedbackView: View {
    var viewModel: ScenarioFeedbackProtocol
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.results()) { result in
                    ScenarioFeedbackViewRow(result: result)
                }
            }
        }
    }
}
