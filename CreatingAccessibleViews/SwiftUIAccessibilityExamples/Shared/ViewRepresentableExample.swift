/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Platform representable accessibility examples.
*/

import SwiftUI

/// Examples of using UIViewRepresentable and NSViewRepresentable in SwiftUI
/// accessibility.
struct ViewRepresentableExample: View {
    var body: some View {
        LabeledExample("Element with representable view") {
            // You can use the SwiftUI Accessibility API to customize the accessibility of
            // AppKit or UIKit represented elements.
            RepresentableView()
                .frame(width: 128, height: 48)
                .accessibilityLabel("representable view accessibility label")
                .accessibilityValue("representable view accessibility value")
        }

        LabeledExample("Element with representable view controller") {
            RepresentableViewController()
                .frame(width: 128, height: 48)
                .accessibilityLabel("representable view controller accessibility label")
                .accessibilityValue("representable view controller accessibility value")
        }

        LabeledExample("Combining accessibility for representable views") {
            // Using the `accessibilityElement` modifier to combine or ignore children
            // hides the AppKit or UIKit represented element to accessibility, and
            // instead assistive technologies interact with the newly created
            // accessibility element.
            RepresentableView()
                .frame(width: 128, height: 48)
                .accessibilityElement(children: .combine)
        }
    }
}
