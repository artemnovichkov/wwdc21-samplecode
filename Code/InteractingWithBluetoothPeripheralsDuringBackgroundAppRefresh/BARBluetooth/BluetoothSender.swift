/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for advertising a bluetooth characteristic and responding to read requests from a remote device.
*/

import CoreBluetooth
import os.log

protocol BluetoothSenderDelegate: AnyObject {
    func getDataFor(readRequest: CBATTRequest) -> Data?
}

/// A sender that broadcasts values to multiple subscribers using a Bluetooth LE characteristic.
class BluetoothSender: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    
    private var logger = Logger(
        subsystem: SamplePeripheralApp.name,
        category: String(describing: BluetoothSender.self)
    )
    
    weak var delegate: BluetoothSenderDelegate?
    
    private var peripheralManager: CBPeripheralManager!
    
    private var service: CBMutableService!
        
    private var subscribers = Set<CBCentral>()
    
    init(service: CBMutableService) {
        super.init()
        self.service = service
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func startAdvertising() {
        guard !peripheralManager.isAdvertising else {
            logger.warning("already advertising")
            return
        }
        
        peripheralManager.removeAllServices()
        peripheralManager.add(service)
        
        let serviceUUID = service.uuid
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
        logger.info("started advertising")
    }
    
    private func stopAdvertising() {
        guard !peripheralManager.isAdvertising else {
            logger.warning("already stopped advertising")
            return
        }
        
        peripheralManager.stopAdvertising()
        logger.info("stopped advertising")
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        let state = peripheral.state
        logger.log("peripheral state is: \(state.rawValue)")
        
        if state == .poweredOn {
            startAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        logger.info("received read request for characteristic: \(request.characteristic.uuid)")
        if let responseData = delegate?.getDataFor(readRequest: request) {
            request.value = responseData
            peripheral.respond(to: request, withResult: .success)
        } else {
            peripheral.respond(to: request, withResult: .insufficientResources)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            logger.error("failed to add service: \(service.uuid): \(error.localizedDescription)")
        } else {
            logger.error("added service: \(service.uuid)")
        }
    }
}
