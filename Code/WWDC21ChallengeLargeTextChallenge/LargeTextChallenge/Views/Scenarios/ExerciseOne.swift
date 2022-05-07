/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the first exercise, which introduces simple modifications to
 designing for Dynamic Type.
*/

import SwiftUI

/// An ObservableObject that contains all of the properties that can be modified in this exercise. Any
/// Views that subscribe to this Object update their UI when any of these values change.
class ExerciseOneProperties: ObservableObject, ScenarioFeedbackProtocol {
    var scenario: Scenario? = nil
    @Published var isPresented = false
    @Published var allowsScrolling = false
    
    /// Initialize with a scenario to get the feedback necessary for this exercise.
    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
    }
    
    /// Returns the feedback for this exercise based on the choices made.
    func results() -> [ScenarioFeedbackResult] {
        var feedbackResults: [ScenarioFeedbackResult] = []
        guard let scenario = scenario else {
            print("Scenario is nil")
            return feedbackResults
        }
        
        for feedback in scenario.feedback where feedback.property == .allowsScrolling {
            let scenarioResult = ScenarioFeedbackResult(feedback: feedback,
                                                        result: self.allowsScrolling)
            feedbackResults.append(scenarioResult)
        }
        
        return feedbackResults
    }
}

/// Constructs the Menu to present when tapping the text view.
struct ExerciseOneTextMenu: View {
    @ObservedObject var viewModel: ExerciseOneProperties
    
    var body: some View {
        VStack {
            Text("Text View Properties")
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding()
            
            Spacer()
            
            // Updates the text view by placing the content in a scroll view,
            // if enabled, or removing it from the scroll view if disabled.
            Button(action: {
                viewModel.allowsScrolling.toggle()
            }) {
                if viewModel.allowsScrolling {
                    Label("Allow Scrolling", systemImage: "checkmark.circle.fill")
                        .font(.body)
                } else {
                    Label("Allow Scrolling", systemImage: "circlebadge")
                        .font(.body)
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

/// Constructs the Text View for the exercise.
struct ExerciseOneTextView: View {
    @ObservedObject var viewModel: ExerciseOneProperties
    
    var body: some View {
        VStack {
            Text("Dynamic Type")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("""
                This is a very long block of text, sometimes used for:
                    • Terms and Conditions
                    • Explain concepts
                    • Telling a story
                
                The mind is the limit when designing your apps! Although views like this are useful, \
                keep in mind that text size can grow to very large sizes! If the text becomes too large, \
                then it becomes possible for the tail end of the text to become truncated if the containing view \
                isn't large enough to handle the larger sizes.
                
                Try increasing the text size and see what happens. The text becomes too large for this view, so users \
                who prefer a larger text size won't be able to see this text. In cases like these, placing our text \
                inside of a scroll view can allow us to scroll to see all of the text! We can even set it so that the \
                Text is only placed in a scroll view once text reaches, or exceeds, a specific size!
                """)
                .padding()
        }
    }
}

/// Constructs the button view to use in the exercise.
struct ExerciseOneButtonView: View {
    @ObservedObject var viewModel: ExerciseOneProperties
    
    var body: some View {
        Button(action: {}) {
            Text("Button")
        }
        .buttonStyle(CustomButtonStyle())
        .frame(width: 300, alignment: .bottom)
    }
}

/// Constructs the first exercise, consisting of a text view with a button at the bottom.
struct ExerciseOne: View {
    let scenario: Scenario?
    @StateObject private var viewModel: ExerciseOneProperties
    
    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
        self._viewModel = StateObject(wrappedValue: ExerciseOneProperties(scenario))
    }
    
    var body: some View {
        VStack {
            if viewModel.allowsScrolling {
                ScrollView {
                    ExerciseOneTextView(viewModel: viewModel)
                }
            }
            // FIX ME: This approach illustrates non-scrollable views.
            // Example Solution. Try using a scroll view for the content.
            // This modification allows the view to scroll, if necessary.
            else {
                ExerciseOneTextView(viewModel: viewModel)
            }
            
            ExerciseOneButtonView(viewModel: viewModel)
        }
        .navigationBarTitle("Text with Button", displayMode: .inline)
        .toolbar {
            NavigationLink(destination: ScenarioFeedbackView(viewModel: viewModel)) {
                Text("Feedback")
            }
        }
        .onTapGesture {
            viewModel.isPresented.toggle()
        }
        .sheet(isPresented: $viewModel.isPresented) {
            ExerciseOneTextMenu(viewModel: viewModel)
        }
    }
}
