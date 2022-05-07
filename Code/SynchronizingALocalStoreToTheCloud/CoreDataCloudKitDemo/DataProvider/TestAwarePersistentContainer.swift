/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The TestAwarePersistentContainer provides a number of useful injection points and customizes
 the store configuration for testing.
*/

import Foundation
import CoreData
import CloudKit

// MARK: Test Support
class TestAwarePersistentContainer: NSPersistentCloudKitContainer {
    override class func defaultDirectoryURL() -> URL {
        var url = super.defaultDirectoryURL()
        if AppDelegate.sharedAppDelegate.testingEnabled {
            url.appendPathComponent("TestStores")
        }
        return url
    }
}

extension CoreDataStack {
    func prepareForTesting(_ container: NSPersistentContainer) {
        guard AppDelegate.sharedAppDelegate.testingEnabled else {
            fatalError("This method should only be used to ensure the tests always start from a known state.")
        }
        
        let url = type(of: container).defaultDirectoryURL()
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            fatalError("Failed to set up testing directory for stores: \(error)")
        }
    }
}
