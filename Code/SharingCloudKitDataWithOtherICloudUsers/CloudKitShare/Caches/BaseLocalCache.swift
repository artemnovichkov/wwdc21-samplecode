/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The base class for local caches.
*/

import Foundation
import CloudKit

extension Notification.Name {
    static let zoneCacheDidChange = Notification.Name("zoneCacheDidChange")
    static let topicCacheDidChange = Notification.Name("topicCacheDidChange")
    static let zoneDidSwitch = Notification.Name("zoneDidSwitch")
}

enum UserInfoKey: String {
    case topicCacheChanges, zoneCacheChanges, zoneSwitched
}

// The types for the notification payload.
//
struct TopicCacheChanges {
    let recordIDsDeleted: [CKRecord.ID]
    let recordsChanged: [CKRecord]
}

struct ZoneCacheChanges {
    let cloudKitDB: CKDatabase
    let zoneIDsDeleted: [CKRecordZone.ID]
    let zoneIDsChanged: [CKRecordZone.ID]
}

struct ZoneSwitched {
    let cloudKitDB: CKDatabase
    let zone: CKRecordZone
}

// The CloudKit database schema name constants.
//
struct Schema {
    struct RecordType {
        static let topic = "Topic"
        static let note = "Note"
    }
    struct Topic {
        static let name = "name"
    }
    struct Note {
        static let title = "title"
        static let topic = "topic"
    }
}

// Clients follow these rules to use `BaseLocalCache` or its subclasses in a thread-safe manner:
// - Call public methods directly. (Otherwise, you trigger a deadlock.)
// - Access mutable properties with "perform...".
//
class BaseLocalCache {
    // A CloudKit task can be a single operation (CKDatabaseOperation)
    // or multiple operations that you chain together.
    // Provide an operation queue to get more flexibility on CloudKit operation management.
    //
    lazy var operationQueue: OperationQueue = OperationQueue()
    
    // This sample accesses the cache by the following paths so the cache has to be thread-safe:
    // - Notifications -> fetchChanges -> CloudKit operation callbacks -> cache writing
    // - User editing -> cache writing
    // - User interface -> cache reading
    //
    // This sample uses this dispatch queue to implement the following logics:
    // - It serializes Writer blocks.
    // - The reader block can be concurrent, but it needs to wait for the enqueued writer blocks to complete.
    //
    // To achieve that, this sample uses the following pattern:
    // - Use a concurrent queue, cacheQueue.
    // - Use cacheQueue.async(flags: .barrier) {} to execute writer blocks.
    // - Use cacheQueue.sync(){} to execute reader blocks. The queue is concurrent,
    //    so reader blocks can be concurrent, unless any writer blocks are in the way.
    // Note that Writer blocks block the reader, so they need to be as small as possible.
    //
    private lazy var cacheQueue: DispatchQueue = {
        return DispatchQueue(label: "LocalCache", attributes: .concurrent)
    }()
    
    func performWriterBlock(_ writerBlock: @escaping () -> Void) {
        cacheQueue.async(flags: .barrier) {
            writerBlock()
        }
    }
    
    func performReaderBlockAndWait<T>(_ readerBlock: () -> T) -> T {
        return cacheQueue.sync {
            return readerBlock()
        }
    }
    
    // Using cacheQueue.async to guarantee that the post-block runs after all the in-queue writer
    // blocks complete (because the writer blocks have the .barrier attribute).
    //
    func performPostBlock(name: NSNotification.Name, object: Any? = nil, userInfo: [UserInfoKey: Any]? = nil) {
        cacheQueue.async {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
            }
        }
    }
}
