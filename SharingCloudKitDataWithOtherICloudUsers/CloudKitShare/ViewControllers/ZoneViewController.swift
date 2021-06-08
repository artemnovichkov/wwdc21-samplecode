/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller class that presents the zones in the current iCloud container and manages zone deletion and creation.
*/

import UIKit
import CloudKit

// ZoneViewController: Presents the zones in the current iCloud container and manages zone deletion and creation.
// Conflict handling isn’t necessary here because:
// - Adding a new zone has no conflict.
// - If the user deletes a zone that doesn't exist on the server, CloudKit returns
// .zoneNotFound or .itemNotFound for the deletion operation to handle.
//
final class ZoneViewController: SpinnerViewController {
    var zoneCacheOrNil: ZoneLocalCache? {
        return (UIApplication.shared.delegate as? AppDelegate)?.zoneCacheOrNil
    }

    var topicCacheOrNil: TopicLocalCache? {
        return (UIApplication.shared.delegate as? AppDelegate)?.topicCacheOrNil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.zoneCacheDidChange(_:)),
            name: .zoneCacheDidChange, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.zoneDidSwitch(_:)),
            name: .zoneDidSwitch, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.isEnabled = !(zoneCacheOrNil == nil)
        
        #if targetEnvironment(macCatalyst)
            title = ""
        #endif

        guard zoneCacheOrNil != nil, let topicCache = topicCacheOrNil else {
            return
        }
        
        // Set the selected row of tableView according to the current ZoneLocalCache.
        //
        if !splitViewController!.isCollapsed {
            selectTableRow(cloudKitDB: topicCache.cloudKitDB, zone: topicCache.zone)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // Reload the tableView so that the "+" row displays.
        //
        UIView.transition(with: tableView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }

        guard let identifier = segue.identifier, identifier == SegueID.zoneShowDetail,
            let mainNC = segue.destination as? UINavigationController,
            let mainVC = mainNC.topViewController as? MainViewController else {
                fatalError("\(#function): Failed to retrieve the main view controller!")
        }
        
        mainVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        mainVC.navigationItem.leftItemsSupplementBackButton = true

        guard let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) else {
            fatalError("\(#function): Failed to retrieve the indexPath of the selected cell!")
        }
        
        let (newCloudKitDB, newZoneOrNil) = zoneCache.zone(at: indexPath)

        // Return if the user doesn't select a different zone.
        //
        guard let topicCache = topicCacheOrNil, let newZone = newZoneOrNil,
            topicCache.zone != newZone || topicCache.cloudKitDB != newCloudKitDB else {
            return
        }
                
        // Refresh the cache even if the selected row is the current row.
        // This is to provide a way to refresh the cache of the current zone.
        //
        mainVC.spinner.startAnimating()
        
        let payload = ZoneSwitched(cloudKitDB: newCloudKitDB, zone: newZone)
        let userInfo = [UserInfoKey.zoneSwitched: payload]
        NotificationCenter.default.post(name: .zoneDidSwitch, object: self, userInfo: userInfo)
    }
}

// MARK: - Actions and handlers.
//
extension ZoneViewController {
    // This handler assumes the notification posts from the main thread.
    //
    @objc
    func zoneCacheDidChange(_ notification: Notification) {
        // tableView.numberOfSections can be 0 when iCloud isn't logged in,
        // so simply reloadData in this case.
        //
        navigationItem.rightBarButtonItem?.isEnabled = !(zoneCacheOrNil == nil)
        spinner.stopAnimating()
        tableView.reloadData()
        
        guard zoneCacheOrNil != nil, let topicCache = topicCacheOrNil else {
            return
        }
        
        if !splitViewController!.isCollapsed {
            selectTableRow(cloudKitDB: topicCache.cloudKitDB, zone: topicCache.zone)
        }
    }
    
    // The zone can switch when the user accepts a share. In that case, select the zone in the table view.
    // Do nothing if notification.object is self.
    //
    @objc
    func zoneDidSwitch(_ notification: Notification) {
        guard (notification.object as? Self) != self,
            let payload = notification.userInfo?[UserInfoKey.zoneSwitched] as? ZoneSwitched else {
            return
        }
        // Reload the table view to make sure it reflects the latest zones,
        // then select the row, if necessary.
        //
        tableView.reloadData()
        if !splitViewController!.isCollapsed {
            selectTableRow(cloudKitDB: payload.cloudKitDB, zone: payload.zone)
        }
    }
    
    // Present an alert controller and add a new record zone with the specified name.
    // This sample doesn't validate the user input, but zone names must be unique in the database.
    //
    func addZone(at section: Int) {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }

        let alert = UIAlertController(title: "New Zone.", message: "Creating a new zone.", preferredStyle: .alert)
        alert.addTextField { textField -> Void in textField.placeholder = "Zone name must be unique!" }
        
        alert.addAction(UIAlertAction(title: "New", style: .default) { _ in
            guard let zoneName = alert.textFields?.first?.text, zoneName.isEmpty == false else {
                return
            }
            
            self.spinner.startAnimating()
            
            if let cloudKitDB = zoneCache.cloudKitDB(at: section) {
                zoneCache.addZone(with: zoneName, ownerName: CKCurrentUserDefaultName, to: cloudKitDB)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // Select the row when the zone changes from outside this view controller.
    //
    func selectTableRow(cloudKitDB: CKDatabase, zone: CKRecordZone) {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }
        
        if let indexPath = zoneCache.indexPath(for: cloudKitDB, zone: zone) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
    }
}
