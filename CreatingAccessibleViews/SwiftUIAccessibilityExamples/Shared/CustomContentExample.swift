/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Accessibility Custom Content examples.
*/

import SwiftUI

/// A model that stores a list of illustrations for use in the Custom Content examples.
private struct Model {
    var illustrations: [Illustration]

    init() {
        // Create test data
        illustrations = [
            Illustration(id: UUID(), label: "First Green Dot", image: Image("dot_green"), shape: "Circle", predominantColor: "Green"),
            Illustration(id: UUID(), label: "First Red Dot", image: Image("dot_red"), shape: "Circle", predominantColor: "Red"),
            Illustration(id: UUID(), label: "First Yellow Dot", image: Image("dot_yellow"), shape: "Circle", predominantColor: "Yellow"),
            Illustration(id: UUID(), label: "Second Red Dot", image: Image("dot_red"), shape: "Circle", predominantColor: "Red"),
            Illustration(id: UUID(), label: "Second Green Dot", image: Image("dot_green"), shape: "Circle", predominantColor: "Green"),
            Illustration(id: UUID(), label: "Second Yellow Dot", image: Image("dot_yellow"), shape: "Circle", predominantColor: "Yellow")
        ]
    }
}

/// A model describing an illustration in this UI.
private struct Illustration: Identifiable {
    var id: UUID
    var label: String
    var image: Image
    var shape: String
    var predominantColor: String
}

/// Custom content key for the shape custom content.
///
/// This can be used to remove custom content
/// that has already been added, or just so that you don't have to re-type a localizable
/// string when using the same custom content label throughout your app.
private let shapeCustomContentKey = AccessibilityCustomContentKey("Illustration Shape", id: "shapeCustomContent")

/// Example view showing the use of the `accessibilityCustomContent` APIs.
struct CustomContentExample: View {
    /// A namespace that pairs label and content.
    @Namespace var namespace
    private var model = Model()

    var body: some View {
        Text("Illustrations")
            .font(.title)
            // Set the labeled pair role of this header text. This tells macOS
            // VoiceOver that it is the label for the grid element below.
            .accessibilityLabeledPair(role: .label, id: "illustrations", in: namespace)

        let size: CGFloat = 64
        let items: [GridItem] = Array(repeating: .init(.fixed(128)), count: 2)
        LazyVGrid(columns: items) {
            ForEach(model.illustrations) { illustration in
                let shape = RoundedRectangle(cornerRadius: defaultCornerRadius)
                VStack {
                    Text(illustration.label)
                        .foregroundColor(Color.white)
                    illustration.image.frame(width: size, height: size)
                }
                .padding()
                .frame(width: 96)
                .background {
                    shape.fill(Color.black)
                }
                .overlay {
                    shape.strokeBorder(Color.gray)
                }
                // Create one accessibility element for all the content of this
                // illustration. The label of the element is picked up from the Text above.
                .accessibilityElement(children: .combine)
                
                // Add custom content to this Accessibility element for
                // the predominant color of the illustration.
                // VoiceOver reads this to users. High priority custom
                // content is read automatically when VoiceOver lands
                // on an element. It is read without its label, so
                // make sure the value includes enough information.
                .accessibilityCustomContent("Predominant Color", "Mostly \(illustration.predominantColor)", importance: .high)
                
                // The `default` priority custom content is accessible
                // in VoiceOver using a shortcut or command, and is
                // read as the value followed by the label.
                .accessibilityCustomContent(shapeCustomContentKey, illustration.shape)
            }
        }
        // Set the other half of the label pair role. Let VoiceOver know that this
        // grid is the content associated with the Illustrations text below, which is
        // the label.
        .accessibilityLabeledPair(role: .content, id: "illustrations", in: namespace)
    }
}
