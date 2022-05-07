/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The single entry point for the Fruta App Clip.
*/

import SwiftUI
import AppClip
import CoreLocation

@main
struct FrutaAppClip: App {
    @StateObject private var model = Model()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                SmoothieMenu()
            }
            .environmentObject(model)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: handleUserActivity)
        }
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        guard
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems
        else {
            return
        }
        
        if let smoothieID = queryItems.first(where: { $0.name == "smoothie" })?.value {
            model.selectedSmoothieID = smoothieID
        }
        
        guard
            let payload = userActivity.appClipActivationPayload,
            let latitudeValue = queryItems.first(where: { $0.name == "latitude" })?.value,
            let longitudeValue = queryItems.first(where: { $0.name == "longitude" })?.value,
            let latitude = Double(latitudeValue),
            let longitude = Double(longitudeValue)
        else {
            return
        }
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: 100, identifier: "smoothie_location")
        
        payload.confirmAcquired(in: region) { inRegion, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            DispatchQueue.main.async {
                model.isApplePayEnabled = inRegion
            }
        }
    }
}
