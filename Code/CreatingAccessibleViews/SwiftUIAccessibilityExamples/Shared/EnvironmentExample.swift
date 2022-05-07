/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Accessibility Environment examples.
*/

import SwiftUI

/// A data model used to demonstrate differentiating without color.
private struct ColorModel {
    var values: [Value] = [.type1, .type3, .type2, .type1, .type3, .type2, .type1]

    enum Value: Hashable {
        case type1
        case type2
        case type3

        var color: Color {
            switch self {
            case .type1:
                return Color.red
            case .type2:
                return Color.green
            case .type3:
                return Color.blue
            }
        }

        var shape: AnyView {
            switch self {
            case .type1:
                return AnyView(Rectangle())
            case .type2:
                return AnyView(Circle())
            case .type3:
                return AnyView(Capsule())
            }
        }
    }
}

/// Example showing the use of the "differentiate without color" setting
/// and environment key.
private struct DifferentiateWithoutColorExample: View {
    private var colorModel: ColorModel = ColorModel()

    // Map in the environment value for `accessibilityDifferentiateWithoutColor`.
    // If this is true, the user has enabled the "differentiate without color"
    // setting on their device, and in your app you should avoid using
    // only color to differentiate aspects of your user experience.
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var body: some View {
        LabeledExample("Differentiate without Color") {
            VStack {
                ForEach(colorModel.values, id: \.self) { value in
                    // To differentiate without color, use different shapes
                    // for each value. Otherwise, all values can be a circle
                    // and differentiated only by color.
                    let shape = differentiateWithoutColor ? value.shape : AnyView(Circle())
                    shape
                        .foregroundColor(value.color)
                        .frame(width: 128, height: 64)
                }
            }
            .padding()
        }
    }
}

/// Example showing the use of the "reduce transparency" setting
/// and environment key.
private struct ReduceTransparencyView: View {
    // Map in the environment value for `accessibilityReduceTransparency`.
    // If this is true, the user has enabled the "reduce transparency"
    // setting on their device, and in your app you should avoid or reduce
    // transparent UI.
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency: Bool

    var body: some View {
        LabeledExample("Reduce Transparency") {
            Text("Some Text")
                .foregroundColor(Color.white)
                // Make this text partially transparent to blend it better into
                // the background, unless reduceTransparency is on,
                // in which case avoid transparency and prefer higher contrast.
                .opacity(reduceTransparency ? 1 : 0.5)
                .padding(8)
                .background { Color.black }
                .padding(20)
        }
    }
}

/// Example showing the use of the "reduce motion" setting
/// and environment key.
private struct ReduceMotionExample: View {
    // Map in the environment value for `accessibilityReduceMotion`.
    // If this is true, the user has enabled the "reduce motion"
    // setting on their device, and in your app you should avoid or reduce
    // any large-scale motion in your UI.
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion: Bool

    @State private var state: Bool = false

    var body: some View {
        let rectangle = RoundedRectangle(cornerRadius: defaultCornerRadius)
            .frame(width: 100, height: 50)
            .rotationEffect(.degrees(state ? 90 : 0))

        LabeledExample("Reduce Motion") {
            VStack(spacing: 30) {
                Button("Turn") {
                    // If reduce motion is enabled, change the state
                    // directly. If it is not, use `withAnimation` to animate
                    // the state change.
                    if reduceMotion {
                        state.toggle()
                    } else {
                        withAnimation {
                            state.toggle()
                        }
                    }
                }

                rectangle

                Spacer().frame(height: 20)
            }
            .padding()
        }
    }
}

/// Example showing the use of explicit API to make a view skip inverting
/// colors when the "invert colors" accessibility setting is on.
private struct IgnoreInvertColorsExample: View {
    // Map in the environment value for `accessibilityInvertColors`.
    // If this is true, the user has enabled the "invert colors"
    // setting on their device, and in your app you should account for the
    // colors of the user's display being inverted, using the
    // `accessibilityIgnoredInvertColors` API.
    @Environment(\.accessibilityInvertColors)
    private var invertColors: Bool

