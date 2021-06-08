/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of MainViewController that manages the tableView data source and delegate.
*/

import UIKit
import CloudKit

// MARK: - UITableViewDataSource and UITableViewDelegate
//
extension MainViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let topicCache = topicCacheOrNil else {
            return 0
        }
        
        let isPrivateDB = topicCache.cloudKitDB.databaseScope == .private
        let topicCount = topicCache.numberOfTopics()
        return isEditing && isPrivateDB ? topicCount + 1 : topicCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let topicCache = topicCacheOrNil else {
            return 0
        }

        // These two accessors return nil when section == topics.count,
        // which can happen when editing (there is an extra section for adding a new topic.)
        // In that case, there is no note for the "new" section.
        //
        guard let noteCount = topicCache.numberOfNotes(at: section),
            let topicPermission = topicCache.permissionOfTopic(at: section) else {
            return 0
        }
        
        if topicPermission != .readWrite {
            return noteCount
        }
        
        return isEditing ? noteCount + 1 : noteCount
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let views = Bundle.main.loadNibNamed("TopicSectionTitleView", owner: self, options: nil)
        
        guard let sectionTitleView = views?.first as? TopicSectionTitleView else {
            return nil
        }
        guard let topicCache = topicCacheOrNil else {
            return sectionTitleView
        }
        
        // Set up the editing style for the section title view. Default to .inserting.
        // Note that participants are unable to remove a topic because it's a root record.
        //
        var editingStyle: TopicSectionTitleView.EditingStyle = .inserting
        if let topicPermission = topicCache.permissionOfTopic(at: section) {
            if topicCache.cloudKitDB.databaseScope == .shared {
                editingStyle = .none
            } else {
                editingStyle = isEditing && topicPermission == .readWrite ? .deleting : .none
            }
        }
        
        var title = "Add a topic"
        if let tuple = topicCache.topicNameAndID(at: section) {
            title = tuple.0
        }
                
        sectionTitleView.setEditingStyle(editingStyle, title: title)
        
        // In the shareDB, a participant is valid to "share" a shared record as well,
        // meaning they can show UICloudShareController for the following purpose:
        // - See the list of invited people.
        // - Send a copy of the share link to others (only if the share is public).
        // - Leave the share.
        // So there’s no need to hide the Share button in this case.
        //
        sectionTitleView.section = section
        return sectionTitleView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let topicCache = topicCacheOrNil else {
            fatalError("\(#function): topicCache shouldn't be nil!")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: TableCellReusableID.subTitle, for: indexPath)
                
        let noteTitle = topicCache.noteTitle(at: indexPath)
        cell.textLabel!.text = noteTitle ?? "Add a note"
        cell.detailTextLabel?.text = nil
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let topicCache = topicCacheOrNil else {
            fatalError("\(#function): topicCache shouldn't be nil")
        }

        // noteRecordAndPermission returns nil for the last row because it's for "+" and doesn't have a note.
        //
        guard let (noteRecord, permission) = topicCache.noteRecordAndPermission(at: indexPath) else {
            return .insert
        }

        // In the private database, permissions default to .readWrite for the record creator.
        // The shared database is different because of the following:
        // - A participant can always remove the participation by presenting a UICloudSharingController.
        // - A participant can change the record content if they have .readWrite permission.
        // - A participant can add a record to a parent if they have .readWrite permission.
        // - A participant can remove a record that they add from a parent.
        // - A participant can't remove a root record if they aren’t the creator.
        // - Users can't "add" a note if they can't write the topic. (See MainViewController.numberOfRowsInSection.)
        //
        if topicCache.cloudKitDB.databaseScope == .shared {
            let isCurrentUser = noteRecord.creatorUserRecordID?.recordName == CKCurrentUserDefaultName
            return isCurrentUser && (permission == .readWrite) ? .delete : .none
        }
        return permission == .readWrite ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let topicCache = topicCacheOrNil else {
            return
        }

        if editingStyle == .insert {
            if let (topicName, topicRecordID) = topicCache.topicNameAndID(at: indexPath.section) {
                // Use "sender" to convey the current topic name and record ID.
                performSegue(withIdentifier: SegueID.mainAddNew, sender: (topicName, topicRecordID))
            }
        } else if editingStyle == .delete {
            spinner.startAnimating()
            topicCache.deleteNote(at: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
