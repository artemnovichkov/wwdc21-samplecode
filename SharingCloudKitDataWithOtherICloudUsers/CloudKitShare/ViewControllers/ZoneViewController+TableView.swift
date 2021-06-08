/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of ZoneViewController that manages the tableView data source and delegate.
*/

import UIKit

// MARK: - UITableViewDataSource and UITableViewDelegate
//
extension ZoneViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let zoneCache = zoneCacheOrNil else {
            return 0
        }
        return zoneCache.numberOfDatabase()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return zoneCacheOrNil?.cloudKitDB(at: section)?.name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let zoneCache = zoneCacheOrNil,
            let cloudKitDB = zoneCache.cloudKitDB(at: section) else {
            return 0
        }
        
        let databaseScope = cloudKitDB.databaseScope
        let zoneCount = zoneCache.numberOfZones(in: section)

        return (databaseScope == .private) && isEditing ? zoneCount + 1 : zoneCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: TableCellReusableID.subTitle, for: indexPath)
        let labelText = zoneCache.nameOfZone(at: indexPath)
        cell.textLabel?.text = labelText ?? "Add a zone"
        cell.detailTextLabel?.text = ""
        if splitViewController!.isCollapsed {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }
        
        if let cloudKitDB = zoneCache.cloudKitDB(at: indexPath.section), cloudKitDB.databaseScope == .shared {
            return .none // No edits on the zones in the CloudKit sharedDatabase.
        }
        let zoneCount = zoneCache.numberOfZones(in: indexPath.section)
        return zoneCount == indexPath.row ? .insert : .delete
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }
        
        // Adding a new zone doesn't have any race condition.
        if editingStyle == .insert {
            return addZone(at: indexPath.section)
        }
        spinner.startAnimating()

        // deleteZone -> .zoneCacheDidChange notification -> AppDelegate.zoneCacheDidChange -> Zone switching.
        // The spinner stops animating there.
        //
        let (cloudKitDB, zoneOrNil) = zoneCache.zone(at: indexPath)
        if let zone = zoneOrNil {
            zoneCache.deleteZone(zone, from: cloudKitDB)
        }
    }
}

