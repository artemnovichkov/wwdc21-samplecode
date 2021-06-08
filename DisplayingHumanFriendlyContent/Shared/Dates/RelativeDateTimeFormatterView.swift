/*
See LICENSE folder for this sample’s licensing information.

Abstract:
RelativeDateTimeFormatterView.swift
*/

import SwiftUI

struct RelativeDateTimeFormatterView: View {
    @State private var formatterState = FormatterState()
    
    var body: some View {
        VStack {
            HStack {
                Text("तुलनात्‍मक", comment: "Relative")
                    .font(.subheadline)
                    .textCase(.uppercase)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 10)
                Spacer()
            }
            
            VStack {
                let dayBeforeYesterday = formatterState.string(from: DateComponents(day: -2))
                Text(dayBeforeYesterday)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                let yesterday = formatterState.string(from: DateComponents(day: -1))
                Text(yesterday)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                let someTimeAgo = formatterState.string(from: DateComponents(minute: -37))
                Text(someTimeAgo)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                let threeHoursLater = formatterState.string(from: DateComponents(hour: 3))
                Text(threeHoursLater)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                let tomorrow = formatterState.string(from: DateComponents(day: 1))
                Text(tomorrow)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                let dayAfterTomorrow = formatterState.string(from: DateComponents(day: 2))
                Text(dayAfterTomorrow)
                    .font(.title3)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                
                HStack {
                    Picker("", selection: $formatterState.dateTimeStyle) {
                        Text("स्वाभाविक", comment: "Natural").tag(RelativeDateTimeFormatter.DateTimeStyle.named)
                        Text("संख्या", comment: "Numeric").tag(RelativeDateTimeFormatter.DateTimeStyle.numeric)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                HStack {
                    Picker("", selection: $formatterState.unitsStyle) {
                        Text(verbatim: "•").tag(RelativeDateTimeFormatter.UnitsStyle.abbreviated)
                        Text(verbatim: "••").tag(RelativeDateTimeFormatter.UnitsStyle.short)
                        Text(verbatim: "•••").tag(RelativeDateTimeFormatter.UnitsStyle.full)
                        Text(verbatim: "••••").tag(RelativeDateTimeFormatter.UnitsStyle.spellOut)
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
    
    private struct FormatterState {
        private var formatter = RelativeDateTimeFormatter()
        var unitsStyle = RelativeDateTimeFormatter.UnitsStyle.short { didSet { updateFormatter() } }
        var dateTimeStyle = RelativeDateTimeFormatter.DateTimeStyle.named { didSet { updateFormatter() } }

        init() {
            updateFormatter()
        }
        
        func string(from dateComponents: DateComponents) -> String {
            return formatter.localizedString(from: dateComponents)
        }
        
        private func updateFormatter() {
            formatter.dateTimeStyle = dateTimeStyle
            formatter.unitsStyle = unitsStyle
        }
    }
}

struct RelativeDateTimeFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        RelativeDateTimeFormatterView()
    }
}
