/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view used to update the application settings.
*/

import Foundation
import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    var presenter: Presenter?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Simple Push Server")) {
                    textField("Server Address", text: $viewModel.settings.pushManagerSettings.host)
                        .keyboardType(.numbersAndPunctuation)
                }
                Section(header: Text("Local Push Connectivity"), footer: Text("The NEAppPushProvider will remain active and receive incoming calls and messages while this device is on a configured cellular or Wi-Fi network.")) {
                    NavigationLink(
                        destination: cellularView(),
                        isActive: $viewModel.isCellularSettingsViewActive,
                        label: {
                            Text("Cellular")
                        })
                    NavigationLink(
                        destination: wifiView(),
                        isActive: $viewModel.isWiFiSettingsViewActive,
                        label: {
                            Text("Wi-Fi")
                        })
                    HStack {
                        Text("Active")
                        Spacer()
                        Text(viewModel.isAppPushManagerActive ? "Yes" : "No")
                    }
                }
            }
            .settingsStyle(title: "Settings")
            .navigationBarItems(leading: Button(action: {
                viewModel.commit()
                presenter?.dismiss()
            }, label: {
                Text("Done")
                    .fontWeight(.medium)
            }))
        }
    }
    
    @ViewBuilder func cellularView() -> some View {
        List {
            Section(header: Text("Carrier"), footer: Text("This device must be supervised to run Local Push Connectivity on a cellular network, unless the cellular network is Band 48 CBRS. The Tracking Area Code is only required on Band 48 CBRS networks.")) {
                textField("Mobile Country Code", text: $viewModel.settings.pushManagerSettings.mobileCountryCode)
                    .keyboardType(.numbersAndPunctuation)
                textField("Mobile Network Code", text: $viewModel.settings.pushManagerSettings.mobileNetworkCode)
                    .keyboardType(.numbersAndPunctuation)
                textField("Tracking Area Code (optional)", text: $viewModel.settings.pushManagerSettings.trackingAreaCode)
                    .keyboardType(.numbersAndPunctuation)
            }
            Section(footer: useCurrentCarrierButtonHelpTextView()) {
                Button(action: {
                    viewModel.populateCurrentCarrier()
                }, label: {
                    Text("Use Current Carrier")
                })
                .disabled(viewModel.carrier == nil)
            }
        }
        .settingsStyle(title: "Cellular")
        .navigationBarItems(trailing: Button(action: {
            viewModel.reset(settingsGroup: .cellular)
        }, label: {
            Text("Reset")
        }))
    }
    
    @ViewBuilder private func wifiView() -> some View {
        List {
            Section(header: Text("Network")) {
                textField("SSID", text: $viewModel.settings.pushManagerSettings.ssid)
                    .keyboardType(.numbersAndPunctuation)
            }
        }
        .settingsStyle(title: "Wi-Fi")
        .navigationBarItems(trailing: Button(action: {
            viewModel.reset(settingsGroup: .wifi)
        }, label: {
            Text("Reset")
        }))
    }
    
    @ViewBuilder private func useCurrentCarrierButtonHelpTextView() -> some View {
        if let carrier = viewModel.carrier {
            Text("Populate the Mobile Country Code and Mobile Network Code for \(carrier.carrierName).")
        } else {
            EmptyView()
        }
    }
    
    private func textField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text, onCommit: { [self] in
            viewModel.commit()
        })
    }
}
