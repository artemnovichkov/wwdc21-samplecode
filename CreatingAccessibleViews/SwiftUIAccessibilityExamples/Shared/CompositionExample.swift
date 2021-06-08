/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Composition accessibility examples.
*/

import SwiftUI

/// Examples of doing dynamic composition of accessibility in SwiftUI.
struct CompositionExample: View {
    var customContent: KeyValuePairs<String, String> = [
        "Label A": "Value A",
        "Label B": "Value B"
    ]

    var customActions: KeyValuePairs<String, () -> Void> = [
        "Custom action A": { print("Custom action A fired!") },
        "Custom action B": { print("Custom action B fired!") }
    ]

    var body: some View {
        LabeledExample("Custom Button Style") {
            // "Delete" is used for the accessibility label because
            // accessibility is represented by the button style's
            // label.
            Button("Delete") {}
                // `trash` symbol displayed visually
                .buttonStyle(SymbolButtonStyle(systemName: "trash"))
                .frame(width: 64, height: 64)
        }

        LabeledExample("Composing Dynamic Accessibility Information") {
            // Compose accessibility from dynamic data, unknown at compile time.
            AccessibilityElementView(color: .red, text: Text("Dynamic Custom Content"))
                // Create an accessibility child for each. Set them as children
                // of the `AccessibilityElementView`.
                .accessibilityChildren {
                    ForEach(customContent, id: \.key) { (label, value) in
                        Rectangle()
                            .accessibilityCustomContent(Text(label), Text(value))
                    }
                }
                // Combine the properties from the children back
                // into the `AccessibilityElementView`.
                .accessibilityElement(children: .combine)

            AccessibilityElementView(color: .blue, text: Text("Dynamic Custom Actions"))
                .accessibilityChildren {
                    ForEach(customActions, id: \.key) { (actionName, action) in
                        Rectangle()
                            .accessibilityAction(named: actionName, action)
                    }
                }
                .accessibilityElement(children: .combine)
        }

        LabeledExample("Elements with no Visuals") {
            Text("There is an other accessibility element in here")

            // To add accessibility elements that have a visual counterpart,
            // use `Color.clear` with an `accessibilityRepresentation`.
            Color.clear
                .accessibilityRepresentation {
                    Text("Text only visible to assistive technologies")
                }
        }
    }
}

/// A button style that shows only a symbol.
///
/// This style uses the label only for accessibility; the label is not rendered visually.
private struct SymbolButtonStyle: ButtonStyle {
    let systemName: String

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .foregroundColor(
                    configuration.isPressed ? Color.red : Color.blue)

            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.white)
                .padding(8)
        }
        // Use `accessibilityRepresentation` to replace accessibility with that of
        // the configuration's label. Otherwise, the accessibility
        // of this `Button` would come only from the `Image`, and the `label` passed
        // into the `Button` when it is constructed would be lost, because it isn't
        // rendered visually for this style.
        .accessibilityRepresentation { configuration.label }
    }
}
