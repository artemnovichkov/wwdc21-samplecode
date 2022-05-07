/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Standard control accessibility examples.
*/

import SwiftUI

/// Examples of accessibility annotations for standard controls.
struct StandardControlExample: View {
    @Namespace var accessibilityNamespace

    var body: some View {
        LabeledExample("Customizing Buttons") {
            Button("Button with an accessibility label") {}
                .accessibilityLabel("Button label for accessibility")

            Button("Button with hint & identifier") {}
                // Use `accessibilityHint` to provide additional information for
                // VoiceOver users about what this control is or does.
                // Note that a user can turn off hints in their accessibility
                // settings.
                .accessibilityHint("Accessibility hint for first button")
                // Use `accessibilityIdentifier` to tag your controls for automation
                // and testing.
                .accessibilityIdentifier("First Button")

            // Use `accessibilityHidden` to hide a `Button` entirely from
            // accessibility, if the functionality is expressed to VoiceOver
            // elsewhere already.
            Button("Button hidden from accessibility") {}
                .accessibilityHidden(true)
        }

        LabeledExample("Drawn Elements") {
            // Use label and value to add information to custom drawn elements.
            AccessibilityElementView(color: .purple, text: Text("Element"))
                .accessibilityLabel("Purple Color Label")
                .accessibilityValue("Purple Color Value")
        }

        VStack {
            Text("Labels and Content")
            // Use `accessibilityLabeledPair` to connect an element
            // with its label, so VoiceOver knows about their relationship.
            // This improves the experience on macOS. On iOS, it will combine
            // the contents of the label.
            HStack {
                Text("Custom Controls")
                    .accessibilityLabeledPair(role: .label, id: "customControls", in: accessibilityNamespace)
                Button("Learn") {}
                    .accessibilityLabeledPair(role: .content, id: "customControls", in: accessibilityNamespace)
            }

            HStack {
                Text("SwiftUI Accessibility")
                    .accessibilityLabeledPair(role: .label, id: "swiftUIAccessibility", in: accessibilityNamespace)
                Button("Learn") {}
                    .accessibilityLabeledPair(role: .content, id: "swiftUIAccessibility", in: accessibilityNamespace)
            }
        }

        LabeledExample("Linked Elements") {
            // Use `accessibilityLinkedGroup` to link together related sets of
            // accessibility elements, so VoiceOver users can jump between them
            // quickly.
            HStack {
                VStack {
                    AccessibilityElementView(color: .red, text: Text("Red 1"))
                        .accessibilityLinkedGroup(id: "red", in: accessibilityNamespace)
                    AccessibilityElementView(color: .green, text: Text("Green 1"))
                        .accessibilityLinkedGroup(id: "green", in: accessibilityNamespace)
                    AccessibilityElementView(color: .blue, text: Text("Blue 1"))
                        .accessibilityLinkedGroup(id: "blue", in: accessibilityNamespace)
                }
                VStack {
                    AccessibilityElementView(color: .red, text: Text("Red 2"))
                        .accessibilityLinkedGroup(id: "red", in: accessibilityNamespace)
                    AccessibilityElementView(color: .green, text: Text("Green 2"))
                        .accessibilityLinkedGroup(id: "green", in: accessibilityNamespace)
                    AccessibilityElementView(color: .blue, text: Text("Blue 2"))
                        .accessibilityLinkedGroup(id: "blue", in: accessibilityNamespace)
                }
            }
        }
    }
}
