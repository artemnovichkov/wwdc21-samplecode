/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DateComponentsFormatterView.swift
*/

import SwiftUI

struct DateComponentsFormatterView: View {
    private let sampleDateComponents = DateComponents(hour: 2, minute: 15)
    
    @State private var dateComponentsStyle = DateComponentsFormatter.UnitsStyle.abbreviated
    
    var body: some View {
        VStack {
            HStack {
                Text("अवधि", comment: "Duration")
                    .font(.subheadline)
                    .textCase(.uppercase)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 10)
                Spacer()
            }
            VStack {
                let localizedDuration = DateComponentsFormatter.localizedString(from: sampleDateComponents, unitsStyle: dateComponentsStyle) ?? ""
                Text(localizedDuration)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                HStack {
                    Picker("", selection: $dateComponentsStyle) {
                        Text(verbatim: "•").tag(DateComponentsFormatter.UnitsStyle.positional)
                        Text(verbatim: "••").tag(DateComponentsFormatter.UnitsStyle.abbreviated)
                        Text(verbatim: "•••").tag(DateComponentsFormatter.UnitsStyle.brief)
                        Text(verbatim: "••••").tag(DateComponentsFormatter.UnitsStyle.short)
                        Text(verbatim: "•••••").tag(DateComponentsFormatter.UnitsStyle.full)
                        Text(verbatim: "••••••").tag(DateComponentsFormatter.UnitsStyle.spellOut)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .foregroundColor(.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05))
                            .padding(-10)
            )
                .padding(20)
        }
    }
}

struct DateComponentsFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        DateComponentsFormatterView()
            .padding(.all, 20)
    }
}
