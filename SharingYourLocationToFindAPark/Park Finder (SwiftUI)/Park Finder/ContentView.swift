/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A content view that illustrates a use case of the location button.
*/

import SwiftUI
import CoreLocationUI
import CoreLocation

struct ContentView: View {
    @State var manager = CLLocationManager()
    
    // Add a map view and button to the body.
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(manager: $manager)
                .edgesIgnoringSafeArea(.all)
            LocationButton(LocationButton.Title.currentLocation) {
                // Start updating location when user taps the button.
                // Location button doesn't require the additional step of calling `requestWhenInUseAuthorization()`.
                manager.startUpdatingLocation()
            }.foregroundColor(Color.white)
                .cornerRadius(27)
                .frame(width: 210, height: 54)
                .padding(.bottom, 30)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
