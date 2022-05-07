/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The zone local cache class that manages the zone local cache.
*/

import Foundation
import CloudKit

// Wrap a CKDatabase, its change token, and its zones.
//
private final class Database {
    var serverChangeToken: CKServerChangeToken?
    let cloudKitDB: CKDatabase
    var zones = [CKRecordZone]()
    
    init(cloudKitDB: CKDatabase) {
        self.cloudKitDB = cloudKitDB
    }
}

// "container" and "database" are immutable; "zones" and "serverChangeToken" in Database are mutable.
// ZoneLocalCache follows these rules to be thread-safe:
// - Public methods access "zones" and "serverChangeToken" in Database with "perform...".
// - Call private methods that access mutable properties with "perform...".
// - Private methods access mutable properties directly because of the above.
// - Access immutable properties directly.
//
final class ZoneLocalCache: BaseLocalCache {
    private let container: CKContainer
    private let databases: [Database]
    
    // Subscribe the database changes and do the first fetch from the server to build up the cache.
    //
    // This sample uses CKDatabaseSubscription to sync the changes on sharedDB and custom zones of privateDB.
    // CKDatabaseSubscription currently doesn't support the default zone.
    // CKRecordZoneSubscription currently doesn't support the default zone and sharedDB.
    // CKQuerySubscription currently doesn't support shardDB.
    //
    init(_ container: CKContainer) {
        self.container = container
        
        databases = [Database(cloudKitDB: container.privateCloudDatabase),
                     Database(cloudKitDB: container.sharedCloudDatabase)]
        super.init()

        for database in databases {
            database.cloudKitDB.addDatabaseSubscription(
                subscriptionID: database.cloudKitDB.name, operationQueue: operationQueue) { error in
                guard handleCloudKitError(error, operation: .modifySubscriptions, alert: true) == nil else {
                    return
                }
                self.fetchChanges(from: database.cloudKitDB)
            }
        }
    }
    
    private func database(with cloudKitDB: CKDatabase) -> Database {
        guard let index = databases.firstIndex(where: { $0.cloudKitDB === cloudKitDB }) else {
            fatalError("\(#function): Failed to find the Database object for cloudKitDB: \(cloudKitDB)")
        }
        return databases[index]
    }
}

// MARK: - Core accessors
//
extension ZoneLocalCache {
    func numberOfDatabase() -> Int {
        return databases.count
    }
    
    func cloudKitDB(at section: Int) -> CKDatabase? {
        return section < databases.count ? databases[section].cloudKitDB : nil
    }
    
    func cloudKitDB(with scope: CKDatabase.Scope) -> CKDatabase? {
        if let index = databases.firstIndex(where: { $0.cloudKitDB.databaseScope == scope }) {
            return databases[index].cloudKitDB
        }
        return nil
    }
    
    func cloudKitDB(with name: String) -> CKDatabase? {
        if let index = databases.firstIndex(where: { $0.cloudKitDB.name == name }) {
            return databases[index].cloudKitDB
        }
        return nil
    }

    func getServerChangeToken(for cloudKitDB: CKDatabase) -> CKServerChangeToken? {
        return performReaderBlockAndWait {
            if let index = self.databases.firstIndex(where: { $0.cloudKitDB === cloudKitDB }) {
                return self.databases[index].serverChangeToken
            }
            return nil
        }
    }
    
    func setServerChangeToken(newToken: CKServerChangeToken?, cloudKitDB: CKDatabase) {
        performWriterBlock {
            if let index = self.databases.firstIndex(where: { $0.cloudKitDB === cloudKitDB }) {
                self.databases[index].serverChangeToken = newToken
            }
        }
    }
    
    // Search and return the first zone and its database.
    //
    func firstZone() -> (CKDatabase, CKRecordZone)? {
        return performReaderBlockAndWait {
            for database in databases where !database.zones.isEmpty {
                return (database.cloudKitDB, database.zones[0])
            }
            return nil
        }
    }
    
    // Search and return a zone with a zoneID and a database scope.
    //
    func zone(with zoneID: CKRecordZone.ID, cloudKitDB: CKDatabase) -> CKRecordZone? {
        return performReaderBlockAndWait {
            let database = self.database(with: cloudKitDB)
            if let index = database.zones.firstIndex(where: { $0.zoneID == zoneID }) {
                return database.zones[index]
            }
            return nil
        }
    }
    
    // Search a zone using an indexPath of ZoneViewController's tableview.
    // Return the zone (if any) and its database.
    //
    func zone(at indexPath: IndexPath) -> (CKDatabase, CKRecordZone?) {
        return performReaderBlockAndWait {
            let newDatabase = self.databases[indexPath.section]
            if indexPath.row < newDatabase.zones.count {
                return (newDatabase.cloudKitDB, newDatabase.zones[indexPath.row])
            }
            return (newDatabase.cloudKitDB, nil)
        }
    }
    
    // Search the specified (database, zone)
    // and return the result as an indexPath of ZoneViewController's tableview.
    //
    func indexPath(for cloudKitDB: CKDatabase, zone: CKRecordZone) -> IndexPath? {
        return performReaderBlockAndWait {
            if let section = self.databases.firstIndex(where: { $0.cloudKitDB === cloudKitDB }),
                let row = self.databases[section].zones.firstIndex(where: { $0.zoneID == zone.zoneID }) {
                return IndexPath(row: row, section: section)
            }
            return nil
        }
    }
    
    // Return the number of zones in a specified database.
    // Specify the database using a section of ZoneViewController's tableview.
    //
    func numberOfZones(in section: Int) -> Int {
        return performReaderBlockAndWait {
            return databases[section].zones.count
        }
    }
    
    // Return the zone name for the specified zone.
    // Specify the zone using an indexPath of ZoneViewController's tableview.
    //
    func nameOfZone(at indexPath: IndexPath) -> String? {
        return performReaderBlockAndWait {
            let database = databases[indexPath.section]
            guard indexPath.row < database.zones.count else {
                return nil
            }
            return database.zones[indexPath.row].zoneID.zoneName
        }
    }
    
    func zoneIDs(in cloudKitDB: CKDatabase) -> [CKRecordZone.ID] {
        return performReaderBlockAndWait {
            let database = self.database(with: cloudKitDB)
            return database.zones.map { $0.zoneID }
        }
    }
}

extension ZoneLocalCache { // MARK: - Core methods
    func performAddingZone(_ zone: CKRecordZone, cloudKitDB: CKDatabase) {
        performWriterBlock {
            let database = self.database(with: cloudKitDB)
            guard !database.zones.contains(where: { $0.zoneID == zone.zoneID }) else {
                return
            }
            database.zones.append(zone)
            database.zones.sort(by: { $0.zoneID.zoneName < $1.zoneID.zoneName })
        }
    }
    
    func performAddingZoneArray(_ zoneArray: [CKRecordZone], cloudKitDB: CKDatabase) {
        performWriterBlock {
            let database = self.database(with: cloudKitDB)
            let count = database.zones.count
            for zone in zoneArray {
                if !database.zones.contains(where: { $0.zoneID == zone.zoneID }) {
                    database.zones.append(zone)
                }
            }
            if database.zones.count > count {
                database.zones.sort { $0.zoneID.zoneName < $1.zoneID.zoneName }
            }
        }
    }
    
    func performDeletingZone(zoneID: CKRecordZone.ID, cloudKitDB: CKDatabase) {
        performWriterBlock {
            let database = self.database(with: cloudKitDB)
            if let index = database.zones.firstIndex(where: { $0.zoneID == zoneID }) {
                database.zones.remove(at: index)
            }
        }
    }
}
