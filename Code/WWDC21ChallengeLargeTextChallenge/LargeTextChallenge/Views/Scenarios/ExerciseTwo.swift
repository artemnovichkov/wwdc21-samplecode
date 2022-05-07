/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the second exercise, which shows how simply stacking views when
 text size is larger helps to prevent text from truncating.
*/

import SwiftUI

/// An ObservableObject that contains all of the properties that can be modified in this exercise. Any
/// Views that subscribe to this Object update their UI when any of these values change.
class ExerciseTwoProperties: ObservableObject, ScenarioFeedbackProtocol {
    var scenario: Scenario? = nil

    @ScaledMetric private var scale = 1.0
    @Published var isPresented = false
    @Published var stackVertically = false
    @Published var stackAtLargerSizes = false

    /// Initialize with a scenario to get the feedback necessary for this exercise.
    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
    }

    /// Returns the feedback for this exercise based on the choices made.
    func results() -> [ScenarioFeedbackResult] {
        var feedbackResults: [ScenarioFeedbackResult] = []
        guard let scenario = scenario else {
            return feedbackResults
        }

        for feedback in scenario.feedback where feedback.property == .stackVertically {
            let result = ScenarioFeedbackResult(feedback: feedback,
                                                result: self.stackVertically)
            feedbackResults.append(result)
        }

        return feedbackResults
    }
}

/// Constructs the Menu to present when tapping any label view.
struct ExerciseTwoLabelMenu: View {
    @ObservedObject var viewModel: ExerciseTwoProperties

    var body: some View {
        VStack {
            Text("TextField Label")
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding()

            Spacer()

            VStack {
                // Modifies the main view by placing the content in a scroll
                // view when enabled, and removing it when disabled.
                Button(action: {
                    viewModel.stackVertically.toggle()
                }) {
                    if viewModel.stackVertically {
                        Label("Stack Vertically", systemImage: "checkmark.circle.fill")
                    } else {
                        Label("Stack Vertically", systemImage: "circlebadge")
                    }
                }
                .padding()

                // If the views should stack vertically, determines at what
                // text size the views should stack.
                if viewModel.stackVertically {
                    Button(action: {
                        viewModel.stackAtLargerSizes.toggle()
                    }) {
                        if viewModel.stackAtLargerSizes {
                            Label("At Larger Sizes", systemImage: "checkmark.circle.fill")
                        } else {
                            Label("At Larger Sizes", systemImage: "circlebadge")
                        }
                    }
                    .padding()
                }
            }

            Spacer()

            Button(action: {
                viewModel.isPresented.toggle()
            }) {
                Text("Dismiss")
                    .font(.body)
            }
        }
        .padding()
    }
}

/// Constructs the second exercise, consisting of a TextField with a label on the side.
struct ExerciseTwo: View {
    @Environment(\.sizeCategory) var sizeCategory

    var scenario: Scenario? = nil

    @StateObject private var viewModel: ExerciseTwoProperties
    @State private var text: String = ""

    // Helper variable for determining whether to stack views based on the user's choices.
    var shouldStack: Bool {
        let stackVertically = viewModel.stackVertically == true
        if viewModel.stackAtLargerSizes == false {
            return stackVertically
        }

        let largerTextSize = sizeCategory >= .accessibilityMedium
        return stackVertically && largerTextSize
    }

    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
        self._viewModel = StateObject(wrappedValue: ExerciseTwoProperties(scenario))
    }

    var body: some View {
        // Custom binding that allows using a computed property to determine whether to stack views or not.
        // FIX ME: This approach illustrates a HStack with large text.
        let isVerticalBinding = Binding<Bool>(
            get: {
                return self.shouldStack
            },
            set: {
                viewModel.stackVertically = $0
            }
        )

        VStack {
            Text("Connect to Server")
                .font(.title)
                .fontWeight(.bold)

            // Example Solution. Play around with VStack and HStacks
            // to find a layout that works at various sizes.
            // @Environment(\.sizeCategory) var sizeCategory
            // if sizeCategory >= .accessibilityExtraLarge {
            //    VStack(content: content)
            // } else {
            //    HStack(content: content)
            // }
            AdaptiveStack(isVertical: isVerticalBinding, horizontalAlignment: .leading, verticalAlignment: .lastTextBaseline) {
                    Text("Server")
                        .padding((shouldStack ? .all : .horizontal), 8)
                        .frame(maxWidth: shouldStack ? CGFloat(500.0) : CGFloat(100.0))
                        .fixedSize()
                        .onTapGesture {
                            viewModel.isPresented.toggle()
                        }
                    TextField("example.com", text: $text)
                        .padding(8)
                        .lineLimit(1)
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.systemBackgroundColor.opacity(0.1)))
            .cornerRadius(10)
            .padding(8)
        }
        .sheet(isPresented: $viewModel.isPresented) {
            ExerciseTwoLabelMenu(viewModel: viewModel)
        }
        .navigationBarTitle("TextField Side View", displayMode: .inline)
        .toolbar {
            NavigationLink(destination: ScenarioFeedbackView(viewModel: viewModel)) {
                Text("Feedback")
            }
        }
    }
}
