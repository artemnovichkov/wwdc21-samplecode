/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that describes the application's settings.
*/

import Foundation
import SimplePushKit

public struct Settings: Codable, Equatable {
    struct PushManagerSettings: Codable, Equatable {
        var ssid = ""
        var mobileCountryCode = ""
        var mobileNetworkCode = ""
        var trackingAreaCode = ""
        var host = ""
    }
    
    var uuid: UUID
    var deviceName: String
    var pushManagerSettings = PushManagerSettings()
}

extension Settings {
    var user: User {
        User(uuid: uuid, deviceName: deviceName)
    }
}

extension Settings.PushManagerSettings {
    // Convenience function that determines if the pushManagerSettings model has any valid configuration properties set. A valid configuration
    // includes both a host value and an SSID or private LTE network configuration.
    var isEmpty: Bool {
        if (!ssid.isEmpty || (!mobileCountryCode.isEmpty && !mobileNetworkCode.isEmpty)) && !host.isEmpty {
            return false
        } else {
            return true
        }
    }
}
