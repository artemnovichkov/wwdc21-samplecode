/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The color picker.
*/

import SwiftUI

struct SystemColorList: View {
    @Binding var color: Color
    var remove: () -> Void

    var body: some View {
        List {
            Section(header: Text("Color")) {
                SystemColorPicker(color: $color)
                    .pickerStyle(.inline)
                    .labelsHidden()
            }

            Section {
                HStack {
                    Spacer()
                    Button("Delete", role: .destructive, action: remove)
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
    }

    struct Empty: View {
        var body: some View {
            List {
                Section(header: Text("Color")) {
                    Text("No selection")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SystemColorPicker: View {
    @Binding var color: Color

    var body: some View {
        let options = [
            ColorOption(name: "White", color: .white),
            ColorOption(name: "Gray", color: .gray),
            ColorOption(name: "Black", color: .black),
            ColorOption(name: "Red", color: .red),
            ColorOption(name: "Orange", color: .orange),
            ColorOption(name: "Yellow", color: .yellow),
            ColorOption(name: "Green", color: .green),
            ColorOption(name: "Mint", color: .mint),
            ColorOption(name: "Teal", color: .teal),
            ColorOption(name: "Cyan", color: .cyan),
            ColorOption(name: "Blue", color: .blue),
            ColorOption(name: "Indigo", color: .indigo),
            ColorOption(name: "Purple", color: .purple),
            ColorOption(name: "Pink", color: .pink),
            ColorOption(name: "Brown", color: .brown)
        ]
        Picker("Color", selection: $color) {
            ForEach(options) { option in
                Label {
                    Text(option.name)
                } icon: {
                    option.color
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.tertiary, lineWidth: 1)
                        }
                        .cornerRadius(6)
                        .frame(width: 32, height: 32)
                }
                .tag(option.color)
            }
        }
    }
}

struct ColorOption: Identifiable {
    var name: String
    var color: Color

    var id: String { name }
}
