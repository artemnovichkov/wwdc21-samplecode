/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UI performance tests.
*/

import XCTest

class UITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            app.collectionViews.firstMatch.swipeUp(velocity: .fast)
        }
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
