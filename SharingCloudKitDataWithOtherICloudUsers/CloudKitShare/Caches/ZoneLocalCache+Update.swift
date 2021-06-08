/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of ZoneLocalCache that provides interfaces for fetching changes and updating the zone cache.
*/

import Foundation
import CloudKit

// MARK: - Extended methods for cache updating
//
extension ZoneLocalCache {
    func fetchChanges(from cloudKitDB: CKDatabase) {
        var zoneIDsChanged = [CKRecordZone.ID](), zoneIDsDeleted = [CKRecordZone.ID]()

        let serverChangeToken = getServerChangeToken(for: cloudKitDB)
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: serverChangeToken)

        // Gather the deleted zone IDs and process them in a batch in the completion block.
        //
        operation.recordZoneWithIDWasDeletedBlock = { zoneID in
            self.performDeletingZone(zoneID: zoneID, cloudKitDB: cloudKitDB)
            zoneIDsDeleted.append(zoneID)
        }
        
        // Gather the changed zones and process them in a batch in the completion block.
        //
        operation.recordZoneWithIDChangedBlock = { zoneID in
            zoneIDsChanged.append(zoneID)
        }
        
        // Update the server change token.
        //
        operation.changeTokenUpdatedBlock = { serverChangeToken in
            self.setServerChangeToken(newToken: serverChangeToken, cloudKitDB: cloudKitDB)
        }

        operation.fetchDatabaseChangesCompletionBlock = { (serverChangeToken, moreComing, error) in
            if let ckError = handleCloudKitError(error, operation: .fetchChanges, alert: true),
                ckError.code == .changeTokenExpired {
                self.setServerChangeToken(newToken: nil, cloudKitDB: cloudKitDB)
                self.fetchChanges(from: cloudKitDB) // Fetch changes again with a nil token.
                return
            }

            self.setServerChangeToken(newToken: serverChangeToken, cloudKitDB: cloudKitDB)
            
            guard !moreComing else {
                return
            }
            
            // The IDs in zoneIDsChanged can be in zoneIDsDeleted (you delete a changed zone),
            // so filter out the updated but deleted zoneIDs.
            //
            zoneIDsChanged = zoneIDsChanged.filter { zoneID in
                return !zoneIDsDeleted.contains(zoneID)
            }
            
            // Set database, recordIDsDeleted, and recordsChanged into the notification payload.
            //
            let payload = ZoneCacheChanges(cloudKitDB: cloudKitDB, zoneIDsDeleted: zoneIDsDeleted, zoneIDsChanged: zoneIDsChanged)
            let userInfo = [UserInfoKey.zoneCacheChanges: payload]
            
            // Make a copy of all zone IDs in the current database and filter out the existing IDs.
            //
            let existingZoneIDs = self.zoneIDs(in: cloudKitDB) // Make a copy of all zone IDs.
            let newZoneIDs = zoneIDsChanged.filter { !existingZoneIDs.contains($0) }
            
            // Post .zoneCacheDidChange if newZoneIDs.isEmpty.
            // Otherwise, post after fetching the new zones.
            //
            if newZoneIDs.isEmpty {
                self.performPostBlock(name: .zoneCacheDidChange, userInfo: userInfo)
            } else {
                self.fetchNewZones(with: newZoneIDs, cloudKitDB: cloudKitDB) { _ in
                    self.performPostBlock(name: .zoneCacheDidChange, userInfo: userInfo)
                }
            }
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    func fetchNewZones(with newZoneIDs: [CKRecordZone.ID], cloudKitDB: CKDatabase, completionHandler: (([CKRecordZone]) -> Void)? = nil) {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: newZoneIDs)
        
        operation.fetchRecordZonesCompletionBlock = { results, error in
            guard handleCloudKitError(error, operation: .fetchRecords) == nil, let zoneDictionary = results else {
                completionHandler?([])
                return
            }
            
            let zoneArray = Array(zoneDictionary.values)
            self.performAddingZoneArray(zoneArray, cloudKitDB: cloudKitDB)
            completionHandler?(zoneArray) // Call the completion handler.
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
}
