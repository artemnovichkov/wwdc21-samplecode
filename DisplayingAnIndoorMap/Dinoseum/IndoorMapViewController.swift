/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller.
*/

import UIKit
import CoreLocation
import MapKit

class IndoorMapViewController: UIViewController, MKMapViewDelegate, LevelPickerDelegate {
    @IBOutlet var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    @IBOutlet var levelPicker: LevelPickerView!
    
    var venue: Venue?
    private var levels: [Level] = []
    private var currentLevelFeatures = [StylableFeature]()
    private var currentLevelOverlays = [MKOverlay]()
    private var currentLevelAnnotations = [MKAnnotation]()
    let pointAnnotationViewIdentifier = "PointAnnotationView"
    let labelAnnotationViewIdentifier = "LabelAnnotationView"
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Request location authorization so the user's current location can be displayed on the map
        locationManager.requestWhenInUseAuthorization()

        self.mapView.delegate = self
        self.mapView.register(PointAnnotationView.self, forAnnotationViewWithReuseIdentifier: pointAnnotationViewIdentifier)
        self.mapView.register(LabelAnnotationView.self, forAnnotationViewWithReuseIdentifier: labelAnnotationViewIdentifier)

        // Decode the IMDF data. In this case, IMDF data is stored locally in the current bundle.
        let imdfDirectory = Bundle.main.resourceURL!.appendingPathComponent("IMDFData")
        do {
            let imdfDecoder = IMDFDecoder()
            venue = try imdfDecoder.decode(imdfDirectory)
        } catch let error {
            print(error)
        }
        
        // You might have multiple levels per ordinal. A selected level picker item displays all levels with the same ordinal.
        if let levelsByOrdinal = self.venue?.levelsByOrdinal {
            let levels = levelsByOrdinal.mapValues { (levels: [Level]) -> [Level] in
                // Choose indoor level over outdoor level
                if let level = levels.first(where: { $0.properties.outdoor == false }) {
                    return [level]
                } else {
                    return [levels.first!]
                }
            }.flatMap({ $0.value })
            
            // Sort levels by their ordinal numbers
            self.levels = levels.sorted(by: { $0.properties.ordinal > $1.properties.ordinal })
        }
        
        // Set the map view's region to enclose the venue
        if let venue = venue, let venueOverlay = venue.geometry[0] as? MKOverlay {
            self.mapView.setVisibleMapRect(venueOverlay.boundingMapRect, edgePadding:
                UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)
        }

        // Display a default level at start, for example a level with ordinal 0
        showFeaturesForOrdinal(0)
        
        // Setup the level picker with the shortName of each level
        setupLevelPicker()
    }
    
    private func showFeaturesForOrdinal(_ ordinal: Int) {
        guard self.venue != nil else {
            return
        }

        // Clear out the previously-displayed level's geometry
        self.currentLevelFeatures.removeAll()
        self.mapView.removeOverlays(self.currentLevelOverlays)
        self.mapView.removeAnnotations(self.currentLevelAnnotations)
        self.currentLevelAnnotations.removeAll()
        self.currentLevelOverlays.removeAll()

        // Display the level's footprint, unit footprints, opening geometry, and occupant annotations
        if let levels = self.venue?.levelsByOrdinal[ordinal] {
            for level in levels {
                self.currentLevelFeatures.append(level)
                self.currentLevelFeatures += level.units
                self.currentLevelFeatures += level.openings
                
                let occupants = level.units.flatMap({ $0.occupants })
                let amenities = level.units.flatMap({ $0.amenities })
                self.currentLevelAnnotations += occupants
                self.currentLevelAnnotations += amenities
            }
        }
        
        let currentLevelGeometry = self.currentLevelFeatures.flatMap({ $0.geometry })
        self.currentLevelOverlays = currentLevelGeometry.compactMap({ $0 as? MKOverlay })

        // Add the current level's geometry to the map
        self.mapView.addOverlays(self.currentLevelOverlays)
        self.mapView.addAnnotations(self.currentLevelAnnotations)
    }
    
    private func setupLevelPicker() {
        // Use the level's short name for a level picker item display name
        self.levelPicker.levelNames = self.levels.map {
            if let shortName = $0.properties.shortName.bestLocalizedValue {
                return shortName
            } else {
                return "\($0.properties.ordinal)"
            }
        }
        
        // Begin by displaying the level-specific information for Ordinal 0 (which is not necessarily the first level in the list).
        if let baseLevel = levels.first(where: { $0.properties.ordinal == 0 }) {
            levelPicker.selectedIndex = self.levels.firstIndex(of: baseLevel)!
        }
    }

    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let shape = overlay as? (MKShape & MKGeoJSONObject),
            let feature = currentLevelFeatures.first( where: { $0.geometry.contains( where: { $0 == shape }) }) else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer: MKOverlayPathRenderer
        switch overlay {
        case is MKMultiPolygon:
            renderer = MKMultiPolygonRenderer(overlay: overlay)
        case is MKPolygon:
            renderer = MKPolygonRenderer(overlay: overlay)
        case is MKMultiPolyline:
            renderer = MKMultiPolylineRenderer(overlay: overlay)
        case is MKPolyline:
            renderer = MKPolylineRenderer(overlay: overlay)
        default:
            return MKOverlayRenderer(overlay: overlay)
        }

        // Configure the overlay renderer's display properties in feature-specific ways.
        feature.configure(overlayRenderer: renderer)

        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let stylableFeature = annotation as? StylableFeature {
            if stylableFeature is Occupant {
                let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: labelAnnotationViewIdentifier, for: annotation)
                stylableFeature.configure(annotationView: annotationView)
                return annotationView
            } else {
                let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointAnnotationViewIdentifier, for: annotation)
                stylableFeature.configure(annotationView: annotationView)
                return annotationView
            }
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let venue = self.venue, let location = userLocation.location else {
            return
        }

        // Display location only if the user is inside this venue.
        var isUserInsideVenue = false
        let userMapPoint = MKMapPoint(location.coordinate)
        for geometry in venue.geometry {
            guard let overlay = geometry as? MKOverlay else {
                continue
            }

            if overlay.boundingMapRect.contains(userMapPoint) {
                isUserInsideVenue = true
                break
            }
        }

        guard isUserInsideVenue else {
            return
        }

        // If the device knows which level the user is physically on, automatically switch to that level.
        if let ordinal = location.floor?.level {
            showFeaturesForOrdinal(ordinal)
        }
    }
    
    // MARK: - LevelPickerDelegate
    
    func selectedLevelDidChange(selectedIndex: Int) {
        precondition(selectedIndex >= 0 && selectedIndex < self.levels.count)
        let selectedLevel = self.levels[selectedIndex]
        showFeaturesForOrdinal(selectedLevel.properties.ordinal)
    }
}
