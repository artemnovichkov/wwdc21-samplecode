/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of TopicLocalCache that provides interfaces for view controllers.
*/

import Foundation
import CloudKit

// MARK: - Extended methods for view controllers
//
extension TopicLocalCache {
    func addTopic(with name: String) {
        let recordID = CKRecord.ID(zoneID: zone.zoneID)
        let newRecord = CKRecord(recordType: Schema.RecordType.topic, recordID: recordID)
        newRecord[Schema.Topic.name] = name as CKRecordValue?
    
        let operation = CKModifyRecordsOperation(recordsToSave: [newRecord], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if handleCloudKitError(error, operation: .modifyRecords, alert: true) == nil,
                let newRecord = records?.first {
                self.performAddingTopic(topicRecord: newRecord)
            }
            self.performPostBlock(name: .topicCacheDidChange)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    func deleteTopic(at index: Int) {
        guard let recordID = topicRecord(at: index)?.recordID else {
            return
        }
                
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        operation.modifyRecordsCompletionBlock = { (_, _, error) in
            if handleCloudKitError(error, operation: .modifyRecords, alert: true) == nil {
                self.performDeletingTopic(topicRecordID: recordID)
            }
            self.performPostBlock(name: .topicCacheDidChange)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    func addNote(_ newNoteRecord: CKRecord, topicRecordID: CKRecord.ID) {
        guard let topicRecord = topicRecord(with: topicRecordID) else {
            return
        }
        
        newNoteRecord[Schema.Note.topic] = CKRecord.Reference(record: topicRecord, action: .deleteSelf)
        newNoteRecord.parent = CKRecord.Reference(record: topicRecord, action: .none)

        let operation = CKModifyRecordsOperation(recordsToSave: [newNoteRecord], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if handleCloudKitError(error, operation: .modifyRecords, alert: true) == nil,
                let savedRecord = records?.first {
                self.performAddingNote(noteRecord: savedRecord, topicRecordID: topicRecordID)
            }
            self.performPostBlock(name: .topicCacheDidChange)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }
    
    func deleteNote(at indexPath: IndexPath) {
        guard let (topicRecord, noteRecord) = topicAndNoteRecords(at: indexPath) else {
            return
        }
        
        let (topicRecordID, noteRecordID) = (topicRecord.recordID, noteRecord.recordID)
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [noteRecordID])
        operation.modifyRecordsCompletionBlock = { (_, _, error) in
            if handleCloudKitError(error, operation: .modifyRecords, alert: true) == nil {
                self.performDeletingNote(noteRecordID: noteRecordID, topicRecordID: topicRecordID)
            }
            self.performPostBlock(name: .topicCacheDidChange)
        }
        
        operation.database = cloudKitDB
        operationQueue.addOperation(operation)
    }

    // Delete a record from the cache without updating the server side.
    // The sample calls this method from cloudSharingControllerDidStopSharing after stopping a share.
    //
    func deleteCachedRecord(_ record: CKRecord) {
        if record.recordType == Schema.RecordType.topic {
            performDeletingTopic(topicRecordID: record.recordID)
            
        } else if record.recordType == Schema.RecordType.note {
            guard let topicRef = record[Schema.Note.topic] as? CKRecord.Reference else {
                return
            }
            performDeletingNote(noteRecordID: record.recordID, topicRecordID: topicRef.recordID)
            
        } else {
            return
        }
        
        performPostBlock(name: .topicCacheDidChange)
    }
}

// MARK: - Extended accessors for view controllers
//
extension TopicLocalCache {
    func topicNameAndID(at index: Int) -> (String, CKRecord.ID)? {
        guard let topicRecord = topicRecord(at: index),
            let topicName = topicRecord[Schema.Topic.name] as? String else {
            return nil
        }
        return (topicName, topicRecord.recordID)
    }

    func noteTitle(at indexPath: IndexPath) -> String? {
        guard let (_, noteRecord) = topicAndNoteRecords(at: indexPath) else {
            return nil
        }
        return noteRecord[Schema.Note.title]
    }
}
