/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the fifth scenario, which shows that limiting the number of columns
 in a collection view helps keep the UI consistent with larger text sizes.
*/

import SwiftUI

/// The default minimum item width for each grid item.
private let defaultMinimumItemWidth: CGFloat = 150.0

/// The View Model for Search Page. Pushes changed values to all observers so that they can update their layout.
class ExerciseFiveProperties: ObservableObject, ScenarioFeedbackProtocol {
    /// Helps determine how many columns the LazyVGrid should start with based on the device size.
    @Environment(\.horizontalSizeClass) var sizeClass
    /// Helps scale the image based on the current text size.
    @ScaledMetric private var scale = 1.0
    
    var scenario: Scenario? = nil
    @Published var isPresented = false
    @Published var useScaledMetric: Bool = false
    
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
        
        for feedback in scenario.feedback where feedback.property == .useScaledMetric {
            let result = useScaledMetric
            let feedbackResult = ScenarioFeedbackResult(feedback: feedback,
                                                        result: result)
            
            feedbackResults.append(feedbackResult)
        }
        
        return feedbackResults
    }
}

/// Constructs the fifth exercise which consists of a LazyVGrid that contains images of Textures.
struct ExerciseFiveMenu: View {
    @ObservedObject var viewModel: ExerciseFiveProperties
    
    var body: some View {
        VStack {
            Text("Grid Columns")
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding()
            
            Spacer()

            // Updates the number of columns in the LazyVGrid.
            VStack {
                Button(action: {
                    viewModel.useScaledMetric.toggle()
                }) {
                    if viewModel.useScaledMetric {
                        Label("Use Scaled Metric", systemImage: "checkmark.circle.fill")
                            .font(.body)
                    } else {
                        Label("Use Scaled Metric", systemImage: "circlebadge")
                            .font(.body)
                    }
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
/// The main View of Search Page. Puts all of the smaller UI parts together and sets up the main view.
struct ExerciseFive: View {
    /// Determines the size device of the device.
    @Environment(\.horizontalSizeClass) var sizeClass
    /// Scaled width of each grid item.
    @ScaledMetric private var minimumItemWidth = defaultMinimumItemWidth
    private var scenario: Scenario?
    @ScaledMetric private var sizeScale = 1.0
    @StateObject private var viewModel: ExerciseFiveProperties
    
    init(_ scenario: Scenario? = nil) {
        self.scenario = nil
        self._viewModel = StateObject(wrappedValue: ExerciseFiveProperties(scenario))
    }

    /// Deterimines the minimumWidth of the GridItem columns based on the user's choice.
    var columns: [GridItem] {
        var minimumWidth: CGFloat = defaultMinimumItemWidth
        if viewModel.useScaledMetric {
            minimumWidth = minimumItemWidth
        }
        return [.init(.adaptive(minimum: minimumWidth), spacing: 8.0, alignment: .top)]
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                LazyVGrid(columns: columns) {
                    ForEach(0..<10) { index in
                        let texture = texturesData[index]
                        SquareImageButton(image: texture.image, text: texture.name)
                    }
                }
                .navigationBarTitle("Textures", displayMode: .automatic)
                .toolbar {
                    NavigationLink(destination: ScenarioFeedbackView(viewModel: viewModel)) {
                        Text("Feedback")
                    }
                }
            }
        }
        .padding()
        .onTapGesture {
            viewModel.isPresented.toggle()
        }
        .sheet(isPresented: $viewModel.isPresented) {
            ExerciseFiveMenu(viewModel: viewModel)
        }
    }
}
