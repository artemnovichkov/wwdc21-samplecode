/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that implements the `INRequestRideIntentHandling` protocol to allow for ride requests in Siri and Maps.
*/

import Foundation
import Intents

class RequestRideIntentHandler: NSObject, INRequestRideIntentHandling, Handler {
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INRequestRideIntent
    }
    
    func resolvePickupLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        // Always check if parameter is not nil
        if let pickup = intent.pickupLocation {
            completion(.success(with: pickup))
        } else {
            completion(.confirmationRequired(with: intent.pickupLocation))
        }
    }
    
    func resolveDropOffLocation(for intent: INRequestRideIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        if let dropOff = intent.dropOffLocation {
            completion(.success(with: dropOff))
        } else {
            completion(.confirmationRequired(with: intent.dropOffLocation))
        }
    }
    
    func confirm(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        
        let rideOption = INRideOption(name: "Small car", estimatedPickupDate: Date(timeIntervalSinceNow: 5 * 60))
        let rideStatus = INRideStatus()
        rideStatus.rideOption = rideOption
        rideStatus.estimatedPickupDate = Date(timeIntervalSinceNow: 5 * 60)
        rideStatus.rideIdentifier = NSUUID().uuidString // This ride identifier must match the one in handleRequestRide and getRideStatus
        
        let response = INRequestRideIntentResponse(code: .success, userActivity: nil)
        response.rideStatus = rideStatus
        
        completion(response)
    }
    
    func handle(intent: INRequestRideIntent, completion: @escaping (INRequestRideIntentResponse) -> Void) {
        // Build response shown to user after tapping "Request."
        let response = INRequestRideIntentResponse(code: .success, userActivity: .none)
        
        // Populate status with all information you want to display on screen.
        let status = INRideStatus()
        status.rideIdentifier = NSUUID().uuidString
        // Set current ride status
        status.phase = .confirmed
        status.pickupLocation = intent.pickupLocation
        status.dropOffLocation = intent.dropOffLocation
        status.completionStatus = .completed()
        
        // Add driver field
        status.driver = INRideDriver(personHandle: INPersonHandle(value: "email@example.com", type: .emailAddress),
                                     nameComponents: PersonNameComponents(),
                                     displayName: "John Doe",
                                     image: INImage(named: "handle_blue"),
                                     contactIdentifier: nil,
                                     customIdentifier: nil,
                                     aliases: nil,
                                     suggestionType: .instantMessageAddress)
        
        // Add ETA field
        status.estimatedPickupDate = Calendar.current.date(byAdding: DateComponents(minute: 5), to: Date())
        let vehicle = INRideVehicle()
        vehicle.model = "1984 Small Car"
        status.vehicle = vehicle
        
        response.rideStatus = status
        completion(response)
    }
}
