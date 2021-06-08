/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `DirectoryView`.
*/

import Foundation
import Combine
import SimplePushKit

class DirectoryViewModel: ObservableObject {
    enum State {
        case configurationNeeded
        case waitingForActivePushManager
        case connecting
        case connected
        case waitingForUsers
    }
    
    enum NetworkConfigurationMode {
        case wifi
        case cellular
        case both
    }
    
    @Published var state: State = .connecting
    @Published var users = [User]()
    @Published var connectedUser: User?
    private let dispatchQueue = DispatchQueue(label: "DirectoryViewModel.dispatchQueue")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe connection state changes for the control channel and map to the DirectoryViewModel state.
        ControlChannel.shared.statePublisher
            .combineLatest(SettingsManager.shared.settingsPublisher, PushConfigurationManager.shared.pushManagerIsActivePublisher, $users)
            .map { controlChannelState, settings, pushManagerIsActive, users -> State in
                guard !settings.pushManagerSettings.isEmpty else {
                    return .configurationNeeded
                }
                
                guard pushManagerIsActive else {
                    return .waitingForActivePushManager
                }
                
                switch controlChannelState {
                case .disconnected:
                    return .connecting
                case .disconnecting:
                    return .connecting
                case .connecting:
                    return .connecting
                case .connected where !users.isEmpty:
                    return .connected
                case .connected where users.isEmpty:
                    return .waitingForUsers
                default:
                    fatalError("Encountered a case that shouldn't happen")
                }
            }
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: dispatchQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }
            .store(in: &cancellables)
        
        // Observe updates to the user directory list and assign to the users array in the DirectoryViewModel.
        UserManager.shared.usersPublisher
            .debounce(for: .milliseconds(500), scheduler: dispatchQueue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] users in
                self?.users = users
            }
        .store(in: &cancellables)
        
        // Observe the call state of the CallManager and set the connected user when in an active call.
        CallManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .connected(let user):
                    self?.connectedUser = user
                case .connecting(let user):
                    self?.connectedUser = user
                case .disconnected, .disconnecting:
                    self?.connectedUser = nil
                }
            }
            .store(in: &cancellables)
    }
    
    var networkConfigurationMode: NetworkConfigurationMode {
        let settings = SettingsManager.shared.settings
        let isConnectedToWiFi = !settings.pushManagerSettings.ssid.isEmpty
        let isConnectedToCellular = !settings.pushManagerSettings.mobileCountryCode.isEmpty && !settings.pushManagerSettings.mobileNetworkCode.isEmpty
        
        if isConnectedToWiFi && isConnectedToCellular {
            return .both
        } else if isConnectedToWiFi {
            return .wifi
        } else {
            return .cellular
        }
    }
}
