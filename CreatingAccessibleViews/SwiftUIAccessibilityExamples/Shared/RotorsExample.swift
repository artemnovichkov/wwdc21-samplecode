/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Accessibility Rotors examples.
*/

import SwiftUI

/// Example data model for Rotor examples.
private struct Model {
    struct Value: Identifiable {
        var label: String
        var color: Color
        var isRotorEntry: Bool = false

        var id: String {
            label
        }
    }

    var values: [Value] = [
        Value(label: "one", color: .green),
        Value(label: "two", color: .blue),
        Value(label: "three", color: .red, isRotorEntry: true),
        Value(label: "four", color: .purple),
        Value(label: "five", color: .orange, isRotorEntry: true),
        Value(label: "six", color: .yellow),
        Value(label: "seven", color: .brown)
    ]
}

/// A rotor example using a lazy vertical stack.
///
/// Accessibility  elements are scrolled into place
/// automatically when the user chooses the Rotor entry in VoiceOver.
/// This code has access to the full list of Rotor entries, so pass
/// the list in directly as a convenience.
private struct StackExample: View {
    var model = Model()

    var body: some View {
        LazyVStack {
            ForEach(model.values) { value in
                AccessibilityElementView(color: value.color, text: Text(value.label))
            }
        }
        .accessibilityRotor("Special Values", entries: model.values.filter(\.isRotorEntry), entryLabel: \.label)
        .navigationTitle("Stack Rotor")
    }
}

/// Navigation content for all the specific examples of rotors.
private struct RotorExampleNavigation: View {
    var body: some View {
        NavigationLink(destination: StackExample()) { Text("Stack Rotor") }
    }
}

#if os(macOS)
struct RotorsExample: View {
    var body: some View {
        NavigationView {
            List {
                RotorExampleNavigation()
            }
            Text("No Rotor Example")
        }
    }
}
#else
struct RotorsExample: View {
    var body: some View {
        VStack(spacing: 10) {
            RotorExampleNavigation()
        }
    }
}
#endif
