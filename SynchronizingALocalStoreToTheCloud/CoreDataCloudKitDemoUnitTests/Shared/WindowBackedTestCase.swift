/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A test base class for testing objects that require a window like view controllers.
*/

import XCTest
import CoreData
@testable import CoreDataCloudKitDemo

class WindowBackedTestCase: CoreDataCloudKitDemoUnitTestCase {
    private var _testWindow: UIWindow?
    var testWindow: UIWindow {
        return _testWindow!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        _testWindow = UIWindow(frame: UIScreen.main.bounds)
        testWindow.makeKeyAndVisible()
    }
    
    override func tearDownWithError() throws {
        if let window = _testWindow {
            window.rootViewController = nil
        }
        try super.tearDownWithError()
    }
}
