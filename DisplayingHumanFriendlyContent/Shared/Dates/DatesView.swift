/*
See LICENSE folder for this sample’s licensing information.

Abstract:
DatesView.swift
*/

import SwiftUI

struct DatesView: View {
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "clock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 75)
                    .foregroundColor(.accentColor)
                DateFormatterView()
                DateComponentsFormatterView()
                DateIntervalFormatterView()
                RelativeDateTimeFormatterView()
            }
        }
    }
}

struct DatesView_Previews: PreviewProvider {
    static var previews: some View {
        DatesView()
    }
}
