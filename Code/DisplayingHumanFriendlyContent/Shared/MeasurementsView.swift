/*
See LICENSE folder for this sample’s licensing information.

Abstract:
MeasurementsView.swift
*/

import SwiftUI

struct MeasurementsView: View {
    @State private var formatterState = FormatterState()

    var body: some View {
        VStack {
            Image(systemName: "speedometer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 75)
                .foregroundColor(.accentColor)
            
            VStack {
                let localizedTemperature = formatterState.string(from: Measurement<UnitTemperature>(value: 37, unit: .celsius))
                Text(localizedTemperature)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                let localizedSpeed = formatterState.string(from: Measurement<UnitSpeed>(value: 100, unit: .kilometersPerHour))
                Text(localizedSpeed)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                let localizedArea = formatterState.string(from: Measurement<UnitArea>(value: 1, unit: .acres))
                Text(localizedArea)
                    .font(.title2)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                
                Toggle(isOn: $formatterState.providedUnit, label: {
                    Text("दी गई इकाई", comment: "Provided Unit")
                })
                Toggle(isOn: $formatterState.naturalScale, label: {
                    Text("प्राकृतिक पैमाना", comment: "Natural Scale")
                })
                Toggle(isOn: $formatterState.temperatureWithoutUnit, label: {
                    Text("बग़ैर इकाई (सिर्फ़ तापमान पर लागू)", comment: "Temperature Without Unit")
                })
                Picker("", selection: $formatterState.selectedUnitStyle) {
                    Text(verbatim: "•").tag(MeasurementFormatter.UnitStyle.short)
                    Text(verbatim: "••").tag(MeasurementFormatter.UnitStyle.medium)
                    Text(verbatim: "•••").tag(MeasurementFormatter.UnitStyle.long)
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
    
    private struct FormatterState {
        private var formatter = MeasurementFormatter()
        var selectedUnitStyle = MeasurementFormatter.UnitStyle.medium { didSet { updateFormatter() } }
        var providedUnit = false { didSet { updateFormatter() } }
        var naturalScale = true { didSet { updateFormatter() } }
        var temperatureWithoutUnit = false { didSet { updateFormatter() } }

        init() {
            formatter.numberFormatter.maximumFractionDigits = 1
            updateFormatter()
        }
        
        func string<UnitType>(from measurement: Measurement<UnitType>) -> String where UnitType: Unit {
            formatter.string(from: measurement)
        }

        private func updateFormatter() {
            formatter.unitStyle = selectedUnitStyle
            var options: MeasurementFormatter.UnitOptions = []
            if providedUnit { options.insert(.providedUnit) }
            if naturalScale { options.insert(.naturalScale) }
            if temperatureWithoutUnit { options.insert(.temperatureWithoutUnit) }
            formatter.unitOptions = options
        }
    }
}

struct MeasurementsView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsView()
    }
}
