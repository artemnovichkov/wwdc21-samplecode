/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NumbersView.swift
*/

import SwiftUI

struct NumbersView: View {
    @State private var formatterState = FormatterState()
    
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "textformat.123")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 75)
                    .foregroundColor(.accentColor)
                
                VStack {
                    let localizedNumber = formatterState.string(from: 32.745)
                    Text(localizedNumber)
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Picker("", selection: $formatterState.numberStyle) {
                        Text("प्रतिशत", comment: "Percent").tag(NumberFormatter.Style.percent)
                        Text("क्रमसूचक", comment: "Ordinal").tag(NumberFormatter.Style.ordinal)
                        Text("सांख्यिक", comment: "Decimal").tag(NumberFormatter.Style.decimal)
                        Text("वैज्ञानिक", comment: "Scientific").tag(NumberFormatter.Style.scientific)
                        Text("शाब्दिक", comment: "Spell Out").tag(NumberFormatter.Style.spellOut)
                        Text("मुद्रा", comment: "Currency").tag(NumberFormatter.Style.currency)
                        Text("मुद्रा – शाब्दिक", comment: "Currency – Spell Out").tag(NumberFormatter.Style.currencyPlural)
                        Text("मुद्रा – हिसाब किताब", comment: "Currency – Accounting").tag(NumberFormatter.Style.currencyAccounting)
                        Text("मुद्रा – ISO कोड", comment: "Currency – ISO Code").tag(NumberFormatter.Style.currencyISOCode)
                    }
                    
                    HStack {
                        Text("पूर्ण व दशमलव अंक", comment: "Integer & Fractional Digits")
                            .font(.subheadline)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Stepper(value: $formatterState.minimumIntegerDigits) {
                        Text("कम से कम \(formatterState.minimumIntegerDigits) पूर्ण अंक", comment: "At least N integer digits")
                    }
                    Stepper(value: $formatterState.maximumIntegerDigits) {
                        Text("ज़्यादा से ज़्यादा \(formatterState.maximumIntegerDigits) पूर्ण अंक", comment: "At most N integer digits")
                    }
                    Stepper(value: $formatterState.minimumFractionDigits) {
                        Text("कम से कम \(formatterState.minimumFractionDigits) दशमलव अंक", comment: "At least N fractional digits")
                    }
                    Stepper(value: $formatterState.maximumFractionDigits) {
                        Text("ज़्यादा से ज़्यादा \(formatterState.maximumFractionDigits) दशमलव अंक", comment: "At most N fractional digits")
                    }
                    
                    HStack {
                        Text("राउंडिंग मोड", comment: "Rounding Mode")
                            .font(.subheadline)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Picker("", selection: $formatterState.roundingMode) {
                        Image(systemName: "equal.circle").tag(NumberFormatter.RoundingMode.halfEven)
                        Image(systemName: "circle.bottomhalf.fill").tag(NumberFormatter.RoundingMode.halfDown)
                        Image(systemName: "circle.tophalf.fill").tag(NumberFormatter.RoundingMode.halfUp)
                        Image(systemName: "arrow.up.to.line").tag(NumberFormatter.RoundingMode.ceiling)
                        Image(systemName: "arrow.down.to.line").tag(NumberFormatter.RoundingMode.floor)
                        Image(systemName: "arrow.up").tag(NumberFormatter.RoundingMode.up)
                        Image(systemName: "arrow.down").tag(NumberFormatter.RoundingMode.down)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                                .foregroundColor(.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05))
                                .padding(-10)
                )
                .padding(20)
                Spacer()
            }
        }
    }
    
    private struct FormatterState {
        private var formatter = NumberFormatter()
        var numberStyle = NumberFormatter.Style.decimal { didSet { updateFormatter() } }
        var minimumFractionDigits = 0 { didSet { updateFormatter() } }
        var maximumFractionDigits = 2 { didSet { updateFormatter() } }
        var minimumIntegerDigits = 1 { didSet { updateFormatter() } }
        var maximumIntegerDigits = 42 { didSet { updateFormatter() } }
        var roundingMode = NumberFormatter.RoundingMode.halfEven { didSet { updateFormatter() } }

        init() {
            updateFormatter()
        }
        
        func string(from number: NSNumber) -> String {
            formatter.string(from: number) ?? ""
        }

        private func updateFormatter() {
            formatter.numberStyle = numberStyle
            formatter.minimumFractionDigits = minimumFractionDigits
            formatter.maximumFractionDigits = maximumFractionDigits
            formatter.minimumIntegerDigits = minimumIntegerDigits
            formatter.maximumIntegerDigits = maximumIntegerDigits
            formatter.roundingMode = roundingMode
        }
    }
}

struct NumbersView_Previews: PreviewProvider {
    static var previews: some View {
        NumbersView()
    }
}
