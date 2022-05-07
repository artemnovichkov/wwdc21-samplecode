/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the list of scenarios for teaching Dynamic Type.
*/

import SwiftUI

/// The Row view to present in the Scenario List.
struct ScenarioRow: View {
    var scenario: Scenario
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(scenario.name)
                .font(.headline)
            Text(scenario.description)
                .font(.body)
        }
    }
}

/// The list of exercises that help show how the user can modify the UI to accomodate larger text sizes.
struct ScenarioList: View {
    @State var isIntroPresented = true
    
    var body: some View {
        NavigationView {
            List(scenarioData) { scenario in
                if scenario.exercise == .textWithButton {
                    NavigationLink(destination: ExerciseOne(scenario)) {
                        ScenarioRow(scenario: scenario)
                    }
                } else if scenario.exercise == .textFieldSideView {
                    NavigationLink(destination: ExerciseTwo(scenario)) {
                        ScenarioRow(scenario: scenario)
                    }
                } else if scenario.exercise == .textWithImage {
                    NavigationLink(destination: ExerciseThree(scenario)) {
                        ScenarioRow(scenario: scenario)
                    }
                } else if scenario.exercise == .listWithIcons {
                    NavigationLink(destination: ExerciseFour(scenario)) {
                        ScenarioRow(scenario: scenario)
                    }
                } else if scenario.exercise == .textureGrid {
                    NavigationLink(destination: ExerciseFive(scenario)) {
                        ScenarioRow(scenario: scenario)
                    }
                }
            }
            .navigationTitle("Scenarios")
            .toolbar {
                Button(action: {
                    isIntroPresented.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
        .sheet(isPresented: $isIntroPresented) {
            IntroView(isPresented: $isIntroPresented)
        }
    }
}
