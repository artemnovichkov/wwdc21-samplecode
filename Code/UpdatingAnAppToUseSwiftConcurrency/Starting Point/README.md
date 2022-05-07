# Updating an App to Use Swift Concurrency

Transform an existing application that uses completion-handlers and dispatch queues
to use Swift's new async/await feature instead of callbacks, and actors instead
of dispatch queues. 

## Overview

The Coffee Tracker app records a user's caffeine intake. 
Each time the user adds a drink, the app recalculates the current caffeine levels 
and the equivalent cups of coffee consumed. 
It then updates the complication timeline 
and estimates the decrease in the user's caffeine level over the next 24 hours.

The app also updates the complications based on external changes 
that occur when the app isn't running. 
Coffee Tracker saves and reads caffeine samples to HealthKit, 
so the app must respond to any external changes, 
such as another app adding or deleting a caffeine sample from HealthKit. 
Coffee Tracker uses a background refresh task to query HealthKit for changes, 
and updates the app's data and the complication timeline.

This sample two versions: a "Starting Point" project and an "Updated" 
project. The starting point uses completion handlers to query the HealthKit SDK and to respond 
to `CLKComplicationDataSource` calls, and uses dispatch queues to isolate concurrent access to memory.
"Updated" replaces completion handlers with `async` function calls,` and uses actors 
to ensure isolation.

## Configure the Sample Code Project

To add the complication to an active watch face, start by building and running the sample code project in the simulator, 
and follow these steps:

1. Click the Digital Crown to exit the app and return to the watch face.
2. Using the trackpad, firmly press the watch face to put the face in edit mode, then tap Customize.
3. Swipe left until the configuration screen highlights the complications. Select the complication to modify.
4. Scroll to the Coffee Tracker complication, and then click the Digital Crown again to save your changes.
5. Tap the Coffee Tracker complication to go back to the app.

For more information on setting up watch faces, see [Change the watch face on your Apple Watch](https://support.apple.com/en-us/HT205536).

After configuring and running the Coffee Tracker app, you can test the background updates.
Make sure the Coffee Tracker complication appears on the active watch face. 
Then build and run the app in the simulator, and follow these steps:

1. Add one or more drinks using the app's main view.
2. Click the Digital Crown to send the app to the background.
3. Open Settings, and scroll down to Health > Health Data > Nutrition > Caffeine. 
    Settings should show all the drinks you added to the app.
4. Click Delete Caffeine Data to clear all the caffeine samples from HealthKit.
5. Navigate back to the watch face. 

Coffee Tracker should update the complication within 15 minutes; however, the update may be delayed based on the system's current state.

## Convert HealthKitController to Use Async Methods

The `HealthKitController` type contains several calls to the HealthKit SDK. The methods that call
these are updated to `async` functions. This allows the completion handler to be dropped. Instead
execution resumes after the awaited function completes. An awaited function can also throw instead 
of using an `Error?` type.

``` swift
// Save the sample to the HealthKit store.
do {
    try await store.save(caffeineSample)
    self.logger.debug("\(mgCaffeine) mg Drink saved to HealthKit")
} catch {
    self.logger.error("Unable to save \(caffeineSample) to the HealthKit store: \(error.localizedDescription)")
}
```

In some cases an SDK call requires use of a completion handler. For example, a call to [`HKAnchoredObjectQuery.init(type:predicate:anchor:limit:resultsHandler:)`](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery/1615071-init) takes a completion handler, 
but the call that needs to be awaited is the call to [`HKHealthStore.execute(_:)`](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614179-execute).

In order to await the results of a completion handler in these cases, a continuation is used:

``` swift
private func queryHealthKit() async throws -> ([HKSample]?, [HKDeletedObject]?, HKQueryAnchor?) {
    return try await withCheckedThrowingContinuation { continuation in
        // Create a predicate that only returns samples created within the last 24 hours.
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
        
        // Create the query.
        let query = HKAnchoredObjectQuery(
            type: caffeineType,
            predicate: datePredicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit) { (_, samples, deletedSamples, newAnchor, error) in
            
            // When the query ends, check for errors.
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: (samples, deletedSamples, newAnchor))
            }
            
        }
        store.execute(query)
    }
}
```

In order to protect the stored properties on the controller when accessed asynchronously, `HealthKitController`
is changed from a `class` type to an `actor`.

Calls to these async methods are made by creating new asynchronous tasks, which
can use `await` to wait for completion:

``` swift
// Handle background refresh tasks.
case let backgroundTask as WKApplicationRefreshBackgroundTask:
    
    async {
        // Check for updates from HealthKit.
        let model = CoffeeData.shared
        
        let success = await model.healthKitController.loadNewDataFromHealthKit()
            
        if success {
            // Schedule the next background update.
            scheduleBackgroundRefreshTasks()
            self.logger.debug("Background Task Completed Successfully!")
        }
        
        // Mark the task as ended, and request an updated snapshot, if necessary.
        backgroundTask.setTaskCompletedWithSnapshot(success)
    }
```

## Put CoffeeData on the Main Actor

The CoffeeData model implements `ObservableObject` and has an `@Published` property to feed the SwiftUI
views. This type is placed on the main actor, so all updates to this property will be made on the main thread.

Two methods that perform synchronous IO---the `load` and `save` methods---are factored out into a
separate CoffeeDataStore actor, which will perform these activities away from the main thread. 

The model type on the main actor must use `await` to call methods on the CoffeeDataStore actor, which allows
other work to run on the main thread during the synchronous IO operations. 

The two types communicate by passing value types---an array of `Drink` structs---as a function arguments to 
`save` and as return value from `load`.

In order to perform all methods asynchronously, the `currentDrinks` property's `didSet` operation 
is replaced by a `private(set)` and a `drinksUpdated() async` method is added. This awaits a call
to the `CoffeeDataStore` actor which performs a save on a background thread.

Calls to the `CoffeeData` from SwiftUI views do not require any use of `await` as these views
are also on the main actor, due to their use of `@EnvironmentObject`.

## Replace Delegates with Completion Handlers with Async Methods 

Several methods on the [`CLKComplicationDataSource`](https://developer.apple.com/documentation/clockkit/clkcomplicationdatasource) 
protocol used to configure the app's timeline take completion handlers. These can be replaced by async equivalents:

``` swift
// Define whether the complication is visible when the watch is unlocked.
func privacyBehavior(for complication: CLKComplication) async -> CLKComplicationPrivacyBehavior {
    // This is potentially sensitive data. Hide it on the lock screen.
    .hideOnLockScreen
}
```
