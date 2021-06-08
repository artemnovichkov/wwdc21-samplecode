/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A test base class that provides access to the CoreDataStack.
*/

import XCTest
import CoreData
import CoreLocation
@testable import CoreDataCloudKitDemo

class CoreDataCloudKitDemoUnitTestCase: XCTestCase {
    static let defaultTimeout = 10.0
    private var _coreDataStack: CoreDataStack?
    var coreDataStack: CoreDataStack {
        return _coreDataStack!
    }
    
    private var _locationManager: CLLocationManager?
    var locationManager: CLLocationManager {
        return _locationManager!
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        let appDelegate = AppDelegate.sharedAppDelegate
        _coreDataStack = appDelegate.coreDataStack
        XCTAssertNotNil(coreDataStack.persistentContainer)
        XCTAssertEqual(2, coreDataStack.persistentContainer.persistentStoreCoordinator.persistentStores.count)
        _coreDataStack?.persistentContainer.viewContext.transactionAuthor = "\(type(of: self)).\(NSStringFromSelector(self.invocation!.selector))"
        
        verifyLocationStatus()
        _locationManager = appDelegate.locationManager
    }
    
    override func tearDownWithError() throws {
        let context = coreDataStack.persistentContainer.viewContext
        let model = coreDataStack.persistentContainer.managedObjectModel
        context.performAndWait {
            for entityName in model.entitiesByName.keys {
                do {
                    let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: entityName))
                    request.resultType = .resultTypeStatusOnly
                    guard let deleteResult = try context.execute(request) as? NSBatchDeleteResult else {
                        XCTFail("Unexpected result from batch delete for \(entityName)")
                        return
                    }
                    
                    guard let status = deleteResult.result as? NSNumber else {
                        XCTFail("Expected an \(NSNumber.self) from batch delete for \(entityName)")
                        return
                    }
                    XCTAssertTrue(status.boolValue)
                } catch let error {
                    XCTFail("Failed to batch delete data from test run for entity \(entityName): \(error)")
                }
            }
            context.reset()
        }
        
        try super.tearDownWithError()
    }
    
    func verifyLocationStatus() {
        let appDelegate = AppDelegate.sharedAppDelegate
        let locationManager = appDelegate.locationManager
        let status = appDelegate.locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            let delegate = CLLocationManagerBlockDelegate()
            let expectation = expectation(description: "Waiting for authorization. Failure likely means the dialog was not tapped in time.")
            delegate.didChangeAuthorizationBlock = { manager in
                XCTAssertEqual(manager, locationManager)
#if targetEnvironment(macCatalyst)
                if .authorizedAlways != manager.authorizationStatus {
                    XCTFail("The wrong authorization state was returned. It should have been authorized on catalyst.")
                }
#else
                if .authorizedWhenInUse != manager.authorizationStatus {
                    XCTFail("The wrong authorization state was returned. It should have been when-in-use")
                }
#endif //#if targetEnvironment(macCatalyst)
                expectation.fulfill()
            }
            locationManager.delegate = delegate
            locationManager.requestWhenInUseAuthorization()
            waitForExpectations(timeout: CoreDataCloudKitDemoUnitTestCase.defaultTimeout, handler: nil)
            withExtendedLifetime(delegate) {}
        case .restricted, .denied:
            XCTFail("Tests require location access to proceed. Please reset the location settings for this app and allow When-In-Use authorization.")
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            break
        default:
            XCTFail("Unknown location authorization state.")
        }
        
#if targetEnvironment(macCatalyst)
        XCTAssertEqual(.authorizedAlways, locationManager.authorizationStatus, "Some tests will require access to location information.")
#else
        XCTAssertEqual(.authorizedWhenInUse, locationManager.authorizationStatus, "Some tests will require access to location information.")
#endif //#if targetEnvironment(macCatalyst)
        XCTAssertTrue(appDelegate.locationAuthorized)
        XCTAssertNotNil(locationManager.location, "Some tests require that the testing bundle and scheme are configured to vend a valid location.")
    }
}
