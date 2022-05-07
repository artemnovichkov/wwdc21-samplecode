/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DateFormatterView.swift
*/

import SwiftUI

// ISO 8601 is a standard that defines date/time formats in a locale-independent manner that can be used for technical interchange. It’s also a nifty way to initialize a specific date/time.
let sampleDate = ISO8601DateFormatter().date(from: "2020-06-22T09:41:00-07:00")!

struct DateFormatterView: View {
    @State private var selectedDateStyle = DateFormatter.Style.short
    @State private var selectedTimeStyle = DateFormatter.Style.short
    @State private var formatterState = FormatterState()

    var body: some View {
        VStack {
            // Styles
            VStack {
                let localizedDate = DateFormatter.localizedString(from: sampleDate, dateStyle: selectedDateStyle, timeStyle: selectedTimeStyle)
                Text(localizedDate)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                HStack {
                    Text("तारीख़", comment: "Date")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $selectedDateStyle) {
                        Text(verbatim: "∅").tag(DateFormatter.Style.none)
                        Text(verbatim: "•").tag(DateFormatter.Style.short)
                        Text(verbatim: "••").tag(DateFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateFormatter.Style.full)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                HStack {
                    Text("समय", comment: "Time")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $selectedTimeStyle) {
                        Text(verbatim: "∅").tag(DateFormatter.Style.none)
                        Text(verbatim: "•").tag(DateFormatter.Style.short)
                        Text(verbatim: "••").tag(DateFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateFormatter.Style.full)
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
            
            // Templates
            VStack {
                let template = formatterState.template
                let dateFormat = formatterState.dateFormat
                let localizedDate = formatterState.string(from: sampleDate)
                
                Text(localizedDate)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                HStack {
                    Text("टेंप्लेट", comment: "Template")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Text(template)
                        .font(.system(size: 14, design: .monospaced))
                    // Allow easy copying of the template
                    Button(action: { writeToPasteboard(template) }) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                HStack {
                    Text("तारीख़ प्रारूप", comment: "Date Format")
                        .font(.subheadline)
                        .textCase(.uppercase)
                        .foregroundColor(.gray)
                    Text(dateFormat)
                        .font(.system(size: 14, design: .monospaced))
                    Spacer()
                }
                .padding(.top, 10)
                
                ForEach(formatterState.templateFields) { templateField in
                    HStack {
                        Text(templateField.title)
                            .font(.subheadline)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $formatterState.selectedPatterns[templateField.id]) {
                            ForEach(templateField.patterns.indices) { index in
                                if templateField.patterns[index] == "" {
                                    Text(verbatim: "∅").tag(templateField.patterns[index])
                                } else {
                                    Text(lengthIndicator(length: index)).tag(templateField.patterns[index])
                                }
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .foregroundColor(.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05))
                            .padding(-10)
            )
            .padding(20)
        }
    }
    
    func lengthIndicator(length: Int) -> String {
        var result = ""
        for _ in 1...length {
            result += "•"
        }
        return result
    }
    
    private struct TemplateField: Identifiable {
        let id: Int
        let title: LocalizedStringKey
        let patterns: [String]
    }

    private struct FormatterState {
        let templateFields = [
            // https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
            TemplateField(id: 0, title: LocalizedStringKey("काल" /* Era */), patterns: [ "", "GGGGG", "G", "GGGG" ]),
            TemplateField(id: 1, title: LocalizedStringKey("साल" /* Year */), patterns: [ "", "yy", "y" ]),
            TemplateField(id: 2, title: LocalizedStringKey("माह" /* Month */), patterns: [ "", "MMMMM", "M", "MMM", "MMMM" ]),
            TemplateField(id: 3, title: LocalizedStringKey("दिन" /* Day */), patterns: [ "", "d", "dd" ]),
            TemplateField(id: 4, title: LocalizedStringKey("वार" /* Day of Week */), patterns: [ "", "EEEEE", "EEEEEE", "EEE", "EEEE" ]),
            TemplateField(id: 5, title: LocalizedStringKey("घंटा" /* Hour */), patterns: [ "", "j", "jj" ]),
            TemplateField(id: 6, title: LocalizedStringKey("मिनट" /* Minute */), patterns: [ "", "m", "mm" ]),
            TemplateField(id: 7, title: LocalizedStringKey("सेकंड" /* Second */), patterns: [ "", "s", "ss" ])
        ]
        
        private var formatter = DateFormatter()
        var template = ""
        var dateFormat = ""
        var selectedPatterns = [
            "",
            "y",
            "MMM",
            "d",
            "EEE",
            "j",
            "m",
            ""
        ] { didSet { updateFormatter() } }

        init() {
            updateFormatter()
        }
        
        func string(from date: Date) -> String {
            formatter.string(from: date)
        }

        private mutating func updateFormatter() {
            template = selectedPatterns.joined()
            dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: Locale.current) ?? ""
            formatter.setLocalizedDateFormatFromTemplate(template)
        }
    }
}

struct DateFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        DateFormatterView()
    }
}

