/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Responds to app life cycle events and initializes the app's subsystems.
*/

import Foundation
import UIKit
import Combine
import SimplePushKit

class AppDelegate: NSObject, UIApplicationDelegate {
    private let dispatchQueue = DispatchQueue(label: "AppDelegate.dispatchQueue")
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "AppDelegate", subsystem: .general)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // It is important to initialize the PushConfigurationManager as early as possible during app initialization.
        PushConfigurationManager.shared.initialize()

        // Initialize the central messaging manager for text communication and request notification permission from the user.
        MessagingManager.shared.initialize()
        MessagingManager.shared.requestNotificationPermission()

        // Register this device with the control channel.
        let user = User(uuid: UserManager.shared.currentUser.uuid, deviceName: UserManager.shared.currentUser.deviceName)
        ControlChannel.shared.register(user)

        // Connect the control channel when the app is in the foreground or responding to a CallKit call in the background. Disconnect the control
        // channel when the app is in the background and not in a CallKit call.
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
                        self.logger.log("App running in background")
                    }
                } else {
                    self.logger.log("App running in foreground, connecting to control channel")
                    ControlChannel.shared.connect()
                }
            }
            .store(in: &cancellables)

        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        logger.log("Application is terminating, disconnecting control channel")
        ControlChannel.shared.disconnect()
    }
    
    // MARK: - Publishers
    
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
}
