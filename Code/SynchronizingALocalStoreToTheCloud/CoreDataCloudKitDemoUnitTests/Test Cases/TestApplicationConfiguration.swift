/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A unit test that verifies the sample application launches correctly for testing.
*/

import XCTest
import CoreLocation
@testable import CoreDataCloudKitDemo

class TestApplicationConfiguration: WindowBackedTestCase {
    func testCoreDataStackObeysLaunchArguments() {
        let appDelegate = AppDelegate.sharedAppDelegate
        XCTAssertTrue(appDelegate.testingEnabled, "Should have launched with testing enabled so the test cases don't use the customer store.")
        XCTAssertFalse(appDelegate.allowCloudKitSync, "Should have launched with CloudKit disabled so cloud sync doesn't impact the test dataset.")
        let container = appDelegate.coreDataStack.persistentContainer
        for storeDescription in container.persistentStoreDescriptions {
            XCTAssertNil(storeDescription.cloudKitContainerOptions, "Shouldn't be using CloudKit during unit / UI tests.")
        }
    }
    
    func testInfoPlistLocationMessage() throws {
        for key in [ "NSLocationUsageDescription", //for macOS
                     "NSLocationWhenInUseUsageDescription" ] {
            if let message = Bundle(for: AppDelegate.self).infoDictionary?[key] as? String {
                XCTAssertEqual("Location data is associated with each Post when it is created for later reference.", message)
            } else {
                XCTFail("The app bundle appears to missing info plist entry for \(key)")
            }
        }
    }
}
