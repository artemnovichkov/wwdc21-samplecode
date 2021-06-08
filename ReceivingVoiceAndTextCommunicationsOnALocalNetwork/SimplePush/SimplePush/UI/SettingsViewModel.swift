/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model for the `SettingsView`.
*/

import Foundation
import Combine
import SimplePushKit

class SettingsViewModel: ObservableObject {
    enum SettingsGroup {
        case cellular
        case wifi
    }
    
    @Published var settings: Settings
    @Published var isAppPushManagerActive = false
    @Published var carrier: CellularPushManagerSettings.Carrier?
    @Published var isCellularSettingsViewActive = false
    @Published var isWiFiSettingsViewActive = false
    
    private let cellularPushManagerSettings = CellularPushManagerSettings()
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(prependString: "SettingsViewModel", subsystem: .general)
    
    init() {
        settings = SettingsManager.shared.settings
        
        // Observe settings published by the SettingsManager to update the SettingsView.
        SettingsManager.shared.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.settings = settings
            }
            .store(in: &cancellables)
        
        // Observe the active state of NEAppPushManager to display the active state in the SettingsView.
        PushConfigurationManager.shared.pushManagerIsActivePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAppPushManagerActive in
                self?.isAppPushManagerActive = isAppPushManagerActive
            }
            .store(in: &cancellables)
        
        // Observe changes to the current carrier settings and update the local Carrier object when they are updated.
        cellularPushManagerSettings.carrierPublisher
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: &$carrier)
        
        // Observe changes to the active state of the cellular and Wi-Fi settings view. When either view is dismissed by the NavigationLink call the
        // `commit()` function to save any changes to the Settings.
        $isCellularSettingsViewActive.navigationLinkDidDismiss()
            .merge(with: $isWiFiSettingsViewActive.navigationLinkDidDismiss())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.commit()
            }
            .store(in: &cancellables)
    }
    
    func commit() {
        do {
            logger.log("Saving updated settings")
            try SettingsManager.shared.set(settings: settings)
        } catch {
            logger.log("Saving to settings failed with error: \(error)")
        }
    }
    
    func reset(settingsGroup: SettingsGroup) {
        var settings = settings
        
        switch settingsGroup {
        case .cellular:
            settings.pushManagerSettings.mobileCountryCode = ""
            settings.pushManagerSettings.mobileNetworkCode = ""
            settings.pushManagerSettings.trackingAreaCode = ""
        case .wifi:
            settings.pushManagerSettings.ssid = ""
        }
        
        self.settings = settings
    }
    
    func populateCurrentCarrier() {
        guard let carrier = carrier else {
            return
        }
        
        var settings = settings
        settings.pushManagerSettings.mobileCountryCode = carrier.mcc
        settings.pushManagerSettings.mobileNetworkCode = carrier.mnc
        
        self.settings = settings
    }
}

extension Publisher where Output == Bool {
    // A function that emits a signal when a NavigationLink dismisses a view after presenting it on screen.
    fileprivate func navigationLinkDidDismiss() -> AnyPublisher<Void, Failure> {
        scan((false, false), { previous, navigationLinkIsActive -> (isActive: Bool, didDismiss: Bool) in
            if previous.0 {
                return (navigationLinkIsActive, true)
            }
            return (navigationLinkIsActive, false)
        })
        .compactMap { _, didDismiss -> Void? in
            guard didDismiss else {
                return nil
            }
            return ()
        }
        .eraseToAnyPublisher()
    }
}
