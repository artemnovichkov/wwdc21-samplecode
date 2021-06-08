/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The local cache class that manages the local cache for topics and notes.
*/

import UIKit
import CloudKit

// The class that manages the Note record and its permissions.
//
private final class Note {
    var record: CKRecord
    var permission = CKShare.ParticipantPermission.readWrite
    
    var title: String { // The title of a Note record shouldn't be nil.
        guard let noteTitle = record[Schema.Note.title] as? String else {
            return ""
        }
        return noteTitle
    }
    
    init(noteRecord: CKRecord) {
        record = noteRecord
    }
}

// The Topic record and its permissions.
//
private final class Topic {
    var record: CKRecord
    var permission = CKShare.ParticipantPermission.readWrite
    var notes: [Note]
    
    var name: String { // The topic name shouldn't be nil.
        guard let topicName = record[Schema.Topic.name] as? String else {
            return ""
        }
        return topicName
    }
    
    init(topicRecord: CKRecord, notes: [Note] = [Note]()) {
        record = topicRecord
        self.notes = notes
    }
        
    func setPermission(with shares: [CKShare]) -> Int? {
        for (index, share) in shares.enumerated() where record.share?.recordID == share.recordID {
            if let participant = share.currentUserParticipant {
                permission = participant.permission
                return index
            }
        }
        return nil
    }
}

// "container", "database", and "zone" are immutable; "topics" and "serverChangeToken" are mutable,
// so "topic.permission", "topic.notes", "topic.record", "note.permission", "note.record" are mutable.
//
// TopicLocalCache follows these rules to be thread-safe:
// - Public methods access mutable properties with "perform...".
// - Call private methods that access mutable properties with "perform...".
// - Private methods access mutable properties directly because of the above.
// - Access immutable properties directly.
//
final class TopicLocalCache: BaseLocalCache {
    let container: CKContainer
    let cloudKitDB: CKDatabase
    let zone: CKRecordZone
    
    private var serverChangeToken: CKServerChangeToken?
    private var topics = [Topic]()
    
    init(container: CKContainer, cloudKitDB: CKDatabase, zone: CKRecordZone) {
        self.container = container
        self.cloudKitDB = cloudKitDB
        self.zone = zone
        
        super.init()
        
        fetchChanges() // Fetching changes with a nil token to build up the cache.
    }
}

// MARK: - Private utilities for cache updating
//
// - Process the changed topics. Any records not in the existing cache are new.
// Several things to consider:
// 1. For a new sharing topic:
// The root record and the share record are both in recordsChanged, so you can retrieve the
// permissions from the share record.
//
// 2. For a note:
// It's shared because it has a shared parent, so CloudKit doesn’t create a share record.
// The permission is the same as the parent.
//
// 3. For a permission change:
// Only the associated share record changes and is in recordsChanged, so this sample has to
// go through the local cache to update the permission.
//
// - Remove the deleted records from the cache, and handle Topic records first.
// If CloudKit removes a topic, it also removes all its notes.
//
extension TopicLocalCache {
    // Search and return the topic and topic index of a child note record.
    //
    private func topicAndIndex(with childNoteRecord: CKRecord) -> (Topic, Int)? {
        var topicOrNil: Topic?, topicIndexOrNil: Int?
        
        if let topicRef = childNoteRecord[Schema.Note.topic] as? CKRecord.Reference {
            if let index = topics.firstIndex(where: { $0.record.recordID == topicRef.recordID }) {
                topicOrNil = topics[index]
                topicIndexOrNil = index
            }
        }
        guard let topic = topicOrNil, let topicIndex = topicIndexOrNil else {
            print("\(#function): Failed to find the topic for a changed note!")
            return nil
        }
        return (topic, topicIndex)
    }
    
