/*
See LICENSE folder for this sample’s licensing information.

Abstract:
These subclasses make it possible to test view controllers by injection
*/

import Foundation
import CloudKit
import CoreData
@testable import CoreDataCloudKitDemo

class InjectableUserIdentity: RenderableUserIdentity {
    var nameComponents: PersonNameComponents? = nil
    var userRecordID: CKRecord.ID
    var contactIdentifiers: [String]
    var hasiCloudAccount: Bool
    
    init(userRecordID: CKRecord.ID = CKRecord.ID(recordName: CKCurrentUserDefaultName),
         nameComponents: PersonNameComponents? = nil,
         contactIdentifiers: [String],
         hasiCloudAccount: Bool = false) {
        if nameComponents == .none {
            var components = PersonNameComponents()
            components.givenName = "Johnny"
            components.familyName = "Appleseed"
            self.nameComponents = components
        } else {
            self.nameComponents = nameComponents
        }
        self.userRecordID = userRecordID
        self.contactIdentifiers = contactIdentifiers
        self.hasiCloudAccount = hasiCloudAccount
        
    }
    
    class func defaultUserIdentity() -> InjectableUserIdentity {
        return InjectableUserIdentity(contactIdentifiers: [ "demo-test-account@fake-icloud.com" ],
                                      hasiCloudAccount: true)
    }
}

class InjectableShareParticipant: RenderableShareParticipant {
    var renderableUserIdentity: RenderableUserIdentity {
        return userIdentity
    }
    
    var userIdentity: RenderableUserIdentity
    var role: CKShare.ParticipantRole
    var permission: CKShare.ParticipantPermission
    var acceptanceStatus: CKShare.ParticipantAcceptanceStatus
    
    init(userIdentity: RenderableUserIdentity = InjectableUserIdentity.defaultUserIdentity(),
         role: CKShare.ParticipantRole = .owner,
         permission: CKShare.ParticipantPermission = .readWrite,
         acceptanceStatus: CKShare.ParticipantAcceptanceStatus = .accepted) {
        self.userIdentity = userIdentity
        self.role = role
        self.permission = permission
        self.acceptanceStatus = acceptanceStatus
    }
}

class InjectableShare: RenderableShare {
    var renderableParticipants: [RenderableShareParticipant]
    init(participants: [RenderableShareParticipant]) {
        renderableParticipants = participants
    }
}

class BlockBasedShareProvider: SharingProvider {
    var coreDataStack: CoreDataStack
    init(stack: CoreDataStack) {
        coreDataStack = stack
    }
    
    func isShared(object: NSManagedObject) -> Bool {
        return isShared(objectID: object.objectID)
    }
    
    public var isSharedBlock: ((_ object: NSManagedObjectID) -> Bool)? = nil
    func isShared(objectID: NSManagedObjectID) -> Bool {
        guard let block = isSharedBlock else {
            return coreDataStack.isShared(objectID: objectID)
        }
        return block(objectID)
    }
    
    public var participantsBlock: ((_ object: NSManagedObject) -> [RenderableShareParticipant])? = nil
    func participants(for object: NSManagedObject) -> [RenderableShareParticipant] {
        guard let block = participantsBlock else {
            return coreDataStack.participants(for: object)
        }
        return block(object)
    }
    
    public var sharesBlock: ((_ objectIDs: [NSManagedObjectID]) -> [NSManagedObjectID: RenderableShare])? = nil
    func shares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: RenderableShare] {
        guard let block = sharesBlock else {
            return try coreDataStack.shares(matching: objectIDs)
        }
        return block(objectIDs)
    }
    
    public var canEditBlock: ((_ object: NSManagedObject) -> Bool)? = nil
    func canEdit(object: NSManagedObject) -> Bool {
        guard let block = canEditBlock else {
            return coreDataStack.canEdit(object: object)
        }
        return block(object)
    }
    
    public var canDeleteBlock: ((_ object: NSManagedObject) -> Bool)? = nil
    func canDelete(object: NSManagedObject) -> Bool {
        guard let block = canDeleteBlock else {
            return coreDataStack.canDelete(object: object)
        }
        return block(object)
    }
}
