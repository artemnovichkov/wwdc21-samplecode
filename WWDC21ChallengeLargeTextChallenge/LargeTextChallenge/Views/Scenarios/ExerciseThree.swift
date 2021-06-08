/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the third exercise, which builds upon the first scenario by
 showing images can scale to account for various text sizes.
*/

import SwiftUI

let exerciseThreeImageName: String = "Landscape_5_Bridge"

/// An ObservableObject that contains all of the properties that can be modified in this exercise. Any
/// Views that subscribe to this Object update their UI when any of these values change.
class ExerciseThreeProperties: ObservableObject, ScenarioFeedbackProtocol {

    var scenario: Scenario? = nil

    @Published var isPresented: Bool = false
    @Published var presentLargerImage: Bool = false

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

        for feedback in scenario.feedback where feedback.property == .presentLargerImage {
            let result = ScenarioFeedbackResult(feedback: feedback,
                                                result: self.presentLargerImage)
            feedbackResults.append(result)
        }

        return feedbackResults
    }
}

/// Constructs the Menu to present when tapping the image view.
struct ExerciseThreeImageMenu: View {
    @ObservedObject var viewModel: ExerciseThreeProperties

    var body: some View {
        VStack {
            Text("Golden Gate Bridge Image")
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .padding()

            Spacer()

            // Updates the image view to use the ScaledMetric value to scale
            // the image to an appropriate size.
            Button(action: {
                viewModel.presentLargerImage.toggle()
            }) {
                if viewModel.presentLargerImage {
                    Label("Present Larger Image", systemImage: "checkmark.circle.fill")
                        .lineLimit(2)
                } else {
                    Label("Present Larger Image", systemImage: "circlebadge")
                        .lineLimit(2)
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

/// Constructs the Text View for this exercise.
struct ExerciseThreeTextView: View {
    var body: some View {
        VStack {
            Text("""
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. In vel eros dui. Interdum et malesuada fames ac ante ipsum primis in \
                faucibus. Curabitur ac quam quis nulla euismod aliquet sit amet at tortor. Nunc tincidunt erat ac lectus posuere venenatis. \
                Vivamus commodo, massa ut maximus tincidunt, ipsum dolor feugiat enim, id vestibulum risus turpis a nibh. Mauris sit amet justo \
                fermentum, laoreet massa ac, consectetur velit. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos \
                himenaeos. Vivamus malesuada augue massa, id consequat enim semper et. Aenean at turpis interdum, molestie mauris ut, efficitur \
                arcu. Suspendisse in augue at metus laoreet sodales non vitae diam. Phasellus interdum eros porttitor mi semper hendrerit. \
                Morbi id ligula orci. Etiam ut dictum metus, non vestibulum velit. Pellentesque in auctor augue. Pellentesque convallis est \
                vitae ante viverra pretium.
                """)
        }
    }
}

struct ExerciseThreeLargeImageView: View {
    /// Tracks how much the image is scaled during the current pinch gesture.
    @State private var currentAmount: CGFloat = 0
    /// Tracks the final scale after performing the pinch gesture.
    @State private var finalAmount: CGFloat = 1
    /// Tracks if this view is currently presented.
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Image(exerciseThreeImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(finalAmount + currentAmount)
                .animation(.linear(duration: 0.3))
                .gesture(
                    // Zoom in or out on the image by using a pinch gesture.
                    MagnificationGesture()
                        .onChanged { amount in
                            self.currentAmount = amount - 1
                        }
                        .onEnded { amount in
                            let newValue: CGFloat = self.finalAmount + self.currentAmount
                            self.currentAmount = 0
                            if newValue < 1.0 {
                                self.finalAmount = 1.0
                            } else if newValue > 5.0 {
                                self.finalAmount = 5.0
                            } else {
                                self.finalAmount = newValue
                            }
                        }
                )
                .padding()

            Spacer()
            // Button to dismiss the sheet view
            Button(action: {
                self.isPresented.toggle()
            }) {
                Text("Dismiss")
                    .font(.body)
            }
        }
    }
}

/// Constructs the Image View for this exercise.
struct ExerciseThreeImageView: View {
    /// Updates the view when the properties in this view model change.
    @ObservedObject var viewModel: ExerciseThreeProperties
    /// Tracks if the larger version of the image is presented.
    @State private var largeImagePresented: Bool = false

    /// The initial height of the image.
    var imageHeight = 350.0

    var body: some View {
        let image = Image(exerciseThreeImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: imageHeight)

        if viewModel.presentLargerImage {
            VStack(alignment: .center) {
                image
                    .onTapGesture {
                        self.largeImagePresented.toggle()
                    }
                    .sheet(isPresented: $largeImagePresented) {
                        ExerciseThreeLargeImageView(isPresented: $largeImagePresented)
                    }
                Text("Tap on Image to Expand")
                    .font(.caption2)
                    .onTapGesture {
                        self.viewModel.isPresented.toggle()
                    }
                    .sheet(isPresented: $viewModel.isPresented) {
                        ExerciseThreeImageMenu(viewModel: viewModel)
                    }
            }
        } else {
            image
                .onTapGesture {
                    self.viewModel.isPresented.toggle()
                }
                .sheet(isPresented: $viewModel.isPresented) {
                    ExerciseThreeImageMenu(viewModel: viewModel)
                }
        }
    }
}

/// Constructs the third exercise, consisting of a text view with an image.
struct ExerciseThree: View {
    var scenario: Scenario? = nil
    @StateObject private var viewModel: ExerciseThreeProperties

    init(_ scenario: Scenario? = nil) {
        self.scenario = scenario
        self._viewModel = StateObject(wrappedValue: ExerciseThreeProperties(scenario))
    }

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Text("The Golden Gate bridge is a beautiful sight to behold")
                        .font(.title)
                        .fontWeight(.bold)
                    ExerciseThreeImageView(viewModel: viewModel)
                        .padding()
                    ExerciseThreeTextView()
                }
            }
        }
        .navigationBarTitle("Text with Image", displayMode: .inline)
        .toolbar {
            NavigationLink(destination: ScenarioFeedbackView(viewModel: viewModel)) {
                Text("Feedback")
            }
        }
        .padding()
    }
}

