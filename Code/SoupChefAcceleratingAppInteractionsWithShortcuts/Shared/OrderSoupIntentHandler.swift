/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Intent handler for `OrderSoupIntent`.
*/

import UIKit
import CoreLocation
import Intents

public class OrderSoupIntentHandler: NSObject, OrderSoupIntentHandling {
    
    // The Dynamic Options API allows you to provide a set of values for eligible parameters
    // dynamically when the user configures this intent parameter in the Shortcuts app.
    //
    // The system calls this method repeatedly while the user types their search term.
    @available(iOSApplicationExtension 14.0, watchOSApplicationExtension 7.0, *)
    public func provideSoupOptionsCollection(for intent: OrderSoupIntent,
                                             searchTerm: String?,
                                             with completion: @escaping (INObjectCollection<Soup>?, Error?) -> Void) {
        let soupMenuManager = SoupMenuManager()
        
        // Dynamic search should only be adopted for searching large catalogs, and not for small static colletions.
        // The Shortcuts app supports filtering of small collections by default.
        let availableRegularItems = soupMenuManager.findItems(exactlyMatching: [.available, .regularItem],
                                                              searchTerm: searchTerm)
        let availableDailySpecialItems = soupMenuManager.findItems(exactlyMatching: [.available, .dailySpecialItem],
                                                                   searchTerm: searchTerm)
        
        let objectCollection = INObjectCollection(sections: [
            INObjectSection(title: "Regular", items: availableRegularItems.map { Soup(menuItem: $0) }),
            INObjectSection(title: "Special", items: availableDailySpecialItems.map { Soup(menuItem: $0) })
        ])
        completion(objectCollection, nil)
    }
    
    @available(iOSApplicationExtension 14.0, watchOSApplicationExtension 7.0, *)
    public func provideToppingsOptionsCollection(for intent: OrderSoupIntent,
                                                 with completion: @escaping (INObjectCollection<Topping>?, Error?) -> Void) {
        completion(INObjectCollection(items: Topping.allCases), nil)
    }
    
    @available(iOSApplicationExtension 14.0, watchOSApplicationExtension 7.0, *)
    public func provideStoreLocationOptionsCollection(for intent: OrderSoupIntent,
                                                      with completion: @escaping (INObjectCollection<CLPlacemark>?, Error?) -> Void) {
        completion(INObjectCollection(items: Order.storeLocations), nil)
    }
    
    /// - Tag: resolve_intent
    public func resolveToppings(for intent: OrderSoupIntent, with completion: @escaping ([ToppingResolutionResult]) -> Void) {
        guard let toppings = intent.toppings else {
            completion([ToppingResolutionResult.needsValue()])
            return
        }
        
        if toppings.isEmpty {
            completion([ToppingResolutionResult.notRequired()])
            return
        }
        
        completion(toppings.map { (topping) -> ToppingResolutionResult in
            return ToppingResolutionResult.success(with: topping)
        })
    }
    
    public func resolveSoup(for intent: OrderSoupIntent, with completion: @escaping (SoupResolutionResult) -> Void) {
        guard let soup = intent.soup else {
            completion(SoupResolutionResult.disambiguation(with: Soup.allCases))
            return
        }
        completion(SoupResolutionResult.success(with: soup))
    }
    
    public func resolveQuantity(for intent: OrderSoupIntent, with completion: @escaping (OrderSoupQuantityResolutionResult) -> Void) {
        let soupMenuManager = SoupMenuManager()
        guard let soup = intent.soup, let menuItem = soupMenuManager.findItem(soup) else {
            completion(OrderSoupQuantityResolutionResult.unsupported())
            return
        }
        
        // A soup order requires a quantity.
        guard let quantity = intent.quantity else {
            completion(OrderSoupQuantityResolutionResult.needsValue())
            return
        }
        
        // If the user asks to order more soups than we have in stock,
        // provide a specific response informing the user why we can't handle the order.
        if quantity.intValue > menuItem.itemsInStock {
            completion(OrderSoupQuantityResolutionResult.unsupported(forReason: .notEnoughInStock))
            return
        }
        
        // Ask the user to confirm that they actually want to order 5 or more soups.
        if quantity.intValue >= 5 {
            completion(OrderSoupQuantityResolutionResult.confirmationRequired(with: quantity.intValue))
            return
        }
        
        completion(OrderSoupQuantityResolutionResult.success(with: quantity.intValue))
    }
    
