/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that implements the `INListRideOptionsIntentHandling` protocol to list ride options in Maps.
*/

import Intents

// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

class ListRideOptionsHandler: NSObject, INListRideOptionsIntentHandling, Handler {
    
    func canHandle(_ intent: INIntent) -> Bool {
        return intent is INListRideOptionsIntent
    }
    
    // Arrays used to create different ride options
    let rideNames = ["Pool", "Sedan", "SUV"]
    let poolOptions = [
        INRidePartySizeOption(
            partySizeRange: NSRange(location: 1, length: 0),
            sizeDescription: "Just me",
            priceRange: INPriceRange(price: 6.00, currencyCode: "USD")),
        INRidePartySizeOption(
            partySizeRange: NSRange(location: 1, length: 1),
            sizeDescription: "Me + 1 friend",
            priceRange: INPriceRange(price: 7.00, currencyCode: "USD"))
    ]
    
    // Party size options for Cab ride option
    var cabOptions = [
        INRidePartySizeOption(
            partySizeRange: NSRange(location: 1, length: 4),
            sizeDescription: "Up to 5 people",
            priceRange: INPriceRange(firstPrice: NSDecimalNumber(string: "6.00"),
                                     secondPrice: NSDecimalNumber(string: "10.00"),
                                     currencyCode: "USD")),
        INRidePartySizeOption(
            partySizeRange: NSRange(location: 1, length: 9),
            sizeDescription: "Up to 10 people",
            priceRange: INPriceRange(firstPrice: NSDecimalNumber(string: "6.00"),
                                     secondPrice: NSDecimalNumber(string: "30.00"),
                                     currencyCode: "USD"))
    ]
    
    // Party size options for SUV ride option
    var suvOptions = [
        INRidePartySizeOption(partySizeRange: NSRange(location: 1, length: 4),
                              sizeDescription: "Up to 5 people",
                              priceRange: INPriceRange(firstPrice: NSDecimalNumber(string: "6.27"),
                                                       secondPrice: NSDecimalNumber(string: "10.54"),
                                                       currencyCode: "USD"))
    ]
    
    // Pricing options for rides
    var fareLineItems: [INRideFareLineItem] = [
        INRideFareLineItem(title: "Base fare",
                           price: NSDecimalNumber(string: "5.00"),
                           currencyCode: "USD"),
        INRideFareLineItem(title: "+ Per mile",
                           price: NSDecimalNumber(string: "0.55"),
                           currencyCode: "USD"),
        INRideFareLineItem(title: "+ Per minute",
                           price: NSDecimalNumber(string: "0.75"),
                           currencyCode: "USD")
    ]
    
    var rideOptions: [INRideOption] = [INRideOption]()
    
    func confirm(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        // Optional, but you can implement actions here to be taken when ride request is confirmed from Maps.
    }
    
    func handle(intent: INListRideOptionsIntent, completion: @escaping (INListRideOptionsIntentResponse) -> Void) {
        for(index, name) in rideNames.enumerated() {
            let rideOption = INRideOption(name: name, estimatedPickupDate: Date(timeIntervalSinceNow: 120))
            
            // Populate ride options using the data created above.
            if index == 0 {
                rideOption.availablePartySizeOptions = poolOptions
                rideOption.fareLineItems = fareLineItems
                rideOption.priceRange = INPriceRange(price: NSDecimalNumber(string: "6.00"), currencyCode: "USD")
            } else if index == 1 {
                rideOption.availablePartySizeOptions = cabOptions
                rideOption.specialPricing = "2x Demand Pricing"
                rideOption.fareLineItems = fareLineItems
                rideOption.priceRange = INPriceRange(minimumPrice: NSDecimalNumber(string: "7.00"), currencyCode: "USD")
            } else if index == 2 {
                rideOption.availablePartySizeOptions = suvOptions
                rideOption.fareLineItems = fareLineItems
                rideOption.userActivityForBookingInApplication = NSUserActivity(activityType: "activity")
                rideOption.usesMeteredFare = true
                rideOption.disclaimerMessage = "This ride makes multiple stops."
            }
            rideOptions.append(rideOption)
        }
        
        // Add usable payment options to the response.
        let paymentOptions = [
            INPaymentMethod(type: .credit,
                            name: "Card 1",
                            identificationHint: "••••1111",
                            icon: INImage(named: "")),
            INPaymentMethod(type: .credit,
                            name: "Card 2",
                            identificationHint: "••••2222",
                            icon: INImage(named: "")),
            INPaymentMethod(type: .credit,
                            name: "Card 3",
                            identificationHint: "••••3333",
                            icon: INImage(named: ""))
        ]
        
        // Create and add data to the response object.
        let response = INListRideOptionsIntentResponse(code: .success, userActivity: nil)
        response.expirationDate = Date(timeIntervalSinceNow: 60 * 5)
        response.paymentMethods = paymentOptions
        response.rideOptions = rideOptions

        completion(response)
    }
}
