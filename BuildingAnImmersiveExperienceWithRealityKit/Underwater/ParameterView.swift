/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SwiftUI view for changing parameter values.
*/
import SwiftUI

struct ParameterView: View {

    struct Parameter: Identifiable {

        let id: String
        let binding: Binding<Float>
    }
    let parameter: Parameter

    var body: some View {
        // Text field
        ValueTextFieldView(text: "\(parameter.id): ", value: parameter.binding)
            .textFieldStyle(RoundedBorderTextFieldStyle())

        // Log space slider
        Slider(
            value: .init(
                get: { log10(parameter.binding.wrappedValue) },
                set: { parameter.binding.wrappedValue = pow(10.0, $0) }
            ),
            in: -4...4
        )
    }
}

struct ValueTextFieldView: View {

    let text: String
    @Binding var value: Float

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.alwaysShowsDecimalSeparator = true
        formatter.allowsFloats = true
        formatter.usesSignificantDigits = true
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 7
        formatter.maximumFractionDigits = 8
        return formatter
    }()

    var body: some View {
        HStack {
            Text(text)
            TextField(
                "",
                value: $value,
                formatter: formatter)
        }
    }
}
