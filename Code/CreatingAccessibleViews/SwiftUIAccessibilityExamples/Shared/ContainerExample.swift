/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Container-related accessibility examples.
*/

import SwiftUI

/// Examples of using containers in SwiftUI accessibility.
struct ContainerExample: View {
    @State private var onState = true

    var body: some View {
        LabeledExample("Grouping Container") {
            // Create a stack with multiple toggles and a label inside.
            VStack(alignment: .leading) {
                Toggle(isOn: $onState) { Text("Toggle 1") }
                Toggle(isOn: $onState) { Text("Toggle 2") }
                Toggle(isOn: $onState) { Text("Toggle 3") }
                Toggle(isOn: $onState) { Text("Toggle 4") }
            }
            .padding()
            .background { Color.white }
            .border(.blue, width: 0.5)

            // Explicitly make a new accessibility element
            // which will contain the children.
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Grouping Container")
        }

        LabeledExample("Hiding Container") {
            VStack(alignment: .leading) {
                Image("dot_red", label: Text("Red Dot"))
                    .resizable()
                    .frame(width: 48, height: 48)
                    .scaledToFit()
                Image("dot_green", label: Text("Green Dot"))
                    .resizable()
                    .frame(width: 48, height: 48)
                    .scaledToFit()
                    .opacity(onState ? 1 : 0)
                    // Opacity hides accessibility element by default,
                    // if this is unwanted explicitly set hidden to false
                    .accessibilityHidden(false)
            }
            .padding()
            .background { Color.white }
            .border(.blue, width: 0.5)
            // Hide all the accessibility elements that come from controls
            // inside this stack.
            .accessibilityHidden(true)
            // Create a new accessibility element to contain them.
            .accessibilityElement(children: .contain)
            // On macOS, containers with a label will be focusable by
            // assistive technologies. On iOS, the label will be spoken
            // when assistive technologies first focus on one of their
            // children.
            .accessibilityLabel("Hiding Container")
        }

        LabeledExample("Combine, then Contain") {
            // Two text elements in a vertical stack, with different hints.
            VStack(alignment: .leading) {
                Text("Combining").accessibilityHint("First Hint")
                Text("Container").accessibilityHint("Second Hint")
            }
            .padding()
            .background { Color.white }
            .border(.blue, width: 0.5)
            // First combine to merge properties from children into a
            // new element.
            .accessibilityElement(children: .combine)
            // Now transform the newly created element into a container
            // to expose the children.
            .accessibilityElement(children: .contain)
        }

        LabeledExample("Contain, then Combine") {
            // Two text elements in a vertical stack, with different hints.
            VStack(alignment: .leading) {
                Text("Combining").accessibilityHint("First Hint")
                Text("Container").accessibilityHint("Second Hint")
            }
            .padding()
            .background { Color.white }
            .border(.blue, width: 0.5)
            // Create a new accessibility element to contain them.
            .accessibilityElement(children: .contain)
            // Now transform the container into an element that
            // merges properties from children, and no longer
            // exposes its children.
            .accessibilityElement(children: .combine)
        }
    }
}
