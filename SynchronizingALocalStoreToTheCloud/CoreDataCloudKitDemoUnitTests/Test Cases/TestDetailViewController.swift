/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This test case covers the DetailViewController
*/

import XCTest
import CoreData
import CloudKit
import MapKit
@testable import CoreDataCloudKitDemo

class TestDetailViewController: WindowBackedTestCase {
    private var _detailViewController: DetailViewController?
    var detailViewController: DetailViewController {
        return _detailViewController!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        XCTAssertNotNil(storyboard)
        _detailViewController = storyboard.instantiateViewController(identifier: "DetailViewController")
        XCTAssertNotNil(_detailViewController)
        
        testWindow.rootViewController = detailViewController
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
    }
    
    override func tearDownWithError() throws {
        testWindow.rootViewController = nil
        try super.tearDownWithError()
    }
    
    func testLoadAndRefreshWithDifferentPostValues() throws {
        let context = coreDataStack.persistentContainer.viewContext
        context.performAndWait {
            detailViewController.post = injectSamplePost(in: context, populate: false)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        context.performAndWait {
            do {
                if let post = try context.fetch(NSFetchRequest<Post>(entityName: "Post")).first {
                    populate(post: post)
                    try context.save()
                    detailViewController.post = post
                } else {
                    XCTFail("Didn't find the post inserted by the last operation.")
                }
            } catch let error {
                XCTFail("Failed to fetch or update post \(error)")
            }
        }
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        context.performAndWait {
            do {
                if let post = try context.fetch(NSFetchRequest<Post>(entityName: "Post")).first {
                    post.title = "Unsaved title"
                    post.content = "Unsaved content"
                    detailViewController.post = post
                } else {
                    XCTFail("Didn't find the post inserted by the last operation.")
                }
            } catch let error {
                XCTFail("Failed to fetch or update post \(error)")
            }
        }
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
    }
    
    func testLoadAndRefreshWithParticipants() {
        var capturedPostID: NSManagedObjectID?
        let context = coreDataStack.persistentContainer.viewContext
        context.performAndWait {
            let post = injectSamplePost(in: context)
            detailViewController.post = post
            capturedPostID = post.objectID
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        guard let postID = capturedPostID else {
            XCTFail("Didn't get an objectID for the inserted post.")
            return
        }
        
        let provider = BlockBasedShareProvider(stack: coreDataStack)
        let participants = createTestParticipants()
        provider.sharesBlock = { (objectIDs) in
            XCTAssertEqual([postID], objectIDs, "Unknown objectID sent to our provider override.")
            let share = InjectableShare(participants: participants)
            return [postID: share]
        }
        detailViewController.sharingProvider = provider
        
        detailViewController.refreshUI()
        XCTAssertNotNil(detailViewController.share, "Share should have been fetched when the UI was updated.")
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        detailViewController.sharingProvider = coreDataStack
        detailViewController.refreshUI()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        XCTAssertNil(detailViewController.share, "Share should have been wiped out when the post was updated.")
    }
    
    func testEditingTransition() {
        let context = coreDataStack.persistentContainer.viewContext
        context.performAndWait {
            detailViewController.post = injectSamplePost(in: context)
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        detailViewController.setEditing(true, animated: false)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        detailViewController.titleTextField.text = "Title updated while editing."
        detailViewController.contentTextView.text += " Content updated while editing."
        detailViewController.setEditing(false, animated: false)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        context.performAndWait {
            do {
                guard let post = try context.fetch(Post.fetchRequest()).first else {
                    XCTFail("Should have been able to fetch at least one post at this point")
                    return
                }
                
                XCTAssertEqual("Title updated while editing.", post.title)
                guard let content = post.content else {
                    XCTFail("Fetched post should have had some content")
                    return
                }
                XCTAssertTrue(content.hasSuffix("Content updated while editing."))
            } catch let error {
                XCTFail("A managed object context operation failed: \(error)")
            }
        }
    }
    
    func testEditingObeysMutability() {
        let context = coreDataStack.persistentContainer.viewContext
        var capturedPostID: NSManagedObjectID? = nil
        context.performAndWait {
            let post = injectSamplePost(in: context)
            detailViewController.post = post
            capturedPostID = post.objectID
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
        
        let provider = BlockBasedShareProvider(stack: coreDataStack)
        provider.canEditBlock = { (object) in
            if object.objectID == capturedPostID {
                return false
            }
            return true
        }
        detailViewController.sharingProvider = provider
        detailViewController.refreshUI()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        verifyDetailViewController()
    }
}
