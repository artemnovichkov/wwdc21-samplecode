/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller class for viewing and editing a note.
*/

import UIKit
import CloudKit

// MARK: - View controller life cycle
//
final class NoteViewController: SpinnerViewController {
    var topicCacheOrNil: TopicLocalCache? {
        return (UIApplication.shared.delegate as? AppDelegate)?.topicCacheOrNil
    }
    var topicName: String?
    var topicRecordID: CKRecord.ID!
    var newNoteRecord: CKRecord!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.topicCacheDidChange(_:)),
            name: .topicCacheDidChange, object: nil)
    }
}

// MARK: - Actions and handlers
//
extension NoteViewController {
    @IBAction func save(_ sender: UIBarButtonItem) {
        guard let topicCache = topicCacheOrNil else {
            return
        }
        
        let indexPath = IndexPath(row: 1, section: 0)
        guard let titleCell = tableView.cellForRow(at: indexPath) as? TextFieldCell else {
            return
        }
        
        guard let input = titleCell.textField.text, input.isEmpty == false else {
            let alert = UIAlertController(title: "The title field is empty.",
                                          message: "Please input a title and try again.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Start spinning on the topic view and the note view.
        //
        spinner.startAnimating()
        if let scene = UIApplication.shared.connectedScenes.first,
            let sceneDeleate = scene.delegate as? SceneDelegate {
            sceneDeleate.animateTopicSpinner(start: true)
        }

        newNoteRecord[Schema.Note.title] = input as CKRecordValue
        topicCache.addNote(newNoteRecord, topicRecordID: topicRecordID)
        dismiss(animated: true) { self.spinner.stopAnimating() }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}

// MARK: - Local cache change notification
//
extension NoteViewController {
    @objc
    func topicCacheDidChange(_ notification: Notification) { // The notification posts in the main queue.
        // Alert (and return to the main screen) when the topic doesn't exist. This can happen when:
        // - Other peers remove the topic.
        // - The zone doesn't exist anymore, so the app switches to a new zone.
        // - The sample nullifies topicCache because the account becomes unavailable.
        //
        guard let topicCache = topicCacheOrNil else {
            self.alertTopicNotExist()
            return
        }
        
        guard let topicRecord = topicCache.topicRecord(with: topicRecordID) else {
            self.alertTopicNotExist()
            return
        }
        
        // The topic is there, so handle the notification payload, if any.
        //
        guard let payload = notification.userInfo?[UserInfoKey.topicCacheChanges] as? TopicCacheChanges else {
            return
        }
        
        // If the note's topic has changes, refresh the UI.
        // This sample doesn't really change a topic name, but you can do that using CloudKit Dashboard.
        //
        if payload.recordsChanged.contains(where: { $0.recordID == topicRecord.recordID }) {
            let topicCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
            topicCell?.detailTextLabel?.text = topicRecord[Schema.Topic.name] as? String
        }
    }
    
    private func alertTopicNotExist() {
        let alert = UIAlertController(title: "This note's topic doesn't exist now.",
                                      message: "Tap OK to go back to the main screen.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.spinner.startAnimating()
            self.dismiss(animated: true) { self.spinner.stopAnimating() }
        })
        present(alert, animated: true)
    }
}
