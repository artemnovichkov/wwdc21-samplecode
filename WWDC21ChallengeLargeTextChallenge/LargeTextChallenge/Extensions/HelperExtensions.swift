/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extensions.
*/

import SwiftUI

// Extensions for Color that use UIColor system colors. UIColors change
// to match the current color scheme of the device, allowing for Dark Mode support.
// See: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/color/
extension Color {
    static let systemBackgroundColor = Color(UIColor.systemBackground)
    static let backgroundColor = Color(UIColor.systemGray6)
    static let buttonColor = Color(UIColor.systemBlue)
    static let buttonTextColor = Color.white
    static let textColor = Color(UIColor.label)
    
    // Generates a random SwiftUI Color.
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

/// Extensions for View that add various overlays for some of the scenarios.
extension View {
    // Adds a color with the specified opacity over the view.
    func tintOverlay(color: Color = .black, opacity: Double = 0.75) -> some View {
        self
            .background(color)
            .opacity(opacity)
    }
    
    // Overlays the specified text and various attributes on the specified view.
    func textOverlay(text: String, color: Color = .primary, font: Font = .title2, weight: Font.Weight = .bold) -> some View {
        ZStack(alignment: .bottomLeading) {
            self
            Text(text)
                .foregroundColor(color)
                .font(font)
                .fontWeight(weight)
                .padding()
        }
    }
}
