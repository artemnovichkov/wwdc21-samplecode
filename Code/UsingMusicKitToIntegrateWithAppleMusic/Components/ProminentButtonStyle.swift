/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom button style for buttons shown prominently the UI.
*/

import SwiftUI

/// `ProminentButtonStyle` is a custom button style that encapsulates
/// all the common modifiers for prominent buttons shown in the UI.
struct ProminentButtonStyle: ButtonStyle {
    
    /// The app-wide color scheme.
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    /// Applies relevant modifiers for this button style.
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundColor(.accentColor)
            .padding()
            .background(backgroundColor.cornerRadius(8))
    }
    
    /// The background color appropriate for the current color scheme.
    private var backgroundColor: Color {
        return Color(uiColor: (colorScheme == .dark) ? .secondarySystemBackground : .systemBackground)
    }
}
