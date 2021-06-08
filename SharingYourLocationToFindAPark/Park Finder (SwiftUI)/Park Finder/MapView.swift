/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A map view to configure the map.
*/

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    
    @Binding var manager: CLLocationManager
    
    let map = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {}
    
    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        let center = CLLocationCoordinate2D(latitude: 13.1, longitude: 80.3)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        map.region = region
        manager.delegate = context.coordinator
        return map
    }
}