    // Update the permissions of the topics, only for sharedDB.
    // Remove the processed share from sharesChanged. Stop when sharesChanged is empty.
    //
    private func updatePermissionIfNeeded(with recordsChanged: [CKRecord], topicsChanged: [Topic]) {
        guard cloudKitDB.databaseScope == .shared else {
            return
        }

        var sharesChanged = [CKShare]()
        for record in recordsChanged where record is CKShare {
            if let share = record as? CKShare {
                sharesChanged.append(share)
            }
        }
        // Set permissions with the gathered share records if they match.
        // This happens when first sharing a topic.
        //
        for topic in topicsChanged {
            guard !sharesChanged.isEmpty else {
                return
            }
            if let index = topic.setPermission(with: sharesChanged) {
                sharesChanged.remove(at: index)
            }
        }
        
        // There are some share records with changes that need processing.
        // This happens when users change the share options, which only affects the share record,
        // not the root record. In that case, go through the entire TopicLocalCache to
        // find the right item and update its permissions.
        //
        for topic in topics {
            guard !sharesChanged.isEmpty else {
                return
            }
            if let index = topic.setPermission(with: sharesChanged) {
                sharesChanged.remove(at: index)
            }
        }
    }
    
    // Update the topics with the changed records that you get from CloudKit.
    //
    private func updateTopicsWithRecordsChanged(_ recordsChanged: [CKRecord]) {
        guard !recordsChanged.isEmpty else {
            return
        }

        var isTopicNameChanged = false
        var topicsChanged = [Topic]()
        
        for record in recordsChanged where record.recordType == Schema.RecordType.topic {
            let topicChanged: Topic
            if let index = topics.firstIndex(where: { $0.record.recordID == record.recordID }) {
                topicChanged = topics[index]
                topicChanged.record = record // Simply replace it with the record from the server.
                
                if isTopicNameChanged { continue }
                isTopicNameChanged = (topicChanged.name != record[Schema.Topic.name])
                
            } else { // A new topic.
                topicChanged = Topic(topicRecord: record)
                topics.append(topicChanged)
                isTopicNameChanged = true // There’s at least one new topic, so sort the topics later.
            }
            topicsChanged.append(topicChanged)
        }

        if isTopicNameChanged { // Sort the topics by name if there are changes to the names.
            topics.sort { $0.name < $1.name }
        }
        
        // Update the permissions of the topics.
        updatePermissionIfNeeded(with: recordsChanged, topicsChanged: topicsChanged)
    }

    // Update the notes with the changed records that you get from CloudKit.
    //
    private func updateNotesWithRecordsChanged(_ recordsChanged: [CKRecord]) {
        guard !recordsChanged.isEmpty else {
            return
        }
        
        let isSharedDB = (cloudKitDB.databaseScope == .shared)
        var unsortedTopicIndice = [Int]()
        
        for record in recordsChanged where record.recordType == Schema.RecordType.note {
            guard let (topic, topicIndex) = topicAndIndex(with: record) else {
                continue
            }
            var isNoteNameChanged = false

            if let noteIndex = topic.notes.firstIndex(where: { $0.record.recordID == record.recordID }) {
                let noteChanged = topic.notes[noteIndex]
                noteChanged.record = record
                
                if isNoteNameChanged { continue }
                isNoteNameChanged = (noteChanged.title != record[Schema.Note.title])
                
            } else { // A new note.
                let noteChanged = Note(noteRecord: record)
                if isSharedDB {
                    noteChanged.permission = topic.permission
                }
                topic.notes.append(noteChanged)
                isNoteNameChanged = true // There’s a new note, so sort the notes later.
            }

            // If there’s a change to the note name, gather the topic index.
            //
            if isNoteNameChanged && !unsortedTopicIndice.contains(topicIndex) {
                unsortedTopicIndice.append(topicIndex)
            }
        }
        
        for index in unsortedTopicIndice { // Sort the notes in the sorted topics.
            topics[index].notes.sort { $0.title < $1.title }
        }
    }
    
    // Remove the deleted records from the cache, and handle the Topic records first.
    // If CloudKit removes a topic, it removes all its notes as well.
    //
    private func updateWithRecordIDsDeleted(_ recordIDsDeleted: [CKRecord.ID]) {
        var noteIDsDeleted = [CKRecord.ID]()
        
        for recordID in recordIDsDeleted {
            if let index = topics.firstIndex(where: { $0.record.recordID == recordID }) {
                topics.remove(at: index)
            } else {
                noteIDsDeleted.append(recordID)
            }
        }
        
        noteIDLoop: for recordID in noteIDsDeleted {
            for topic in topics {
                if let index = topic.notes.firstIndex(where: { $0.record.recordID == recordID }) {
                    topic.notes.remove(at: index)
                    continue noteIDLoop
                }
            }
        }
    }
}

