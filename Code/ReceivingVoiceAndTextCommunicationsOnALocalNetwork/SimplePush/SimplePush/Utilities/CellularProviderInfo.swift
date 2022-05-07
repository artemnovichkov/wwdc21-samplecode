/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object for obtaining the current cellular carrier information of the user's device.
*/

import Foundation
import CoreTelephony
import Combine
import SimplePushKit

class CellularPushManagerSettings {
    struct Carrier {
        var carrierName: String
        var mcc: String
        var mnc: String
    }
    
    private(set) lazy var carrierPublisher = carrierSubject.dropNil()
    private let networkInfo = CTTelephonyNetworkInfo()
    private let carrierSubject = CurrentValueSubject<Carrier?, Never>(nil)
    private let logger = Logger(prependString: "CellularpushManagerSettings", subsystem: .general)
    
    init() {
        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] serviceIdentifier in
            self?.logger.log("Cell carrier information did update.")
            self?.updateServices()
        }
        
        updateServices()
    }
    
    private func updateServices() {
        guard let carriers = networkInfo.serviceSubscriberCellularProviders else {
            return
        }
        
        for (_, carrier) in carriers {
            guard let carrierName = carrier.carrierName, !carrierName.isEmpty,
                  let carrier = Carrier(carrier: carrier) else {
                logger.log("Cell carrier information is empty.")
                continue
            }
            
            carrierSubject.send(carrier)
        }
    }
}

extension CellularPushManagerSettings.Carrier {
    init?(carrier: CTCarrier?) {
        guard let carrierName = carrier?.carrierName,
              let mcc = carrier?.mobileCountryCode,
              let mnc = carrier?.mobileNetworkCode
        else {
            return nil
        }
        
        self.carrierName = carrierName
        self.mcc = mcc
        self.mnc = mnc
    }
}
