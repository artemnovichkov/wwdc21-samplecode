/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom button style to keep buttons consistent throughout the app.
*/

import SwiftUI

/// Applies a consistent layout to all buttons throughout the app.
struct CustomButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .background(Color.buttonColor)
            .foregroundColor(Color.buttonTextColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2))
    }
}
