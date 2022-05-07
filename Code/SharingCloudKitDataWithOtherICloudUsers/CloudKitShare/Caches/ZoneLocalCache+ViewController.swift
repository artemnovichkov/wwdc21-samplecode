/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of ZoneLocalCache that provides interfaces for view controllers.
*/

import Foundation
import CloudKit

// MARK: - Extended methods for view controllers
//
extension ZoneLocalCache {
    func addZone(with zoneName: String, ownerName: String, to cloudKitDB: CKDatabase) {
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
        let newZone = CKRecordZone(zoneID: zoneID)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [newZone])
        operation.modifyRecordZonesCompletionBlock = { (zones, zoneIDs, error) in
            guard handleCloudKitError(error, operation: .modifyZones, alert: true) == nil,
                let savedZone = zones?.first else {
                self.performPostBlock(name: .zoneCacheDidChange)
                return
            }
            
            self.performAddingZone(savedZone, cloudKitDB: cloudKitDB)

            let payload = ZoneCacheChanges(cloudKitDB: cloudKitDB, zoneIDsDeleted: [], zoneIDsChanged: [zoneID])
            let userInfo = [UserInfoKey.zoneCacheChanges: payload]
            self.performPostBlock(name: .zoneCacheDidChange, userInfo: userInfo)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
        
    func deleteZone(_ zone: CKRecordZone, from cloudKitDB: CKDatabase) {
        let operation = CKModifyRecordZonesOperation(recordZoneIDsToDelete: [zone.zoneID])
        operation.modifyRecordZonesCompletionBlock = { (_, _, error) in
            guard handleCloudKitError(error, operation: .modifyRecords, alert: true) == nil else {
                self.performPostBlock(name: .zoneCacheDidChange)
                return
            }
            
            self.performDeletingZone(zoneID: zone.zoneID, cloudKitDB: cloudKitDB)
            
            let payload = ZoneCacheChanges(cloudKitDB: cloudKitDB, zoneIDsDeleted: [zone.zoneID], zoneIDsChanged: [])
            let userInfo = [UserInfoKey.zoneCacheChanges: payload]
            self.performPostBlock(name: .zoneCacheDidChange, userInfo: userInfo)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    // This sample calls this method from UICloudSharingControllerDelegate methods
    // after UICloudSharingController changes the CloudKit data.
    //
    func deleteCachedZone(_ zone: CKRecordZone, cloudKitDB: CKDatabase) {
        performDeletingZone(zoneID: zone.zoneID, cloudKitDB: cloudKitDB)
        
        let payload = ZoneCacheChanges(cloudKitDB: cloudKitDB, zoneIDsDeleted: [zone.zoneID], zoneIDsChanged: [])
        let userInfo = [UserInfoKey.zoneCacheChanges: payload]
        performPostBlock(name: .zoneCacheDidChange, userInfo: userInfo)
    }
}
