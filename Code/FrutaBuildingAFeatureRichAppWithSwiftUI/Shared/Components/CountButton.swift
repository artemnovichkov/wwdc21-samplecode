/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button for either incrementing or decrementing a binding.
*/

import SwiftUI

// MARK: - CountButton

struct CountButton: View {
    var mode: Mode
    var action: () -> Void

    @Environment(\.isEnabled) var isEnabled

    public var body: some View {
        Button(action: action) {
            Image(systemName: mode.imageName)
                .symbolVariant(isEnabled ? .circle.fill : .circle)
                .imageScale(.large)
                .padding()
                .contentShape(Rectangle())
                .opacity(0.5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CountButton.Mode

extension CountButton {
    enum Mode {
        case increment
        case decrement

        var imageName: String {
            switch self {
            case .increment:
                return "plus"
            case .decrement:
                return "minus"
            }
        }
    }
}

// MARK: - Previews

struct CountButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CountButton(mode: .increment, action: {})
            CountButton(mode: .decrement, action: {})
            CountButton(mode: .increment, action: {}).disabled(true)
            CountButton(mode: .decrement, action: {}).disabled(true)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
