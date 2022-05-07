/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Bluetooth identifiers that are used throughout the project.
*/

import CoreBluetooth

enum BluetoothConstants {
    
    /// An identifier for the sample service.
    static let sampleServiceUUID = CBUUID(string: "AAAA")
    
    /// An identifier for the sample characteristic.
    static let sampleCharacteristicUUID = CBUUID(string: "BBBB")
    
    /// The defaults key that will be used for persisting the most recently received data.
    static let receivedDataKey = "received-data"
}
