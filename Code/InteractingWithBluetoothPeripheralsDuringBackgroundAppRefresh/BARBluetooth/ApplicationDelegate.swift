/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The delegate manages the lifecycle of the iOS app and responds to bluetooth read requests.
*/

import UIKit
import CoreBluetooth

/// Calculates the value based on the current time of day.
func getCurrentValue() -> Int {
    let secondsPerDay: Int = 24 * 60 * 60
    let secondsToday = Int(Date().timeIntervalSince1970) % secondsPerDay
    let percent = Double(secondsToday) / Double(secondsPerDay)
    return 20 + Int(percent * 10)
}

class ApplicationDelegate: NSObject, UIApplicationDelegate, BluetoothSenderDelegate {
    
    var bluetoothSender: BluetoothSender!
    
    let characteristic = CBMutableCharacteristic(
        type: BluetoothConstants.sampleCharacteristicUUID,
        properties: [.read],
        value: nil,
        permissions: .readable
    )
    
    override init() {
        super.init()
        
        /// Initialize the bluetooth sender with a service and a characteristic.
        let service = CBMutableService(type: BluetoothConstants.sampleServiceUUID, primary: true)
        service.characteristics = [characteristic]
        
        bluetoothSender = BluetoothSender(service: service)
        bluetoothSender.delegate = self
    }
    
    // MARK: BluetoothSenderDelegate
    
    /// Respond to a read request by sending a value for the characteristic
    func getDataFor(readRequest: CBATTRequest) -> Data? {
        if readRequest.characteristic == characteristic {
            let data = getCurrentValue()
            return try? JSONEncoder().encode(data)
        } else {
            return nil
        }
    }
}
