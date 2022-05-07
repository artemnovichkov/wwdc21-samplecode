/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of MainViewController that implements UICloudSharingControllerDelegate.
*/

import UIKit

extension MainViewController: UICloudSharingControllerDelegate {
    // Provide a meaningful title to the UICloudSharingController invitation screen
    //
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "A cool topic to share!"
    }

    // When CloudKit successfully shares a topic, it calls this method.
    // At this point, the CKShare object and the whole share hierarchy are up to date on the server side,
    // so fetch the changes and update the local cache.
    //
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        guard let topicCache = topicCacheOrNil else {
            fatalError("\(#function): topicCache shouldn't be nil!")
        }
        topicCache.fetchChanges()
    }
    
    // CloudKit removes the CKShare record and updates the root record on the server side before calling this method,
    // so fetch the changes and update the local cache.
    //
    // Stopping sharing can happen in two scenarios: an owner stops a share, or a participant removes itself from a share.
    // In the former case, no visual changes occur on the owner side (privateDB).
    // In the latter case, the share disappears from the sharedDB.
    // If the share is the only item in the current zone, CloudKit removes the zone as well.
    //
    // Fetching immediately here may not get all the changes because the server side needs a while to index.
    //
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        guard let zoneCache = zoneCacheOrNil, let topicCache = topicCacheOrNil else {
            return
        }
        
        guard let record = rootRecord, topicCache.cloudKitDB.databaseScope == .shared else {
            return topicCache.fetchChanges() // Fetch the changes to completely sync with the server.
        }
        
        topicCache.deleteCachedRecord(record)
        guard topicCache.numberOfTopics() == 0 else {
            return topicCache.fetchChanges() // Fetch the changes to completely sync with the server.
        }
        
        // Delete the cached zone in sharedDB if the zone doesn't have a topic.
        // deleteCachedZone triggers a zone switching.
        //
        if let cloudKitDB = zoneCache.cloudKitDB(with: .shared) {
            zoneCache.deleteCachedZone(topicCache.zone, cloudKitDB: cloudKitDB)
        }
    }
    
    // Failing to save a share, show an alert and refresh the cache to avoid an inconsistent status.
    //
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        let alert = UIAlertController(title: "Failed to save a share.",
                                      message: "\(error) ", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true) {
            self.spinner.stopAnimating()
        }
        
        // Fetch the root record from the server and update the rootRecord silently.
        // .fetchChanges doesn't return anything here, so fetch with the recordID.
        //
        if let topicCache = topicCacheOrNil, let rootRecordID = rootRecord?.recordID {
            topicCache.fetchRecord(with: rootRecordID)
        }
    }
}
