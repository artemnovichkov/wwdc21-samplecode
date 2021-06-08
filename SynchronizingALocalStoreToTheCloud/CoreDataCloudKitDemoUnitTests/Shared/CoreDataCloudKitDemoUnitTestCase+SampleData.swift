/*
See LICENSE folder for this sample’s licensing information.

Abstract:
These methods create different types of sample data for the tests to use.
*/

import XCTest
import CloudKit
import CoreData
@testable import CoreDataCloudKitDemo

extension CoreDataCloudKitDemoUnitTestCase {
    func injectSamplePost(in context: NSManagedObjectContext,
                          populate: Bool = true,
                          includeLocation: Bool = true) -> Post {
        let post = Post(context: context)
        do {
            if populate {
                self.populate(post: post, includeLocation: includeLocation)
            }
            try context.save()
        } catch let error {
            XCTFail("Save failed: \(error)")
        }
        return post
    }
    
    func populate(post: Post, includeLocation: Bool = true) {
            post.title = "Sample Title"
            post.content = "Sample body content"
            if includeLocation {
                post.location = locationManager.location
            }
    }
    
    func createTestParticipants() -> [InjectableShareParticipant] {
        var participants = [InjectableShareParticipant]()
        for participantNumber in 0...10 {
            var nameComponents = PersonNameComponents()
            nameComponents.givenName = "FirstName\(participantNumber)"
            nameComponents.familyName = "LastName\(participantNumber)"
            let identity = InjectableUserIdentity(userRecordID: CKRecord.ID(recordName: "User\(participantNumber)"),
                                                  nameComponents: nameComponents,
                                                  contactIdentifiers: ["person-\(participantNumber)@fake-icloud.com"],
                                                  hasiCloudAccount: true)
            var role: CKShare.ParticipantRole = .unknown
            var permission: CKShare.ParticipantPermission = .unknown
            var acceptanceStatus: CKShare.ParticipantAcceptanceStatus = .unknown
            switch participantNumber % 4 {
            case 1:
                role = .owner
                permission = .none
                acceptanceStatus = .pending
            case 2:
                role = .privateUser
                permission = .readOnly
                acceptanceStatus = .accepted
            case 3:
                role = .publicUser
                permission = .readWrite
                acceptanceStatus = .removed
            default:
                break
            }
            
            participants.append(InjectableShareParticipant(userIdentity: identity,
                                                           role: role,
                                                           permission: permission,
                                                           acceptanceStatus: acceptanceStatus))
        }
        return participants
    }
}
