/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NamesView.swift
*/

import SwiftUI

struct NamesView: View {
    @State private var selectedName = 2
    @State private var selectedStyle = PersonNameComponentsFormatter.Style.long
    
    let sampleNames = [
        // Arabic
        PersonNameComponents(familyName: "أسعد",
                             givenName: "باسل"),
        
        // Chinese, Simplified
        PersonNameComponents(familyName: "吴",
                             givenName: "菲",
                             phoneticRepresentation: PersonNameComponents(familyName: "Wú",
                                                                          givenName: "Fēi")),
        
        // Chinese, Traditional
        PersonNameComponents(familyName: "張",
                             givenName: "雅婷",
                             phoneticRepresentation: PersonNameComponents(familyName: "ㄓㄤˉ",
                                                                          givenName: "ㄧㄚˇㄊㄧㄥˊ")),
        
        // English
        PersonNameComponents(familyName: "Doe",
                             givenName: "Jane"),
        
        // Hindi
        PersonNameComponents(familyName: "प्रिया",
                             givenName: "कुमारी"),
        
        // Japanese
        PersonNameComponents(familyName: "山田",
                             givenName: "太郎",
                             phoneticRepresentation: PersonNameComponents(familyName: "ヤマダ",
                                                                          givenName: "タロウ")),
        
        // Thai
        PersonNameComponents(familyName: "โด",
                             givenName: "เจน")
    ]
    
    var body: some View {
        ScrollView {
            let selectedSampleName = sampleNames[selectedName]
            
            VStack {
                let abbreviatedName = PersonNameComponentsFormatter.localizedString(from: selectedSampleName, style: .abbreviated, options: [])
                // If `abbreviatedName` is more than two characters, fall back to showing a generic symbol instead.
                if abbreviatedName.count > 2 {
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 75)
                        .foregroundColor(.accentColor)
                } else {
                    Monogram(nameComponents: selectedSampleName, color: .accentColor, sideLength: 75)
                }
            }
            
            VStack {
                let name = PersonNameComponentsFormatter.localizedString(from: selectedSampleName, style: selectedStyle, options: [])
                Text(name)
                    .font(.title2)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
                
                let phoneticName = PersonNameComponentsFormatter.localizedString(from: selectedSampleName, style: selectedStyle, options: .phonetic)
                if !phoneticName.isEmpty {
                    Text(phoneticName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                }

                Picker("", selection: $selectedName) {
                    ForEach(sampleNames.indices) { index in
                        Text(PersonNameComponentsFormatter.localizedString(from: sampleNames[index], style: .medium, options: [])).tag(index)
                    }
                }
                
                Picker("", selection: $selectedStyle) {
                    Text(verbatim: "••").tag(PersonNameComponentsFormatter.Style.short)
                    Text(verbatim: "•••").tag(PersonNameComponentsFormatter.Style.medium)
                    Text(verbatim: "••••").tag(PersonNameComponentsFormatter.Style.long)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .background(RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .foregroundColor(.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05))
                            .padding(-10)
            )
            .padding(20)
        }
    }
}

struct NamesView_Previews: PreviewProvider {
    static var previews: some View {
        NamesView()
    }
}

// Convenience initializer for `PersonNameComponents`
extension PersonNameComponents {
    init(namePrefix: String? = nil,
         familyName: String? = nil,
         middleName: String? = nil,
         givenName: String? = nil,
         nameSuffix: String? = nil,
         nickname: String? = nil,
         phoneticRepresentation: PersonNameComponents? = nil) {
        self.init()
        self.namePrefix = namePrefix
        self.familyName = familyName
        self.middleName = middleName
        self.givenName = givenName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.phoneticRepresentation = phoneticRepresentation
    }
}
