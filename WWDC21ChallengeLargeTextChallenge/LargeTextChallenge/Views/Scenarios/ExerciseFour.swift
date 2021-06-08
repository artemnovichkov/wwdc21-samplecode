/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the fourth scenario, which shows how to limit the size an
 image scales to so that it doesn't impact the UI.
*/

import SwiftUI

private let defaultIconFrameHeight: CGFloat = 75.0

/// An ObservableObject that contains all of the properties that can be modified in this exercise. Any
/// Views that subscribe to this Object update their UI when any of these values change.
class ExerciseFourProperties: ObservableObject, ScenarioFeedbackProtocol {
    var scenario: Scenario? = nil
    @Published var isPresented = false
    @Published var replaceWithLabel = false

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

        let data = scenario.feedback
        for feedback in data where feedback.property == .replaceHStackWithLabel {
            let result = self.replaceWithLabel
            feedbackResults.append(ScenarioFeedbackResult(feedback: feedback, result: result))
        }

        return feedbackResults
    }
}

/// Constructs the Menu to present when tapping any symbol..
struct ExerciseFourSymbolMenu: View {
    @ObservedObject var viewModel: ExerciseFourProperties

    var body: some View {
        VStack {
            Text("Symbols")
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding()

            Spacer()

            // Determines whether to replace the HStack with a Label.
            Button(action: {
                viewModel.replaceWithLabel.toggle()
            }) {
                if viewModel.replaceWithLabel {
                    Label("Use Label instead of HStack", systemImage: "checkmark.circle.fill")
                        .font(.body)
                } else {
                    Label("Use Label instead of HStack", systemImage: "circlebadge")
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

/// Constructs the Header to use in the List for this exercise.
struct ExerciseFourHeader: View {
    /// Updates the view when properties in this model change.
    @ObservedObject var viewModel: ExerciseFourProperties

    var body: some View {
        let labelView = Label(title: {
            VStack(alignment: .leading) {
                Text("Test Person")
                    .font(.title)
                Text("testperson@icloud.com")
                    .font(.subheadline)
            }
        }, icon: {
            Image(systemName: "person.circle.fill")
                .renderingMode(.template)
                .font(.title)
        })

        let hStackView = HStack(alignment: .center) {
            Image(systemName: "person.circle.fill")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .frame(height: defaultIconFrameHeight)
            VStack(alignment: .leading) {
                Text("Test Person")
                    .font(.title)
                Text("testperson@icloud.com")
                    .font(.subheadline)
            }
        }

        if viewModel.replaceWithLabel {
            labelView
                .onTapGesture {
                    viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseFourSymbolMenu(viewModel: viewModel)
                }
        } else {
            hStackView
                .onTapGesture {
                    viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseFourSymbolMenu(viewModel: viewModel)
                }
        }
    }
}

/// Constructs the Row to use in this exercise.
struct ExerciseFourRow: View {
    @ObservedObject var viewModel: ExerciseFourProperties
    @ScaledMetric var imageHeight: CGFloat = defaultIconFrameHeight

    var value: String
    var imageName: String
    var color: Color

    var body: some View {
        let labelView = Label(title: {
            Text(self.value)
                .font(.body)
                .lineLimit(2)
        }, icon: {
            Image(systemName: self.imageName)
                .renderingMode(.template)
                .foregroundColor(color)
        })

        let hStackView = HStack(alignment: .center) {
            Image(systemName: imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(color)
                .padding()
                .frame(height: imageHeight)

            Text(value)
                .font(.body)
                .lineLimit(1)
                .onTapGesture {
                    viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseFourSymbolMenu(viewModel: viewModel)
                }
        }

        if viewModel.replaceWithLabel {
            labelView
                .onTapGesture {
                    viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseFourSymbolMenu(viewModel: viewModel)
                }
        } else {
            hStackView
                .frame(height: defaultIconFrameHeight)
                .onTapGesture {
                    viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseFourSymbolMenu(viewModel: viewModel)
                }
        }
    }
}

/// Constructs the List View to use in this exercise.
struct ExerciseFourList: View {
    /// Updates the view when the properties in this view model change.
    @ObservedObject var viewModel: ExerciseFourProperties

    var body: some View {
        List {
            ExerciseFourRow(viewModel: viewModel, value: "Favorites",
                            imageName: "star.circle.fill",
                            color: .yellow)
            ExerciseFourRow(viewModel: viewModel,
                            value: "Guides",
                            imageName: "book.circle.fill", color: .purple)
            ExerciseFourRow(viewModel: viewModel,
                            value: "Accidents",
                            imageName: "exclamationmark.circle.fill", color: .red)
            ExerciseFourRow(viewModel: viewModel,
                            value: "Friends Recommend",
                            imageName: "person.2.circle.fill", color: .blue)
            ExerciseFourRow(viewModel: viewModel,
                            value: "Search",
                            imageName: "magnifyingglass.circle.fill", color: .gray)
        }
        .cornerRadius(3.0)
    }
}

struct ExerciseFour: View {
    let scenario: Scenario?
    @StateObject private var viewModel: ExerciseFourProperties

    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
        self._viewModel = StateObject(wrappedValue: ExerciseFourProperties(scenario))
    }
    var body: some View {
        VStack {
            ExerciseFourHeader(viewModel: viewModel)
                .padding()
            ExerciseFourList(viewModel: viewModel)
                .background(Color.white)
            .navigationBarTitle("List With Icons", displayMode: .inline)
            .toolbar {
                NavigationLink(destination: ScenarioFeedbackView(viewModel: viewModel)) {
                    Text("Feedback")
                }
            }
        }
    }
}
