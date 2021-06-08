/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ContentView.swift
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                let contentMaxWidth = 700 as CGFloat
                NavigationLink(destination: DatesView().frame(maxWidth: contentMaxWidth)) {
                    Label(LocalizedStringKey("तारीख़ व समय") /* Dates & Times */, systemImage: "clock")
                }
                NavigationLink(destination: MeasurementsView().frame(maxWidth: contentMaxWidth)) {
                    Label(LocalizedStringKey("माप") /* Measurements */, systemImage: "speedometer")
                }
                NavigationLink(destination: NamesView().frame(maxWidth: contentMaxWidth)) {
                    Label(LocalizedStringKey("नाम") /* Names */, systemImage: "person")
                }
                NavigationLink(destination: NumbersView().frame(maxWidth: contentMaxWidth)) {
                    Label(LocalizedStringKey("संख्या") /* Numbers */, systemImage: "textformat.123")
                }
            }
            .navigationTitle(Text("प्रारूप", comment: "Formatters"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone SE", "iPad Pro (9.7-inch)"], id: \.self) { deviceName in
            ContentView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
