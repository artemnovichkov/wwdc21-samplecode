/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A toggle style that uses system checkmark images to represent the On state.
*/

import SwiftUI

struct CircleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label.hidden()
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .accessibility(label: configuration.isOn ?
                               Text("Checked", comment: "Accessibility label for circular style toggle that is checked (on)") :
                                Text("Unchecked", comment: "Accessibility label for circular style toggle that is unchecked (off)"))
                .foregroundStyle(configuration.isOn ? Color.accentColor : .secondary)
                .imageScale(.large)
                .font(Font.title)
        }
    }
}

extension ToggleStyle where Self == CircleToggleStyle {
    static var circle: CircleToggleStyle {
        CircleToggleStyle()
    }
}