    public func resolveOrderType(for intent: OrderSoupIntent, with completion: @escaping (OrderTypeResolutionResult) -> Void) {
        if intent.orderType == .unknown {
            completion(OrderTypeResolutionResult.needsValue())
        } else {
            completion(OrderTypeResolutionResult.success(with: intent.orderType))
        }
    }
    
    public func resolveDeliveryLocation(for intent: OrderSoupIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        guard let deliveryLocation = intent.deliveryLocation else {
            completion(INPlacemarkResolutionResult.needsValue())
            return
        }
        
        completion(INPlacemarkResolutionResult.success(with: deliveryLocation))
    }
    
    public func resolveStoreLocation(for intent: OrderSoupIntent, with completion: @escaping (INPlacemarkResolutionResult) -> Void) {
        guard let storeLocation = intent.storeLocation else {
            completion(INPlacemarkResolutionResult.needsValue())
            return
        }
        
        completion(INPlacemarkResolutionResult.success(with: storeLocation))
    }
    
    /// - Tag: confirm_intent
    public func confirm(intent: OrderSoupIntent, completion: @escaping (OrderSoupIntentResponse) -> Void) {
        
        /*
        The confirm phase provides an opportunity for you to perform any final validation of the intent parameters and to
        verify that any needed services are available. You might confirm that you can communicate with your company’s server.
         */
        let soupMenuManager = SoupMenuManager()
        guard let soup = intent.soup, let menuItem = soupMenuManager.findItem(soup) else {
            completion(OrderSoupIntentResponse(code: .failure, userActivity: nil))
            return
        }

        if menuItem.attributes.contains(.available) == false {
            //  Here's an example of how to use a custom response for a failure case when a particular soup item is unavailable.
            completion(OrderSoupIntentResponse.failureOutOfStock(soup: soup))
            return
        }
        
        // Once the intent is validated, indicate that the intent is ready to handle.
        completion(OrderSoupIntentResponse(code: .ready, userActivity: nil))
    }
    
    public func handle(intent: OrderSoupIntent, completion: @escaping (OrderSoupIntentResponse) -> Void) {

        guard let order = Order(from: intent), let soup = intent.soup
        else {
            completion(OrderSoupIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        //  The handle method is also an appropriate place to handle payment via Apple Pay.
        //  A declined payment is another example of a failure case that could take advantage of a custom response.
        
        //  Place the soup order via the order manager.
        let orderManager = SoupOrderDataManager()
        orderManager.placeOrder(order: order)
        
        //  For the success case, we want to indicate a wait time so the user knows when their soup order will be ready.
        //  This sample uses a hardcoded value, but your implementation could use a time returned by your server.
        let orderDate = Date()
        let readyDate = Date(timeInterval: 10 * 60, since: orderDate) // 10 minutes
        
        let userActivity = NSUserActivity(activityType: NSUserActivity.orderCompleteActivityType)
        userActivity.addUserInfoEntries(from: [NSUserActivity.ActivityKeys.orderID.rawValue: order.id])
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        
        let orderDetails = OrderDetails(identifier: nil, display: formatter.string(from: orderDate, to: readyDate) ?? "")
        orderDetails.estimatedTime = Calendar.current.dateComponents([.minute, .hour, .day, .month, .year], from: readyDate)
        orderDetails.total = INCurrencyAmount(amount: NSDecimalNumber(decimal: order.total),
                                              currencyCode: NumberFormatter.currencyFormatter.currencyCode)
        
        let response: OrderSoupIntentResponse
        if let formattedWaitTime = formatter.string(from: orderDate, to: readyDate) {
            response = OrderSoupIntentResponse.success(orderDetails: orderDetails, soup: soup, waitTime: formattedWaitTime)
        } else {
            // A fallback success code with a less specific message string.
            response = OrderSoupIntentResponse.successReadySoon(orderDetails: orderDetails, soup: soup)
        }
        
        response.userActivity = userActivity
        completion(response)
    }
}
