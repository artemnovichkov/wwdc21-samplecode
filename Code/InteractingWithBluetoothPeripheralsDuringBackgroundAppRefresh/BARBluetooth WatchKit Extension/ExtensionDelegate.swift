/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The delegate manages the the app's lifecycle and handles background refresh tasks.
*/

import WatchKit
import CoreBluetooth
import os.log

class ExtensionDelegate: NSObject, WKExtensionDelegate, BluetoothReceiverDelegate {
    
    private let logger = Logger(
        subsystem: BARBluetoothApp.name,
        category: String(describing: ExtensionDelegate.self)
    )
    
    private var currentRefreshTask: WKRefreshBackgroundTask?
    
    private(set) var bluetoothReceiver: BluetoothReceiver!
    
    override init() {
        super.init()
        
        bluetoothReceiver = BluetoothReceiver(
            service: BluetoothConstants.sampleServiceUUID,
            characteristic: BluetoothConstants.sampleCharacteristicUUID
        )
        
        bluetoothReceiver.delegate = self
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                
                logger.info("handling background app refresh task")
                
                /// Check to see if you disconnected from any peripherals. If not, then end the background refresh task.
                guard let peripheral = bluetoothReceiver.knownDisconnectedPeripheral, shouldReconnect(to: peripheral) else {
                    logger.info("no known disconnected peripheral to reconnect to")
                    completeRefreshTask(refreshTask)
                    return
                }
                
                /// Reconnect to the known disconnected bluetooth peripheral and read its characteristic value.
                bluetoothReceiver.connect(to: peripheral)
                
                refreshTask.expirationHandler = {
                    self.logger.info("background runtime is about to expire")
                    
                    /// When the background refresh task is about to expire, disconnect from the peripheral if you have not done so already
                    if let peripheral = self.bluetoothReceiver.connectedPeripheral {
                        self.bluetoothReceiver.disconnect(from: peripheral)
                    }
                }
                
                currentRefreshTask = refreshTask
                
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: .distantFuture, userInfo: nil)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    private func shouldReconnect(to peripheral: CBPeripheral) -> Bool {
        /// Implement your own logic to determine if the peripheral should be reconnected.
        return true
    }
    
    private func completeRefreshTask(_ task: WKRefreshBackgroundTask) {
        logger.info("setting background app refresh task as complete")
        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: BluetoothReceiverDelegate
    
    func didCompleteDisconnection(from peripheral: CBPeripheral) {
        /// If the peripheral completes its disconnection and you are handling a background refresh task, then complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        }
    }
    
    func didFailWithError(_ error: BluetoothReceiverError) {
        /// If the `BluetoothReceiver` fails and you are handling a background refresh task, then complete the task.
        if let refreshTask = currentRefreshTask {
            completeRefreshTask(refreshTask)
            currentRefreshTask = nil
        }
    }
    
    func didReceiveData(_ data: Data) {
        guard let value = try? JSONDecoder().decode(Int.self, from: data) else {
            logger.error("failed to decode float from data")
            return
        }
        
        logger.info("received value from peripheral: \(value)")
        UserDefaults.standard.setValue(value, forKey: BluetoothConstants.receivedDataKey)
        
        ComplicationController.updateAllActiveComplications()
        
        /// When you are handling a background refresh task and are done interacting with the peripheral, disconnect from it as soon as possible.
        if currentRefreshTask != nil, let peripheral = bluetoothReceiver.connectedPeripheral {
            bluetoothReceiver.disconnect(from: peripheral)
        }
    }
}