    var body: some View {
        LabeledExample("Ignore Invert Colors") {
            VStack {
                Text(invertColors ? "Invert Colors On" : "Invert Colors Off")

                Spacer().frame(height: 8)

                // This element is unmodified, so it will appear inverted if
                // "invert colors" is on.
                AccessibilityElementView(color: Color.orange, text: Text("Orange, Inverted"))

                // This element explicitly asks to ignore "invert colors". It
                // always appears purple, even if "invert colors" is on.
                AccessibilityElementView(color: Color.purple, text: Text("Purple, Uninverted"))
                    .accessibilityIgnoresInvertColors()
                
                VStack {
                    // This element doesn't ignore invert colors, which means
                    // it looks inverted when invert colors is on.
                    // The `false` value here undoes the
                    // `true` value coming from the outer `VStack`.
                    AccessibilityElementView(color: Color.red, text: Text("Red, Inverted"))
                        .accessibilityIgnoresInvertColors(false)

                    // This element takes the `true` value for `accessibilityIgnoresInvertColors`
                    // from the `VStack`. It ignores invert colors when
                    // invert colors is on, so it always appears uninverted.
                    AccessibilityElementView(color: Color.blue, text: Text("Blue, Uninverted"))

                    // This element also appears uninverted, because it
                    // explicitly wants to ignore invert colors.
                    AccessibilityElementView(color: Color.green, text: Text("Green, Uninverted"))
                        .accessibilityIgnoresInvertColors(true)
                }
                .accessibilityIgnoresInvertColors()
            }.padding()
        }
    }
}

/// Example showing the use of the "increase contrast" setting
/// and environment key.
private struct IncreaseContrastExample: View {
    // Map in the environment value for `colorSchemeContrast`.
    // If this is true, the user has enabled the "increase contrast"
    // setting on their device, and in your app you should draw controls
    // with increased contrast.
    @Environment(\.colorSchemeContrast)
    private var colorSchemeContrast: ColorSchemeContrast

    var body: some View {
        let shouldIncreaseContrast = colorSchemeContrast == .increased
        LabeledExample("Increase Contrast") {
            Text("C")
                // Adjust colors to increase contrast for better legibility.
                .foregroundColor(shouldIncreaseContrast ? Color.white : Color.gray)
                .frame(width: 100, height: 100, alignment: .center)
                .background {
                    RoundedRectangle(cornerRadius: defaultCornerRadius)
                        .fill(Color(white: shouldIncreaseContrast ? 0 : 0.4))
                }
        }
    }
}

/// Example showing the use of the environment variables showing the state of
/// accessibility features.
private struct AccessibilityFeaturesExample: View {
    // Map in the environment values for `accessibilityVoiceOverEnabled` and `accessibilitySwitchControlEnabled`.
    // If these are true, the user is working with these accessibility features.
    @Environment(\.accessibilityVoiceOverEnabled)
    private var voiceOverEnabled: Bool

    @Environment(\.accessibilitySwitchControlEnabled)
    private var switchControlEnabled: Bool

    @State private var isHovering: Bool = false

    var shouldShowHoverButton: Bool {
        // If VoiceOver or Switch Control are enabled, don't hide buttons
        // until they are hovered over. Instead, always show them so VoiceOver
        // users can access them.
        voiceOverEnabled || switchControlEnabled || isHovering
    }

    var body: some View {
        VStack(alignment: .center) {
            Text("First Line")
            Text("Second Line")
            if shouldShowHoverButton {
                Button("Shows on Hover") {}
                    .foregroundColor(Color.primary)
            }
        }
        .foregroundColor(Color.white)
        .padding()
        .frame(width: 200, height: 100)
        .background {
            RoundedRectangle(cornerRadius: defaultCornerRadius)
                .foregroundColor(Color.purple)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Example view showing the use of the various `accessibility` environment keys.
struct EnvironmentExample: View {
    var body: some View {
        VStack(alignment: .leading) {
            DifferentiateWithoutColorExample()
            ReduceTransparencyView()
            ReduceMotionExample()
            IgnoreInvertColorsExample()
            IncreaseContrastExample()
            AccessibilityFeaturesExample()
        }
        .frame(minWidth: 200)
    }
}

