/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A test case that covers the main view controller.
*/

import XCTest
import CoreData
@testable import CoreDataCloudKitDemo

class TestMainViewController: WindowBackedTestCase {
    private var _mainViewController: MainViewController?
    var mainViewController: MainViewController {
        return _mainViewController!
    }
    
    private var _splitviewController: UISplitViewController?
    var splitviewController: UISplitViewController {
        return _splitviewController!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        XCTAssertNotNil(storyboard)
        _splitviewController = storyboard.instantiateInitialViewController()
        XCTAssertNotNil(_splitviewController)
        XCTAssertEqual(2, splitviewController.viewControllers.count)
        guard let navigationController = splitviewController.viewControllers[0] as? UINavigationController else {
            XCTFail("Unexpected view controller in the stack \(splitviewController.viewControllers)")
            return
        }
        _mainViewController = navigationController.topViewController as? MainViewController
        XCTAssertNotNil(_mainViewController)
        testWindow.rootViewController = splitviewController
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
    
    func testBasicLoad() {
        XCTAssertEqual("PostsTableView", mainViewController.tableView.accessibilityIdentifier)
        XCTAssertEqual(1, mainViewController.tableView.numberOfSections)
        XCTAssertEqual(0, mainViewController.tableView.numberOfRows(inSection: 0))
    }
    
    func testPostCell() {
        let context = coreDataStack.persistentContainer.viewContext
        let postExpectation = expectation(description: "Waiting for the post to be added.")
        var capturedPost: Post?
        mainViewController.dataProvider.addPost(in: context, shouldSave: false) { addedPost in
            capturedPost = addedPost
            postExpectation.fulfill()
        }
        waitForExpectations(timeout: CoreDataCloudKitDemoUnitTestCase.defaultTimeout, handler: nil)
        guard let post = capturedPost else {
            XCTFail("Failed to capture a post from the data provider.")
            return
        }
        XCTAssertEqual(1, mainViewController.tableView.numberOfRows(inSection: 0))
        XCTAssertTrue(post.title!.hasPrefix("Untitled "))
        
        guard let postCell = mainViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCell else {
            XCTFail("Should have had a cell for the inserted post.")
            return
        }
        XCTAssertEqual("PostCell", postCell.accessibilityIdentifier)
        XCTAssertEqual(post.title, postCell.title.text)
        XCTAssertEqual(post, postCell.post)
        XCTAssertTrue(postCell.hasAttachmentLabel.isHidden)
        post.title = "A Title"
        reloadTableView()
        XCTAssertEqual("A Title", postCell.title.text)
        XCTAssertTrue(postCell.hasAttachmentLabel.isHidden)
        
        let attachment = Attachment(context: context)
        attachment.post = post
        reloadTableView()
        XCTAssertEqual("❖", postCell.hasAttachmentLabel.text)
        XCTAssertFalse(postCell.hasAttachmentLabel.isHidden)
        
        post.attachments = nil
        reloadTableView()
        XCTAssertTrue(postCell.hasAttachmentLabel.isHidden)
    }

    func testLocationAuthorizationCheck() {
        let originalManager = AppDelegate.sharedAppDelegate.locationManager
        let injectableManager = InjectableCLLocationManager()
        AppDelegate.sharedAppDelegate.locationManager = injectableManager
        injectableManager.authorizationStatusOverride = .authorizedWhenInUse
        injectableManager.requestWhenInUseAuthorizationBlock = {
            XCTFail("Shouldn't be called if already authorized.")
        }
        
        let context = coreDataStack.persistentContainer.viewContext
        expectation(forNotification: NSNotification.Name.NSManagedObjectContextDidSave,
                    object: context,
                    handler: nil)
        mainViewController.add(mainViewController.composeItem)
        AppDelegate.sharedAppDelegate.locationManager = originalManager
        
        waitForExpectations(timeout: CoreDataCloudKitDemoUnitTestCase.defaultTimeout,
                            handler: nil)
        context.performAndWait {
            do {
                guard let post = try context.fetch(Post.fetchRequest()).last else {
                    XCTFail("Should have found one post from the call to add")
                    return
                }
                
                XCTAssertNotNil(post.location)
            } catch let error {
                XCTFail("Failed to fetch added post after checking location authorization \(error)")
            }
        }
    }
    
    func testSharedPostsGetDisclosure() {
        var sharedObjectIDs: Set<NSManagedObjectID> = Set()
        let context = coreDataStack.persistentContainer.viewContext
        self.generatePosts(in: context, postSaveBlock: { posts in
            for (index, post) in posts.enumerated() where (index % 4) == 0 {
                sharedObjectIDs.insert(post.objectID)
            }
        })
        
        let provider = BlockBasedShareProvider(stack: coreDataStack)
        provider.isSharedBlock = sharedObjectIDs.contains
        mainViewController.sharingProvider = provider
        
        do {
            try mainViewController.dataProvider.fetchedResultsController.performFetch()
        } catch let error {
            XCTFail("Error while fetching \(error)")
        }
        
        reloadTableView()
        let rowCount = mainViewController.tableView(mainViewController.tableView,
                                                        numberOfRowsInSection: 0)
        XCTAssertEqual(100, rowCount)
        guard let expectedSharedImage = UIImage(systemName: "person.circle") else {
            XCTFail("Failed to get the person system image.")
            return
        }
        
        for index in 0..<rowCount {
            let indexPath = IndexPath(row: index, section: 0)
            let post = mainViewController.dataProvider.fetchedResultsController.object(at: indexPath)
            guard let title = post.title else {
                XCTFail("All posts should have been given a title.")
                return
            }
            
            guard let cell = mainViewController.tableView(mainViewController.tableView,
                                                               cellForRowAt: indexPath) as? PostCell else {
                XCTFail("Encountered an unexpected cell type in the main view controller's table view.")
                return
            }
            
            if sharedObjectIDs.contains(post.objectID) {
                guard let attributedText = cell.title.attributedText else {
                    XCTFail("Failed to get the attributed text of \(cell). Was it not set?")
                    return
                }
                
                guard let attachment = attributedText.attributes(at: 0, effectiveRange: nil)[.attachment] as? NSTextAttachment else {
                    XCTFail("Expected an image attachment at the first character.")
                    return
                }
                
                XCTAssertEqual(expectedSharedImage, attachment.image)
            } else {
                XCTAssertEqual(cell.title.text, title)
            }
        }
    }
    
    func testTableViewObeysMutability() {
        var sharedObjectIDs: Set<NSManagedObjectID> = Set()
        var deletableObjectIDs: Set<NSManagedObjectID> = Set()
        let context = coreDataStack.persistentContainer.viewContext
        self.generatePosts(in: context, postSaveBlock: { posts in
            for (index, post) in posts.enumerated() where (index % 4) == 0 {
                if (index % 4) == 0 {
                    sharedObjectIDs.insert(post.objectID)
                    if (index % 8) == 0 {
                        deletableObjectIDs.insert(post.objectID)
                    }
                } else {
                    deletableObjectIDs.insert(post.objectID)
                }
            }
        })
        
        let provider = BlockBasedShareProvider(stack: coreDataStack)
        provider.isSharedBlock = sharedObjectIDs.contains
        provider.canDeleteBlock = { object in
            return deletableObjectIDs.contains(object.objectID)
        }
        mainViewController.sharingProvider = provider
        
        do {
            try mainViewController.dataProvider.fetchedResultsController.performFetch()
        } catch let error {
            XCTFail("Error while fetching \(error)")
        }
        
        reloadTableView()
        XCTAssertEqual(100, mainViewController.tableView(mainViewController.tableView,
                                                              numberOfRowsInSection: 0))
        mainViewController.tableView.setEditing(true, animated: false)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
        
        guard let tableView = mainViewController.tableView else {
            XCTFail("Main view controller doesn't have a table view? \(mainViewController)")
            return
        }
        
        for index in 0..<100 {
            let indexPath = IndexPath(row: index, section: 0)
            let post = mainViewController.dataProvider.fetchedResultsController.object(at: indexPath)
            if sharedObjectIDs.contains(post.objectID) {
                if deletableObjectIDs.contains(post.objectID) {
                    XCTAssertTrue(mainViewController.tableView(tableView, canEditRowAt: indexPath))
                } else {
                    XCTAssertFalse(mainViewController.tableView(tableView, canEditRowAt: indexPath))
                }
            } else {
                XCTAssertTrue(deletableObjectIDs.contains(post.objectID))
                XCTAssertTrue(mainViewController.tableView(tableView, canEditRowAt: indexPath))
            }
        }
    }
    
    // MARK: Utilities
    func reloadTableView() {
        mainViewController.tableView.reloadData()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
    
    func generatePosts(in context: NSManagedObjectContext, postSaveBlock: ([NSManagedObject]) -> Void) {
        context.performAndWait {
            do {
                var posts = [Post]()
                for index in 0..<100 {
                    guard let post = NSEntityDescription.insertNewObject(forEntityName: "Post", into: context) as? Post else {
                        fatalError("Did something happen to the Post entity?")
                    }
                    
                    post.title = "Sample post \(index)"
                    post.content = "Some sample content for post \(index)"
                    posts.append(post)
                }
                
                try context.save()
                postSaveBlock(posts)
            } catch let error {
                XCTFail("Something went wrong adding posts \(error)")
            }
        }
    }
}

class BlockFetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    var controllerDidChangeContentBlock: ((_ controller: NSFetchedResultsController<NSFetchRequestResult>) -> Void)?
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let block = controllerDidChangeContentBlock {
            block(controller)
        }
    }
}
