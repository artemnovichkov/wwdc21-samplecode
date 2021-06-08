/*
See LICENSE folder for this sample’s licensing information.

Abstract:
These methods help verify different controls and user interface elements in the DetailViewController
*/

import XCTest
import CoreData
import CloudKit
@testable import CoreDataCloudKitDemo

extension TestDetailViewController {
    func verifyDetailViewController() {
        verifyDetailViewController(matches: detailViewController.post)
    }
    
    func verifyDetailViewController(matches post: Post?) {
        verifyButtonItems()
        verifyTextFields(post)
        verifyParticipantCells()
    }
    
    func verifyTextFields(_ post: Post?) {
        XCTAssertEqual("Unknown", detailViewController.locationTextField.placeholder)
        XCTAssertFalse(detailViewController.locationTextField.isEnabled, "Location text field should always be disabled, it can't be edited.")
        let sharingController = UICloudSharingController()
        if let realPost = post {
            realPost.managedObjectContext?.performAndWait {
                if let title = realPost.title {
                    XCTAssertEqual(title, detailViewController.titleTextField.text)
                    XCTAssertEqual(title, detailViewController.itemTitle(for: sharingController))
                } else {
                    XCTAssertEqual("", detailViewController.titleTextField.text)
                    XCTAssertEqual("", detailViewController.itemTitle(for: sharingController))
                }
                
                if let content = realPost.content {
                    XCTAssertEqual(content, detailViewController.contentTextView.text)
                } else {
                    XCTAssertEqual("", detailViewController.contentTextView.text)
                }
                
                if let location = realPost.location {
                    let expectedString = expectedLocationValue(for: location)
                    XCTAssertNotNil(expectedString, "Didn't get a valid string back from the location in \(realPost)")
                    XCTAssertEqual(expectedString!, detailViewController.locationTextField.text)
                } else {
                    XCTAssertEqual("", detailViewController.locationTextField.text)
                }
                
                if detailViewController.isEditing {
                    XCTAssertTrue(detailViewController.titleTextField.isEnabled)
                    XCTAssertTrue(detailViewController.contentTextView.isEditable)
                } else {
                    XCTAssertFalse(detailViewController.titleTextField.isEnabled)
                    XCTAssertFalse(detailViewController.contentTextView.isEditable)
                }
            }
        } else {
            XCTAssertEqual("", detailViewController.titleTextField.text)
            XCTAssertFalse(detailViewController.titleTextField.isEnabled)
            XCTAssertEqual("", detailViewController.contentTextView.text)
            XCTAssertFalse(detailViewController.contentTextView.isEditable)
            XCTAssertEqual("", detailViewController.itemTitle(for: sharingController))
        }
    }
    
    func verifyParticipantCells() {
        if let participants = detailViewController.share?.renderableParticipants,
           participants.isEmpty == false {
            XCTAssertEqual(participants.count, detailViewController.tableView(detailViewController.tableView,
                                                                                   numberOfRowsInSection: 5))
            for (index, participant) in participants.enumerated() {
                let cell = detailViewController.tableView(detailViewController.tableView,
                                                               cellForRowAt: IndexPath(row: index, section: 5))
                if let firstName = participant.renderableUserIdentity.nameComponents?.givenName,
                   let lastName = participant.renderableUserIdentity.nameComponents?.familyName {
                    XCTAssertEqual("\(firstName) \(lastName)", cell.textLabel?.text)
                } else {
                    XCTAssertEqual(participant.renderableUserIdentity.contactIdentifiers.first, cell.textLabel?.text)
                }
                
                let status = DetailViewController.string(for: participant.acceptanceStatus)
                let role = DetailViewController.string(for: participant.role)
                let permission = DetailViewController.string(for: participant.permission)
                let expectedDetailText = "\(role) - \(permission) - \(status)"
                XCTAssertEqual(expectedDetailText, cell.detailTextLabel?.text)
            }
        } else {
            XCTAssertEqual(0, detailViewController.tableView(detailViewController.tableView,
                                                                  numberOfRowsInSection: 5))
        }
    }
    
    func expectedLocationValue(for location: CLLocation) -> String? {
        var expectedString: String?
        let coder = CLGeocoder()
        let expectation = expectation(description: "Waiting for the reverse geocode to finish.")
        coder.reverseGeocodeLocation(location) { placemarks, error in
            XCTAssertNil(error)
            XCTAssertEqual(1, placemarks?.count)
            if let placemark = placemarks?.first {
                if let city = placemark.locality,
                   let state = placemark.administrativeArea {
                    expectedString = "\(city), \(state)"
                }
            } else {
                XCTFail("Expected one placemark to be returned for this location \(location)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: CoreDataCloudKitDemoUnitTestCase.defaultTimeout, handler: nil)
        return expectedString
    }
    
    func verifyButtonItems() {
        let detailVC = detailViewController
        if let buttonItems = detailVC.navigationItem.rightBarButtonItems {
            XCTAssertEqual(2, buttonItems.count)
            XCTAssertEqual([detailVC.shareButtonItem!,
                            detailVC.editButtonItem], detailViewController.navigationItem.rightBarButtonItems)
            XCTAssertNotNil(detailVC.editButtonItem)
            XCTAssertNotNil(detailVC.shareButtonItem)
            if let actualPost = detailVC.post {
                XCTAssertEqual(detailVC.sharingProvider.canEdit(object: actualPost), detailVC.editButtonItem.isEnabled)
                XCTAssertTrue(detailVC.shareButtonItem!.isEnabled)
            } else {
                XCTAssertFalse(detailVC.editButtonItem.isEnabled)
                XCTAssertFalse(detailVC.shareButtonItem!.isEnabled)
            }
        } else {
            XCTFail("Failed to find button items on \(detailVC)")
        }
    }
}
