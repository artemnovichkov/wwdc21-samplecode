/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class helps test interactions with CLLocationManager by providing block-based
 overrides tests can hook and inject.
*/

import CoreLocation

class InjectableCLLocationManager: CLLocationManager {
    var requestWhenInUseAuthorizationBlock: (() -> Void)? = nil
    override func requestWhenInUseAuthorization() {
        guard let block = requestWhenInUseAuthorizationBlock else {
            super.requestWhenInUseAuthorization()
            return
        }
        block()
    }
    
    var authorizationStatusOverride: CLAuthorizationStatus? = nil
    override var authorizationStatus: CLAuthorizationStatus {
        guard let statusOverride = authorizationStatusOverride else {
            return super.authorizationStatus
        }
        return statusOverride
    }
}

class CLLocationManagerBlockDelegate: NSObject, CLLocationManagerDelegate {
    var didChangeAuthorizationBlock: ((_ manager: CLLocationManager) -> Void)? = nil
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let block = didChangeAuthorizationBlock else {
            return
        }
        block(manager)
    }
}
