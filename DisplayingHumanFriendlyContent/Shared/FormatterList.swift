/*
See LICENSE folder for this sample’s licensing information.

Abstract:
FormatterList.swift
*/

import SwiftUI

struct FormatterListView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DatesView()) {
                    Label("तारीख़ व समय", systemImage: "clock")
                }
                NavigationLink(destination: DatesView()) {
                    Label("माप", systemImage: "thermometer")
                }
                NavigationLink(destination: NameFormatter()) {
                    Label("नाम", systemImage: "person")
                }
                NavigationLink(destination: DatesView()) {
                    Label("लिस्ट", systemImage: "list.bullet")
                }
                NavigationLink(destination: DatesView()) {
                    Label("संख्या", systemImage: "textformat.123")
                }
                NavigationLink(destination: DatesView()) {
                    Label("टेक्स्ट", systemImage: "doc.plaintext")
                }
            }
            .navigationBarTitle(Text("प्रारूप"))
        }
    }
}

struct FormatterList_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(["iPhone SE", "iPad Pro (9.7-inch)"], id: \.self) { deviceName in
            FormatterListView()
                .previewDevice(PreviewDevice(rawValue: deviceName))
                .previewDisplayName(deviceName)
        }
    }
}
