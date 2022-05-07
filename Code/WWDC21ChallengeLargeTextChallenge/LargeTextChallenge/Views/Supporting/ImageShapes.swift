/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs various image views to give fun shapes to images in the app.
*/

import SwiftUI

/// Constructs an image view in a Circle shape.
struct CircleImage: View {
    var image: Image
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white, lineWidth: 4)
            )
    }
}

/// Constructs an image view in a RoundedRectange shape.
struct RoundedImage: View {
    var image: Image
    var imageSize: CGFloat = 125
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 4)
            )
            .frame(height: imageSize)
    }
}

// Constructs an image view with a RoundedRectangle and adds an animation
// when tapped.
struct SquareImageButton: View {
    var image: Image
    var color: Color = Color.random
    var text: String = ""
    @State var isPressed = false
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .tintOverlay(color: color, opacity: 0.3)
            .clipShape(RoundedRectangle(cornerRadius: 25.0))
            .textOverlay(text: text, color: .white)
            .scaleEffect(isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2))
    }
}

/// Constructs a system icon with a color circle background.
struct CircleSymbol: View {
    let imageName: String
    var imageSize: CGFloat = 50
    var color: Color = .blue
    
    var body: some View {
        Image(systemName: imageName)
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(color)
            .padding()
            .frame(height: imageSize)
    }
}

struct CircleImage_Previews: PreviewProvider {
    static var previews: some View {
        CircleImage(image: Image("Landscape_2_Sunset"))
    }
}
