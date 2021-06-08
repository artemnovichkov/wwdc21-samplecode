/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The settings view for the app's preferences window.
*/

import SwiftUI

struct SettingsView: View {

    var body: some View {
        Color.clear
            .frame(width: 400, height: 200, alignment: .top)
    }

    private struct GeneralSettings: View {
        @EnvironmentObject var store: Store

        var body: some View {
            Color.clear
        }
    }

    private struct ViewingSettings: View {
        var body: some View {
            Color.clear
        }
    }
}
