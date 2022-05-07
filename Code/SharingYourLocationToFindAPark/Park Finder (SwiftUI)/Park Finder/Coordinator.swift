/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A coordinator to add pins on the map view.
*/

import CoreLocation
import MapKit

class Coordinator: NSObject, CLLocationManagerDelegate {
    var parent: MapView
    
    init(_ parent: MapView) {
        self.parent = parent
    }
    
    // Helper function that adds park pins on the mapview.
    private func addPins(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else {
                return
            }
            
            if let placemarks = placemarks, let placemark = placemarks.first, let location = placemark.location {
                let span = MKCoordinateSpan(latitudeDelta: 0.013, longitudeDelta: 0.010)
                let region = MKCoordinateRegion(center: location.coordinate, span: span)
                self.parent.map.setRegion(region, animated: false)
                
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = "Park"
                request.region = self.parent.map.region
                
                let search = MKLocalSearch(request: request)
                search.start { (response, error) in
                    guard let response = response else {
                        return
                    }
                    
                    self.parent.map.removeAnnotations(self.parent.map.annotations)
                    for item in response.mapItems {
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title = item.placemark.name
                        self.parent.map.addAnnotation(annotation)
                    }
                }
            }
        }
    }

    // MARK: - Location Manager Delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.addPins(location: location)
            manager.stopUpdatingLocation()
        }
    }
}
