/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Image-related accessibility examples.
*/

import SwiftUI

/// A visual frame for an image.
struct FramedImage: View {
    let image: Image

    init(_ image: Image) {
        self.image = image
    }

    var body: some View {
        let dimension: CGFloat = 64
        let backgroundShape = RoundedRectangle(cornerRadius: 5)

        image.resizable()
            .frame(width: dimension, height: dimension)
            .scaledToFit()
            .padding()
            .background {
                backgroundShape.fill(.white)
            }
            .overlay {
                backgroundShape.stroke(.gray)
            }
    }
}

/// Examples of making Images accessible using SwiftUI.
struct ImageExample: View {
    var body: some View {
        LabeledExample("Unlabeled Image") {
            // This image creates an accessibility element, but has no label.
            // The accessibility label will be taken from the file name of the
            // image.
            FramedImage(Image("dot_green"))
        }

        LabeledExample("Accessible Images") {
            // This image uses an explicit accessibility label via the API.
            FramedImage(Image("dot_red"))
                .accessibilityLabel("Red Dot Image")

            // This image is created with an explicit (accessibility) label.
            FramedImage(Image("dot_green", label: Text("Green Dot")))

            // This image gets an implicit accessibility label, because
            // the string `dot_yellow` is in a localizable strings
            // file.
            FramedImage(Image("dot_yellow"))

            // Use the `accessibilityChildren` modifier to allow VoiceOver users
            // to navigate into an image and access parts of the contents
            // individually as accessibility elements.
            FramedImage(Image("dot_yellow"))
                .accessibilityChildren {
                    VStack {
                        Text("First Child Element")
                        Text("Second Child Element")
                        Text("Third Child Element")
                    }
                }
        }

        LabeledExample("System Images") {
            // System images have an accessibility label by default.
            FramedImage(Image(systemName: "trash"))

            // But you may need to provide a more appropriate label.
            FramedImage(Image(systemName: "trash"))
                .accessibilityLabel("Delete")
        }

        LabeledExample("Decorative Image") {
            // This image is explicitly marked decorative, so it does not
            // create an accessibility element.
            FramedImage(Image(decorative: "dot_green"))
        }

        LabeledExample("Text and Image Pairs") {
            // Label will automatically create only one accessibility element
            // for the entire view. The Accessibility information for
            // this element will be taken from the text, but its size will
            // encompass the image.
            Label("Delete", systemImage: "trash")

            // Any accessibility information explicitly applied to the image
            // in a label will be ignored.
            Label() {
                Text("Turn On")
            } icon: {
                Image("dot_green")
                    .accessibilityLabel("This accessibility label will be ignored")
            }
        }
    }
}
