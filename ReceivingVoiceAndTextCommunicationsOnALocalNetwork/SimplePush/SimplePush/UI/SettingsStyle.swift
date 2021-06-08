/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view modifier to apply a consistent format to the Settings screens.
*/

import Foundation
import SwiftUI

struct SettingsStyle: ViewModifier {
    var title: String
    
    func body(content: Content) -> some View {
        content
            .listStyle(InsetGroupedListStyle())
            .environment(\.defaultMinListRowHeight, 50.0)
            .navigationBarTitle(title, displayMode: .inline)
    }
}

extension View {
    func settingsStyle(title: String) -> some View {
        modifier(SettingsStyle(title: title))
    }
}
