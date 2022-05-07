/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of TopicLocalCache that provides interfaces for updating cache with server changes.
*/

import Foundation
import CloudKit

// MARK: - Extended methods for cache updating
//
extension TopicLocalCache {
    // Fetch zone changes from the server and update the cache.
    // Only custom zones support fetching changes.
    //
    func fetchChanges() {
        var recordsChanged = [CKRecord](), recordIDsDeleted = [CKRecord.ID]()

        let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        configuration.previousServerChangeToken = getServerChangeToken()
        
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zone.zoneID], configurationsByRecordZoneID: [zone.zoneID: configuration]
        )

        // Gather the changed records and process them in a batch in the completion block.
        //
        operation.recordChangedBlock = {
            (record) in recordsChanged.append(record)
        }
        
        // Gather the deleted record IDs and process them in a batch in the completion block.
        //
        operation.recordWithIDWasDeletedBlock = {
            (recordID, _) in recordIDsDeleted.append(recordID)
        }

        // Update the server change token.
        //
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneID, serverChangeToken, _) in
            assert(zoneID == self.zone.zoneID)
            self.setServerChangeToken(newToken: serverChangeToken)
        }

        // Fetch changes again with a nil token if the token has expired.
        //
        operation.recordZoneFetchCompletionBlock = {
            (zoneID, serverChangeToken, clientChangeTokenData, moreComing, error) in
            if let ckError = handleCloudKitError(error, operation: .fetchChanges),
                ckError.code == .changeTokenExpired {
                self.setServerChangeToken(newToken: nil)
                self.fetchChanges()
                
            } else {
                assert(zoneID == self.zone.zoneID && moreComing == false)
                self.setServerChangeToken(newToken: serverChangeToken)
            }
        }

        operation.fetchRecordZoneChangesCompletionBlock = { error in
            // This sample calls TopicLocalCache.fetchChanges when getting a database change notification.
            // Deleting a zone by a peer doesn't trigger a fetchRecordZoneChangesOperation.
            //
            // .zoneNotFound can happen when a participant removes itself from a share and the
            // share is the only item in the current zone. In that case,
            // cloudSharingControllerDidStopSharing deletes the cached zone, which triggers a zone switching.
            // So this sample ignores .zoneNotFound here.
            //
            if let ckError = handleCloudKitError(error, operation: .fetchChanges,
                                                 affectedObjects: [self.zone.zoneID]) {
                print("Error in fetchRecordZoneChangesCompletionBlock: \(ckError)")
            }
            
            // Filter out the updated but deleted IDs.
            //
            recordsChanged = recordsChanged.filter {
                record in return !recordIDsDeleted.contains(record.recordID)
            }
            
            // Update the cache with the deleted recordIDs.
            self.performUpdatingWithRecordIDsDeleted(recordIDsDeleted)
            
            // Update the topics and notes with the changed records.
            //
            self.performUpdatingTopicsWithRecordsChanged(recordsChanged)
            self.performUpdatingNotesWithRecordsChanged(recordsChanged)
            
            // The modification payload contains recordIDsDeleted and recordsChanged.
            //
            let payload = TopicCacheChanges(recordIDsDeleted: recordIDsDeleted, recordsChanged: recordsChanged)
            let userInfo = [UserInfoKey.topicCacheChanges: payload]
            self.performPostBlock(name: .topicCacheDidChange, userInfo: userInfo)
            
            print("\(#function):Deleted \(recordIDsDeleted.count); Changed \(recordsChanged.count)")
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    // A convenient method for fetching a record with a recordID and updating the cache.
    //
    func fetchRecord(with recordID: CKRecord.ID) {
        let operation = CKFetchRecordsOperation(recordIDs: [recordID])
        
        operation.fetchRecordsCompletionBlock = { (recordsByRecordID, error) in
            guard handleCloudKitError(error, operation: .fetchRecords, affectedObjects: [recordID]) == nil,
                let record = recordsByRecordID?[recordID]  else {
                return
            }
            
            if record.recordType == Schema.RecordType.topic {
                self.performUpdatingTopicsWithRecordsChanged([record])
                self.performPostBlock(name: .topicCacheDidChange)
            } else if record.recordType == Schema.RecordType.note {
                self.performUpdatingNotesWithRecordsChanged([record])
                self.performPostBlock(name: .topicCacheDidChange)
            }
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
}
