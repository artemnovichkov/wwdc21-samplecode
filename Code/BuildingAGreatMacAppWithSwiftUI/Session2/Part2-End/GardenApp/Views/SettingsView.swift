/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The settings view for this app's preferences window.
*/

import SwiftUI

struct SettingsView: View {

    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ViewingSettings()
                .tabItem {
                    Label("Viewing", systemImage: "eyeglasses")
                }
        }
        .frame(width: 400, height: 200, alignment: .top)
    }

    private struct GeneralSettings: View {
        @EnvironmentObject var store: Store
        @AppStorage("defaultGarden") private var selection: Garden.ID?

        var body: some View {
            Form {
                Picker("Default Garden", selection: $selection) {
                    Text("None").tag(Garden.ID?.none)
                    ForEach(store.gardens) { garden in
                        Text("\(garden.name), \(garden.displayYear)")
                            .tag(Garden.ID?.some(garden.id))
                    }
                }
                .fixedSize()
                .padding()
            }
        }
    }

    private struct ViewingSettings: View {
        var body: some View {
            Color.clear
        }
    }
}
