/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data controller that manages reading and writing data from the HealthKit store.
*/

import Foundation
import HealthKit
import os

// The key used to save and load anchor objects from user defaults.
private let anchorKey = "anchorKey"

// The HealthKit store.
private let store = HKHealthStore()
private let isAvailable = HKHealthStore.isHealthDataAvailable()

// Caffeine types, used to read and write caffeine samples.
private let caffeineType = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
private let types: Set<HKSampleType> = [caffeineType]

// Milligram units.
private let miligrams = HKUnit.gramUnit(with: .milli)

class HealthKitController {
    
    let logger = Logger(subsystem: "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.HealthKitController",
                        category: "HealthKit")
    
    // MARK: - Properties
    
    // A weak link to the main model.
    private weak var model: CoffeeData?
    
    // Indicates whether the user has authroized access to their health data
    private lazy var isAuthorized = false
    
    // An anchor object, used to download just the changes since the last time.
    private var anchor: HKQueryAnchor? {
        get {
            // If user defaults returns nil, just return it.
            guard let data = UserDefaults.standard.object(forKey: anchorKey) as? Data else {
                return nil
            }
            
            // Otherwise, unarchive and return the data object.
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            } catch {
                // If an error occurs while unarchiving, log the error and return nil.
                logger.error("Unable to unarchive \(data): \(error.localizedDescription)")
                return nil
            }
        }
        set(newAnchor) {
            // If the new value is nil, save it.
            guard let newAnchor = newAnchor else {
                UserDefaults.standard.set(nil, forKey: anchorKey)
                return
            }
            
            // Otherwise convert the anchor object to Data, and save it in user defaults.
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: anchorKey)
            } catch {
                // If an error occurs while archiving the anchor, just log the error.
                // the value stored in user defaults is not changed.
                logger.error("Unable to archive \(newAnchor): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Initializers
    
    // The HealthKit controller's initializer.
    init(withModel model: CoffeeData) {
        self.model = model
    }
    
    // MARK: - Public Methods
    
    // Request authorization to read and save the required data types.
    public func requestAuthorization(completionHandler: @escaping (Bool) -> Void ) {
        guard isAvailable else { return }
        
        store.requestAuthorization(toShare: types, read: types) { success, error in
            
            // Check for any errors.
            guard error == nil else {
                self.logger.error("An error occurred while requesting HealthKit Authorization: \(error!.localizedDescription)")
                return
            }
            
            // Set the authorization property, and call the handler.
            self.isAuthorized = success
            completionHandler(success)
        }
    }
    
    // Reads data from the HealthKit store.
    public func loadNewDataFromHealthKit( completionHandler: @escaping (Bool) -> Void = { _ in }) {
        
        guard isAvailable else {
            logger.debug("HealthKit is not available on this device.")
            completionHandler(false)
            return
        }
        
        logger.debug("Loading data from HealthKit")
        
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
                self.logger.error("An error occurred while querying for samples: \(error.localizedDescription)")
                completionHandler(false)
                return
            }
            
            // Update the anchor.
            self.anchor = newAnchor
            
            // Convert new caffeine samples into Drink instances.
            var newDrinks: [Drink] = []
            if let samples = samples {
                newDrinks = self.drinksToAdd(from: samples)
            }
            
            // Create a set of UUIDs for any samples deleted from HealthKit.
            let deletedDrinks = self.drinksToDelete(from: deletedSamples ?? [])
            
            // Update the data on the main queue.
            DispatchQueue.main.async {
                // Update the model.
                self.updateModel(newDrinks: newDrinks, deletedDrinks: deletedDrinks)
                completionHandler(true)
            }
        }
        
        store.execute(query)
    }
    
    // Save a drink to HealthKit as a caffeine sample.
    public func save(drink: Drink) {
        
        // Make sure HealthKit is available and authorized.
        guard isAvailable else { return }
        guard store.authorizationStatus(for: caffeineType) == .sharingAuthorized else { return }
        
        // Create metadata to hold the drink's UUID.
        // Use the sync identifier to remove drinks if they are deleted from
        // HealthKit.
        let metadata: [String: Any] = [HKMetadataKeySyncIdentifier: drink.uuid.uuidString,
                                       HKMetadataKeySyncVersion: 1]
        
        // Create a quantity object for the amount of caffeine in the drink.
        let mgCaffeine = HKQuantity(unit: miligrams, doubleValue: drink.mgCaffeine)
        
        // Create the caffeine sample.
        let caffeineSample = HKQuantitySample(type: caffeineType,
                                              quantity: mgCaffeine,
                                              start: drink.date,
                                              end: drink.date,
                                              metadata: metadata)
        
        // Save the sample to the HealthKit store.
        store.save(caffeineSample) { success, error in
            guard success else {
                self.logger.error("Unable to save \(caffeineSample) to the HealthKit store: \(error!.localizedDescription)")
                return
            }
            
            self.logger.debug("\(mgCaffeine) mg Drink saved to HealthKit")
        }
    }
    
    // MARK: - Private Methods
    // Take an array of caffeine samples and returns an array of drinks.
    private func drinksToAdd(from samples: [HKSample]) -> [Drink] {
        
        // Filter out any samples saved by this app.
        let newSamples = samples.filter { sample in
            sample.sourceRevision.source != HKSource.default()
        }
        
        logger.debug("\(newSamples.count) samples not from this app!")
        
        let quantitySamples = newSamples.compactMap { sample in
            sample as? HKQuantitySample
        }
        
        logger.debug("\(quantitySamples.count) samples are quantity samples")
        
        // Return each sample, converted into a drink
        return quantitySamples.map { sample in
            Drink(mgCaffeine: sample.quantity.doubleValue(for: miligrams),
                  onDate: sample.startDate,
                  uuid: sample.uuid)
        }
    }
    
    // For any drinks deleted from the HealthKit store, this also deletes them from the app's data.
    private func drinksToDelete(from samples: [HKDeletedObject]) -> Set<UUID> {
        let uuidsToDelete = samples.lazy.map { deletedObject -> UUID in
            // Prefer HKMetadataKeySyncIdentifier if available
            let uuidString = deletedObject.metadata?[HKMetadataKeySyncIdentifier] as? String ?? ""
            return UUID(uuidString: uuidString) ?? deletedObject.uuid
        }
        
        logger.debug("\(uuidsToDelete.count) drinks deleted from HealthKit.")

        return Set(uuidsToDelete)
    }
    
    // Update the model.
    private func updateModel(newDrinks: [Drink], deletedDrinks: Set<UUID>) {
        assert(Thread.main == Thread.current, "Must be run on the main queue because it accesses currentDrinks.")
        
        guard !newDrinks.isEmpty && !deletedDrinks.isEmpty else {
            logger.debug("No drinks to add or delete from HealthKit.")
            return
        }
        
        // Get a copy of the current drink data.
        guard let oldDrinks = model?.currentDrinks else { return }
        
        // Remove the deleted drinks.
        var drinks = oldDrinks.filter { deletedDrinks.contains($0.uuid) }
        
        // Add the new drinks.
        drinks += newDrinks
        
        // Sort the array by date.
        drinks.sort { $0.date < $1.date }
        
        model?.currentDrinks = drinks
    }
}
