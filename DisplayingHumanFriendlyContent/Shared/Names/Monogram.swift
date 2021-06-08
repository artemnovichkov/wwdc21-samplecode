/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Monogram.swift
*/

import SwiftUI

struct Monogram: View {
    var nameComponents: PersonNameComponents
    var color: Color
    var sideLength: CGFloat = 75
    var body: some View {
        Group {
            let abbreviatedName = PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .abbreviated, options: [])
            ZStack {
                Circle()
                    .stroke(color, lineWidth: sideLength * 0.1)
                Text(abbreviatedName)
                    .foregroundColor(color)
                    .padding(.all, sideLength * 0.1)
                    .minimumScaleFactor(0.1)
                    .scaledToFit()
                    .font(.system(size: 200, weight: .bold, design: .rounded))
                    
            }
            .frame(width: sideLength, height: sideLength)
        }
    }
}

struct Monogram_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            let sampleName = PersonNameComponents(familyName: "मिश्र", givenName: "करन")
            Monogram(nameComponents: sampleName, color: .orange)
                .padding(.bottom, 20)
            Monogram(nameComponents: sampleName, color: .blue, sideLength: 100)
                .padding(.bottom, 20)
            Monogram(nameComponents: sampleName, color: .pink, sideLength: 250)
        }
    }
}
