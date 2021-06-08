/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Action accessibility examples.
*/

import SwiftUI

/// Examples of using actions in SwiftUI accessibility.
struct ActionExample: View {
    var body: some View {
        // Use `accessibilityAction` to add a default action to an element,
        // or to override an existing default action the element might already
        // have. Add `isButton` to have VoiceOver read this element as a button.
        LabeledExample("Element with default action") {
            AccessibilityElementView(color: .red, text: Text("Default"))
                .accessibilityLabel("Element with default action")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    print("Default action fired!")
                }
        }

        LabeledExample("Element with custom actions") {
            // Use `accessibilityAction(named:)` to add custom actions to an
            // element.
            // Pass a `Label` into the view-based version of
            // `accessibilityAction()` to create a custom action with not only
            // a textual name, but also an image that can be shown by Switch
            // Control and other accessibility features.
            AccessibilityElementView(color: .blue, text: Text("Custom"))
                .accessibilityLabel("Element with custom actions")
                .accessibilityAction(named: "Custom Action") {}
                .accessibilityAction {
                    print("Label Action fired!")
                } label: {
                    Label("Delete", systemImage: "trash")
                }
        }

        LabeledExample("Element with adjustable action") {
            // Use `accessibilityAdjustableAction` to allow an accessibility
            // element to respond to VoiceOver's built-in increment
            // and decrement capabilities.
            AccessibilityElementView(color: .green, text: Text("Adjustable"))
                .accessibilityLabel("Element with adjustable action")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .decrement:
                        print("Decrement action fired!")
                    case .increment:
                        print("Increment action fired!")
                    @unknown default:
                        break
                    }
                }
        }

        // Combining multiple elements with different default actions will lead
        // to a single resulting element, with multiple named custom actions,
        // named after the combined elements.
        LabeledExample("Combined element with custom actions") {
            HStack {
                AccessibilityElementView(color: .yellow, text: Text("Default"))
                    .accessibilityLabel("Default Action A")
                    .accessibilityAction {
                        print("Default action A fired!")
                    }

                AccessibilityElementView(color: .purple, text: Text("Default"))
                    .accessibilityLabel("Default Action B")
                    .accessibilityAction {
                        print("Default action B fired!")
                    }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Combined element with custom actions")
        }
    }
}
