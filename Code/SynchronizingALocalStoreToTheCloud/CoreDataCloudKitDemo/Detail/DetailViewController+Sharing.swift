/*
See LICENSE folder for this sample’s licensing information.

Abstract:
These protocols are used by the DetailViewController to support injection during testing
*/

import Foundation
import CoreData
import CloudKit
import UIKit

protocol RenderableUserIdentity {
    var nameComponents: PersonNameComponents? { get }
    var contactIdentifiers: [String] { get }
}

protocol RenderableShareParticipant {
    var renderableUserIdentity: RenderableUserIdentity { get }
    var role: CKShare.ParticipantRole { get }
    var permission: CKShare.ParticipantPermission { get }
    var acceptanceStatus: CKShare.ParticipantAcceptanceStatus { get }
}

protocol RenderableShare {
    var renderableParticipants: [RenderableShareParticipant] { get }
}

extension CKUserIdentity: RenderableUserIdentity {}

extension CKShare.Participant: RenderableShareParticipant {
    var renderableUserIdentity: RenderableUserIdentity {
        return userIdentity
    }
}

extension CKShare: RenderableShare {
    var renderableParticipants: [RenderableShareParticipant] {
        return participants
    }
}

protocol SharingProvider {
    func isShared(object: NSManagedObject) -> Bool
    func isShared(objectID: NSManagedObjectID) -> Bool
    func participants(for object: NSManagedObject) -> [RenderableShareParticipant]
    func shares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: RenderableShare]
    func canEdit(object: NSManagedObject) -> Bool
    func canDelete(object: NSManagedObject) -> Bool
}

// MARK: Sharing Support
extension DetailViewController {
    @IBAction func shareNoteAction(_ sender: Any) {
        guard let barButtonItem = sender as? UIBarButtonItem else {
            fatalError("Not a UI Bar Button item??")
        }
        
        guard let post = self.post else {
            fatalError("Can't share without a post")
        }
        
        let container = AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer
        let cloudSharingController = UICloudSharingController {
            (controller, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) in
            container.share([post], to: nil) { objectIDs, share, container, error in
                if let actualShare = share {
                    post.managedObjectContext?.performAndWait {
                        actualShare[CKShare.SystemFieldKey.title] = post.title
                    }
                }
                completion(share, container, error)
            }
        }
        cloudSharingController.delegate = self
        
        if let popover = cloudSharingController.popoverPresentationController {
            popover.barButtonItem = barButtonItem
        }
        present(cloudSharingController, animated: true) {}
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        fatalError("Failed to save share \(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        guard let title = post?.title else {
            return ""
        }
        
        return title
    }
    
    class func string(for permission: CKShare.ParticipantPermission) -> String {
        switch permission {
        case .unknown:
            return "Unknown"
        case .none:
            return "None"
        case .readOnly:
            return "Read-Only"
        case .readWrite:
            return "Read-Write"
        @unknown default:
            fatalError("It looks like a new value was added to CKShare.Participant.Permission")
        }
    }
    
    class func string(for role: CKShare.ParticipantRole) -> String {
        switch role {
        case .owner:
            return "Owner"
        case .privateUser:
            return "Private User"
        case .publicUser:
            return "Public User"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("It looks like a new value was added to CKShare.Participant.Role")
        }
    }
    
    class func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
        switch acceptanceStatus {
        case .accepted:
            return "Accepted"
        case .removed:
            return "Removed"
        case .pending:
            return "Invited"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("It looks like a new value was added to CKShare.Participant.AcceptanceStatus")
        }
    }
}
