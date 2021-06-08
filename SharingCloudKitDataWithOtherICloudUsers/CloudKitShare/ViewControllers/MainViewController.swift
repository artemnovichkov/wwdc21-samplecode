/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller class that manages topics and notes.
*/

import UIKit
import CloudKit

final class MainViewController: SpinnerViewController {
    var zoneCacheOrNil: ZoneLocalCache? {
        return (UIApplication.shared.delegate as? AppDelegate)?.zoneCacheOrNil
    }
    var topicCacheOrNil: TopicLocalCache? {
        return (UIApplication.shared.delegate as? AppDelegate)?.topicCacheOrNil
    }

    // Clients need to set rootRecord before presenting UICloudSharingController
    // so that its delegate methods can access the information in the root record.
    //
    var rootRecord: CKRecord?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        
        #if targetEnvironment(macCatalyst)
            title = ""
        #endif
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.topicCacheDidChange(_:)),
            name: .topicCacheDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.isEnabled = !(topicCacheOrNil == nil)

        guard let topicCache = topicCacheOrNil else {
            return
        }
        title = topicCache.cloudKitDB.name + "." + topicCache.zone.zoneID.zoneName

        #if targetEnvironment(macCatalyst)
            title = ""
        #endif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let topicCache = topicCacheOrNil else {
            fatalError("\(#function): topicCache shouldn't be nil!")
        }
        guard let identifier = segue.identifier, identifier == SegueID.mainAddNew else {
            return
        }

        guard let noteNC = segue.destination as? UINavigationController,
            let noteViewController = noteNC.topViewController as? NoteViewController else {
            return
        }
        
        // "sender" conveys the name and ID of the current topic where the user adds the note.
        //
        guard let (topicName, topicRecordID) = sender as? (String, CKRecord.ID) else {
            return
        }
        
        // Create a new and unsaved note record for NoteViewController.
        //
        let noteRecord = CKRecord(recordType: Schema.RecordType.note, recordID: CKRecord.ID(zoneID: topicCache.zone.zoneID))
        noteViewController.newNoteRecord = noteRecord
        
        noteViewController.topicRecordID = topicRecordID
        noteViewController.topicName = topicName
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        // Reload the tableView so that the "+" row displays.
        //
        UIView.transition(with: tableView, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        })
    }
}

// MARK: - Actions and handlers
//
extension MainViewController {
    // This handler assumes the notification posts from the main thread.
    //
    @objc
    func topicCacheDidChange(_ notification: Notification) {
        if let topicCache = topicCacheOrNil {
            title = topicCache.cloudKitDB.name + "." + topicCache.zone.zoneID.zoneName
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            title = ""
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
        
        #if targetEnvironment(macCatalyst)
            title = ""
        #endif

        tableView.reloadData()
        spinner.stopAnimating()
    }
    
    // The Edit button action.
    //
    @IBAction func editTopic(_ sender: AnyObject) {
        guard let topicCache = topicCacheOrNil else {
            return
        }

        guard let sectionTitleView = (sender as? UIView)?.superview as? TopicSectionTitleView,
            sectionTitleView.editingStyle != .none else {
            return
        }

        let alert: UIAlertController
        if sectionTitleView.editingStyle == .inserting {
            alert = UIAlertController(title: "New Topic.", message: "Creating a topic.",
                                      preferredStyle: .alert)
            alert.addTextField { textField -> Void in
                textField.placeholder = "Name. Use 'Unnamed' if no input."
            }
            alert.addAction(UIAlertAction(title: "New", style: .default) { _ in
                
                guard let name = alert.textFields?.first?.text else {
                    return
                }
                let finalName = name.isEmpty ? "Unnamed" : name
                
                self.spinner.startAnimating()
                topicCache.addTopic(with: finalName)
            })
            
        } else { // The sectionTitleView.editingStyle is .deleting.
            alert = UIAlertController(title: "Deleting Topic.",
                                      message: "Would you delete the topic and all its notes?",
                                      preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .default) { _ in
                self.spinner.startAnimating()
                topicCache.deleteTopic(at: sectionTitleView.section)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
        
    // The action handler of the Share button.
    //
    @IBAction func shareTopic(_ sender: AnyObject) {
        guard let sectionTitleView = (sender as? UIView)?.superview as? TopicSectionTitleView,
            let topicCache = topicCacheOrNil,
            let topicRecord = topicCache.topicRecord(at: sectionTitleView.section) else {
                return
        }

        let completionHandler: (UICloudSharingController?) -> Void = { controller in
            if let sharingController = controller {
                // Set the root record and present the UICloudSharingController.
                // Specify the pop-over source view. Presenting the Cloud sharing controller in an iPadOS app
                // without setting the pop-over presentation controller causes a runtime error.
                //
                sharingController.popoverPresentationController?.sourceView = sender as? UIView
                self.rootRecord = topicRecord
                sharingController.delegate = self
                sharingController.availablePermissions = [.allowPublic, .allowReadOnly, .allowReadWrite]
                self.present(sharingController, animated: true) { self.spinner.stopAnimating() }
                
            } else { // Alert the user that the sharing process failed.
                let title = "Failed to share."
                let message = "Can't set up a valid share object."
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true) { self.spinner.stopAnimating() }
            }
        }
                
        spinner.startAnimating() // Start spinning.
        
        // prepareSharingController is asynchronous so it doesn’t block the main queue.
        //
        topicCache.container.prepareSharingController(rootRecord: topicRecord, database: topicCache.cloudKitDB,
                                                      zone: topicCache.zone) { controller in
            completionHandler(controller)
        }
    }
}
