/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The list of accessibility examples.
*/

import SwiftUI

// MARK: App

@main
struct AccessibilityExamplesApp: App {
    var body: some Scene {
        WindowGroup {
            ExamplesView()
        }
    }
}

// MARK: Model

/// A model-level representation of an example.
struct Example {
    var name: String
    var view: AnyView
    var wantsScrollView: Bool
    var wantsPadding: Bool

    init<Content: View>(
        _ name: String,
        wantsScrollView: Bool = true,
        wantsPadding: Bool = true,
        @ViewBuilder content: @escaping (() -> Content)
    ) {
        self.name = name
        self.wantsScrollView = wantsScrollView
        self.wantsPadding = wantsPadding
        self.view = AnyView(content())
    }
}

/// The list of examples to show.
let examples = [
    Example("Standard Controls") { StandardControlExample() },
    Example("Custom Controls") { CustomControlsExample() },
    Example("Images") { ImageExample() },
    Example("Text") { TextExample() },
    Example("Containers") { ContainerExample() },
    Example("Actions") { ActionExample() },
    Example("ViewRepresentable") { ViewRepresentableExample() },
    Example("Canvas") { CanvasExample() },
    Example("ForEach") { ForEachExample() },
    Example("Sort Priority") { SortPriorityExample() },
    Example("Composition") { CompositionExample() },
    Example("Rotors", wantsScrollView: false, wantsPadding: false) { RotorsExample() },
    Example("Focus") { FocusExample() },
    Example("Custom Content") { CustomContentExample() },
    Example("Environment") { EnvironmentExample() }
]

// MARK: Visual Helpers

/// A view that pairs a set of examples with a grouping label.
struct LabeledExample<Content: View>: View {
    private var text: Text
    private var content: Content

    init(_ text: Text, @ViewBuilder content: (() -> Content)) {
        self.text = text
        self.content = content()
    }

    init(_ key: LocalizedStringKey, @ViewBuilder content: (() -> Content)) {
        self.init(Text(key), content: content)
    }

    var body: some View {
        GroupBox(label: text) {
            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
    }
}

/// The default corner radius to use for rounding.
let defaultCornerRadius: CGFloat = 10

/// A view for representing an accessibility element visually.
struct AccessibilityElementView: View {
    let color: Color
    let text: Text

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: defaultCornerRadius)
        text.padding(8)
            .frame(minWidth: 128, alignment: .center)
            .background {
                shape.fill(color)
            }
            .overlay {
                shape.strokeBorder(.white, lineWidth: 2)
            }
            .overlay {
                shape.strokeBorder(.gray, lineWidth: 1)
            }
    }
}
