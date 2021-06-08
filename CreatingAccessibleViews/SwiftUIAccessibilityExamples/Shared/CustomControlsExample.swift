/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Custom control accessibility examples.
*/

import SwiftUI

/// Examples of accessibility annotations for custom controls.
struct CustomControlsExample: View {
    @State private var sliderValue: Double = 0.5
    @State private var isOn = false
    @State private var stepperValue = 1
    @State private var pickerValue = 0

    var body: some View {
        LabeledExample("Custom Slider") {
            TrackSlider(value: $sliderValue, label: "Custom Slider")
                .frame(width: 200, height: 30)
        }

        LabeledExample("Custom Switch") {
            TrackSwitch(isOn: $isOn, label: "Custom Switch")
                .frame(width: 60, height: 30)

        }

        LabeledExample("Manually-implemented Custom Button") {
            Circle()
                .foregroundColor(Color.white)
                .overlay(Image(systemName: "trash"))
                .onTapGesture {
                    // ...
                }
                .accessibilityRepresentation {
                    Button("Delete") {
                        // Same action as tap gesture.
                    }
                }
        }

        LabeledExample("Custom Stepper") {
            let shape = RoundedRectangle(cornerRadius: defaultCornerRadius)
            HStack {
                Image(systemName: "minus")
                    .disabled(stepperValue == 0)
                    .onTapGesture {
                        stepperValue -= 1
                    }

                Text("\(stepperValue)")
                    .frame(width: 50, alignment: .center)

                Image(systemName: "plus")
                    .onTapGesture {
                        stepperValue += 1
                    }
            }
            .padding()
            .frame(minWidth: 150)
            .background { shape.fill(.white) }
            .overlay { shape.stroke(.gray) }
            .accessibilityRepresentation {
                Stepper(value: $stepperValue, in: 0...100) {
                    Text("Custom Stepper")
                }
            }
        }

        LabeledExample("Custom Picker") {
            Text("Selected: \(pickerValue)")

            Spacer().frame(height: 15)

            HStack {
                Button("Option 1") { pickerValue = 0 }
                Button("Option 2") { pickerValue = 1 }
                Button("Option 3") { pickerValue = 2 }
            }
            .buttonStyle(.plain)
            .accessibilityRepresentation {
                Picker(selection: $pickerValue, label: Text("Custom Picker") ) {
                    Text("Option 1").tag(0)
                    Text("Option 2").tag(1)
                    Text("Option 3").tag(2)
                }
            }
        }
    }
}

// MARK: Custom Slider

private struct TrackSlider: View {
    @Binding var value: Double
    var label: String

    var body: some View {
        TrackShape(value: value)
            .accessibilityRepresentation {
                Slider(value: $value, in: 0...1) {
                    Text(label)
                }
            }
    }
}

// MARK: Custom Switch

private struct TrackSwitch: View {
    @Binding var isOn: Bool
    var label: String

    var body: some View {
        TrackShape(value: isOn ? 1 : 0)
            .accessibilityRepresentation {
                Toggle(isOn: $isOn) {
                    Text(label)
                }
            }
    }
}

// MARK: Drawing Views

private struct TrackShape: View {
    var value: Double

    private struct BackgroundTrack: View {
        var cornerRadius: CGFloat
        var body: some View {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .foregroundColor(Color(white: 0.2))
        }
    }

    private struct OverlayTrack: View {
        var cornerRadius: CGFloat
        var body: some View {
            let rectangle = RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )

            rectangle.foregroundColor(Color(white: 0.95))
                .overlay {
                    rectangle.stroke(Color.gray)
                }
        }
    }

    private struct Knob: View {
        var cornerRadius: CGFloat
        var body: some View {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .strokeBorder(Color(white: 0.7), lineWidth: 1)
            .shadow(radius: 3)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                BackgroundTrack(cornerRadius: geometry.size.height / 2)

                OverlayTrack(cornerRadius: geometry.size.height / 2)
                    .frame(
                        width: max(geometry.size.height, geometry.size.width * CGFloat(value) + geometry.size.height / 2),
                        height: geometry.size.height)

                Knob(cornerRadius: geometry.size.height / 2)
                    .frame(
                        width: geometry.size.height,
                        height: geometry.size.height)
                    .offset(x: max(0, geometry.size.width * CGFloat(value) - geometry.size.height / 2), y: 0)
            }
        }
    }
}

struct CustomControlsExample_Previews: PreviewProvider {
    static var previews: some View {
        CustomControlsExample()
    }
}
