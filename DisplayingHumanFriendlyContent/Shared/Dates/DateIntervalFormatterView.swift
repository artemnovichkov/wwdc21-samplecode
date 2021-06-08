/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DateIntervalFormatterView.swift
*/

import SwiftUI

struct DateIntervalFormatterView: View {
    private let startDate = sampleDate
    private let endDate = ISO8601DateFormatter().date(from: "2020-06-26T18:00:00-07:00")!

    @State private var formatterState = FormatterState()
    
    var body: some View {
        VStack {
            HStack {
                Text("अंतराल", comment: "Interval")
                    .font(.subheadline)
                    .textCase(.uppercase)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                    .padding(.leading, 10)
                Spacer()
            }
            
            VStack {
                let localizedDateInterval = formatterState.string(from: startDate, to: endDate)
                Text(localizedDateInterval)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                HStack {
                    Text("तारीख़", comment: "Date")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $formatterState.dateStyle) {
                        Text(verbatim: "∅").tag(DateIntervalFormatter.Style.none)
                        Text(verbatim: "•").tag(DateIntervalFormatter.Style.short)
                        Text(verbatim: "••").tag(DateIntervalFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateIntervalFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateIntervalFormatter.Style.full)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                HStack {
                    Text("समय", comment: "Time")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $formatterState.timeStyle) {
                        Text(verbatim: "∅").tag(DateIntervalFormatter.Style.none)
                        Text(verbatim: "•").tag(DateIntervalFormatter.Style.short)
                        Text(verbatim: "••").tag(DateIntervalFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateIntervalFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateIntervalFormatter.Style.full)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 5)
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
        private var formatter = DateIntervalFormatter()
        var dateStyle = DateIntervalFormatter.Style.medium { didSet { updateFormatter() } }
        var timeStyle = DateIntervalFormatter.Style.none { didSet { updateFormatter() } }

        init() {
            updateFormatter()
        }
        
        func string(from fromDate: Date, to toDate: Date) -> String {
            formatter.string(from: fromDate, to: toDate)
        }

        private func updateFormatter() {
            formatter.dateStyle = dateStyle
            formatter.timeStyle = timeStyle
        }
    }
}

struct DateIntervalFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        DateIntervalFormatterView()
    }
}
