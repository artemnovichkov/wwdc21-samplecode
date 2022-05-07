/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the app that lists other connected users.
*/

import Foundation
import SwiftUI
import Combine
import SimplePushKit

struct DirectoryView: View {
    @EnvironmentObject var rootViewCoordinator: RootViewCoordinator
    @StateObject private var viewModel = DirectoryViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                List(viewModel.users) { user in
                    Button {
                        rootViewCoordinator.presentedView = .user(user, nil)
                    } label: {
                        HStack {
                            Text(user.deviceName)
                                .font(.headline)
                                .fontWeight(.regular)
                                .foregroundColor(Color("Colors/PrimaryText"))
                            Spacer()
                            Circle()
                                .fill(fillForCallIndicator(user: user))
                                .frame(width: 10.0)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .environment(\.defaultMinListRowHeight, 50.0)
                
                VStack {
                    if viewModel.state != .connected {
                        placeholderView(state: viewModel.state)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .edgesIgnoringSafeArea(.all)
                            .background(viewModel.state == .connected ? Color.clear : Color("Colors/GroupedListBackground"))
                            .transition(transition)
                    }
                }
            }
            .navigationBarTitle("Contacts", displayMode: .large)
            .navigationBarItems(leading: Button {
                rootViewCoordinator.presentedView = .settings
            } label: {
                Text("Settings")
                    .fontWeight(.medium)
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder func placeholderView(state: DirectoryViewModel.State) -> some View {
        VStack(spacing: 30) {
            image(for: state)
                .font(.system(size: 60, weight: .regular))
                .foregroundColor(Color("Colors/PrimaryText"))
            Text(stateHumanReadable)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("Colors/PrimaryText"))
                .padding([.leading, .trailing], 30)
        }
    }
    
    @ViewBuilder func image(for state: DirectoryViewModel.State) -> some View {
        switch state {
        case .configurationNeeded:
            Image(systemName: "wrench")
        case .waitingForActivePushManager:
            Image(systemName: "exclamationmark.triangle")
        case .waitingForUsers:
            Image(systemName: "person.crop.circle.badge.xmark")
        case .connecting, .connected:
            Image(systemName: "bolt")
        }
    }
    
    var stateHumanReadable: String {
        switch viewModel.state {
        case .configurationNeeded:
            return "Configure Server and Local Push Connectivity in Settings"
        case .waitingForActivePushManager:
            let ssid = SettingsManager.shared.settings.pushManagerSettings.ssid
            
            switch viewModel.networkConfigurationMode {
            case .wifi:
                return "Connect to \(ssid)"
            case .cellular:
                return "Connect to the configured cellular network"
            case .both:
                return "Connect to \(ssid) or the configured cellular network"
            }
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .waitingForUsers:
            return "Waiting for contacts"
        }
    }
    
    func fillForCallIndicator(user: User) -> Color {
        guard let connectedUser = viewModel.connectedUser,
            connectedUser.uuid == user.uuid else {
                return .clear
        }
        return .blue
    }
   
    var transition: AnyTransition {
        let duration = 0.5
        
        return AnyTransition
            .opacity
            .animation(.easeInOut(duration: duration))
    }
}