// MARK: - Core accessors
//
extension TopicLocalCache {
    func getServerChangeToken() -> CKServerChangeToken? {
        return performReaderBlockAndWait { return self.serverChangeToken }
    }
    
    func setServerChangeToken(newToken: CKServerChangeToken?) {
        performWriterBlock { self.serverChangeToken = newToken }
    }
    
    func topicRecord(at index: Int) -> CKRecord? {
        return performReaderBlockAndWait {
            return index < topics.count ? topics[index].record : nil
        }
    }

    func topicRecord(with recordID: CKRecord.ID) -> CKRecord? {
        return performReaderBlockAndWait {
            let index = self.topics.firstIndex(where: { $0.record.recordID == recordID })
            return index == nil ? nil : self.topics[index!].record
        }
    }

    func permissionOfTopic(at section: Int) -> CKShare.ParticipantPermission? {
        return performReaderBlockAndWait {
            return section < topics.count ? topics[section].permission : nil
        }
    }
    
    func numberOfTopics() -> Int {
        return performReaderBlockAndWait { return topics.count }
    }
    
    func numberOfNotes(at section: Int) -> Int? {
        return performReaderBlockAndWait {
            return section < topics.count ? topics[section].notes.count : nil
        }
    }
    
    func noteRecordAndPermission(at indexPath: IndexPath) -> (CKRecord, CKShare.ParticipantPermission)? {
        return performReaderBlockAndWait {
            guard indexPath.section < topics.count else {
                return nil
            }
            let topic = topics[indexPath.section]
            guard indexPath.row < topic.notes.count else {
                return nil
            }
            let note = topic.notes[indexPath.row]
            return (note.record, note.permission)
        }
    }
    
    func topicAndNoteRecords(at indexPath: IndexPath) -> (CKRecord, CKRecord)? {
        return performReaderBlockAndWait {
            guard indexPath.section < topics.count else {
                return nil
            }
            let topic = topics[indexPath.section]
            
            guard indexPath.row < topic.notes.count else {
                return nil
            }
            return (topic.record, topic.notes[indexPath.row].record)
        }
    }
}

// MARK: - Core methods
//
extension TopicLocalCache {
    func performUpdatingWithRecordIDsDeleted(_ recordIDsDeleted: [CKRecord.ID]) {
        performWriterBlock {
            self.updateWithRecordIDsDeleted(recordIDsDeleted)
        }
    }

    func performUpdatingTopicsWithRecordsChanged(_ recordsChanged: [CKRecord]) {
        performWriterBlock {
            self.updateTopicsWithRecordsChanged(recordsChanged)
        }
    }

    func performUpdatingNotesWithRecordsChanged(_ recordsChanged: [CKRecord]) {
        performWriterBlock {
            self.updateNotesWithRecordsChanged(recordsChanged)
        }
    }
    
    func performAddingTopic(topicRecord: CKRecord) {
        performWriterBlock {
            let topic = Topic(topicRecord: topicRecord) // There’s no need to fetch the notes for a new topic.
            self.topics.append(topic)
            self.topics.sort { $0.name < $1.name }
        }
    }
    
    func performDeletingTopic(topicRecordID: CKRecord.ID) {
        performWriterBlock {
            if let index = self.topics.firstIndex(where: { $0.record.recordID == topicRecordID }) {
                self.topics.remove(at: index)
            }
        }
    }

    func performAddingNote(noteRecord: CKRecord, topicRecordID: CKRecord.ID) {
        performWriterBlock {
            if let index = self.topics.firstIndex(where: { $0.record.recordID == topicRecordID }) {
                let topic = self.topics[index]
                if !topic.notes.contains(where: { $0.record.recordID == noteRecord.recordID }) {
                    topic.notes.append(Note(noteRecord: noteRecord))
                    topic.notes.sort { $0.title < $1.title }
                }
            }
        }
    }
    
    func performDeletingNote(noteRecordID: CKRecord.ID, topicRecordID: CKRecord.ID) {
        performWriterBlock {
            if let index = self.topics.firstIndex(where: { $0.record.recordID == topicRecordID }) {
                let topic = self.topics[index]
                if let noteIndex = topic.notes.firstIndex(where: { $0.record.recordID == noteRecordID }) {
                    topic.notes.remove(at: noteIndex)
                }
            }
        }
    }
}
