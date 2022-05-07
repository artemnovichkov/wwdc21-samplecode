/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary manager for the app.
*/

import Foundation
import SwiftUI
import Combine
import SimplePushKit

class AppInitiator: ObservableObject {
    private(set) lazy var isExecutingInBackgroundPublisher: AnyPublisher<Bool, Never> = {
        Just(true)
        .merge(with:
            NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
            .map { notification -> Bool in
                notification.name == UIApplication.didEnterBackgroundNotification
            }
        )
        .debounce(for: .milliseconds(100), scheduler: dispatchQueue)
        .eraseToAnyPublisher()
    }()
    
    private let dispatchQueue = DispatchQueue(label: "AppManager.dispatchQueue")
    private var userViewModels = [UUID: UserViewModel]()
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "AppManager", subsystem: .general)
    
    init() {
        PushConfigurationManager.shared.initialize()
        MessagingManager.shared.initialize()
        MessagingManager.shared.requestNotificationPermission()
        
        // Register this device with the control channel.
        let user = User(uuid: UserManager.shared.currentUser.uuid, deviceName: UserManager.shared.currentUser.deviceName)
        ControlChannel.shared.register(user)
        
        // Connect the control channel when the app is in the foreground or responding to a CallKit call in the background.
        // Disconnect the control channel when the app is in the background and not in a CallKit call.
        isExecutingInBackgroundPublisher
            .combineLatest(CallManager.shared.$state)
            .sink { [weak self] isExecutingInBackground, callManagerState in
                guard let self = self else {
                    return
                }
                
                if isExecutingInBackground {
                    switch callManagerState {
                    case .connecting:
                        self.logger.log("App running in background and the CallManager's state is connecting, connecting to control channel")
                        ControlChannel.shared.connect()
                    case .disconnected:
                        self.logger.log("App running in background and the CallManager's state is disconnected, disconnecting from control channel")
                        ControlChannel.shared.disconnect()
                    default:
                        break
                    }
                } else {
                    self.logger.log("App running in foreground, connecting to control channel")
                    ControlChannel.shared.connect()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.logger.log("Application is terminating, disconnecting control channel")
                ControlChannel.shared.disconnect()
            }
            .store(in: &cancellables)
    }
    
    func viewModel(for user: User) -> UserViewModel {
        userViewModels.get(user.id, insert: UserViewModel(user: user))
    }
}
