/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller.
*/

import UIKit
import RealityKit
import ARKit
import MapKit
import Photos

class ViewController: UIViewController, ARSessionDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toastLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var trackingStateLabel: UILabel!
    
    let coachingOverlayWorldTracking = ARCoachingOverlayView()
    
    var geoCoachingController: GeoCoachingViewController!
    
    let locationManager = CLLocationManager()
    
    var currentAnchors: [ARAnchor] {
        return arView.session.currentFrame?.anchors ?? []
    }
        
    // Geo anchors ordered by the time of their addition to the scene.
    var geoAnchors: [GeoAnchorWithAssociatedData] = []
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set this view controller as the session's delegate.
        arView.session.delegate = self
        
        // Enable coaching.
        setupWorldTrackingCoachingOverlay()
        
        geoCoachingController = GeoCoachingViewController(for: arView)
                
        // Set this view controller as the Core Location manager delegate.
        locationManager.delegate = self
        
        // Set this view controller as the MKMapView delegate.
        mapView.delegate = self
        
        // Disable automatic configuration and set up geotracking
        arView.automaticallyConfigureSession = false
                
        // Run a new AR Session.
        restartSession()
                
        // Add tap gesture recognizers
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnARView(_:))))
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnMapView(_:))))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true

        // Start listening for location updates from Core Location
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Disable Core Location when the view disappears.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - User Interaction
    @IBAction func menuButtonTapped(_ sender: Any) {
        presentAdditionalActions()
    }
    
    // Responds to a user tap on the AR view.
    @objc
    func handleTapOnARView(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        
        // Perform ARKit raycast on tap location
        if let result = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first {
            addGeoAnchor(at: result.worldTransform.translation)
        } else {
            showToast("No raycast result.\nTry pointing at a different area\nor move closer to a surface.")
        }
    }
    
    // Responds to a user tap on the map view.
    @objc
    func handleTapOnMapView(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: mapView)
        let location = mapView.convert(point, toCoordinateFrom: mapView)
        addGeoAnchor(at: location)
    }
    
    // Removes the most recent geo anchor.
    @IBAction func undoButtonTapped(_ sender: Any) {
        guard let lastGeoAnchor = geoAnchors.last else {
            showToast("Nothing to undo")
            return
        }
        
        // Remove geo anchor from the scene.
        arView.session.remove(anchor: lastGeoAnchor.geoAnchor)
        
        // Remove map overlay
        mapView.removeOverlay(lastGeoAnchor.mapOverlay)
        
        // Remove the element from the collection.
        geoAnchors.removeLast()
        
        showToast("Removed last added anchor")
    }
    
    // MARK: - Methods
    
    // Presents the available actions when the user presses the menu button.
    func presentAdditionalActions() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Reset Session", style: .destructive, handler: { (_) in
            self.restartSession()
        }))
        actionSheet.addAction(UIAlertAction(title: "Load Anchors …", style: .default, handler: { (_) in
            self.showGPXFiles()
        }))
        actionSheet.addAction(UIAlertAction(title: "Save Anchors …", style: .default, handler: { (_) in
            self.saveAnchors()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    // Calls into the function that saves any user-created geo anchors to a GPX file.
    func saveAnchors() {
        let geoAnchors = currentAnchors.compactMap({ $0 as? ARGeoAnchor })
        guard !geoAnchors.isEmpty else {
                alertUser(withTitle: "No geo anchors", message: "There are no geo anchors to save.")
            return
        }
        
        saveAnchorsAsGPXFile(geoAnchors)
    }

    func restartSession() {
        // Check geo-tracking location-based availability.
        ARGeoTrackingConfiguration.checkAvailability { (available, error) in
            if !available {
                let errorDescription = error?.localizedDescription ?? ""
                let recommendation = "Please try again in an area where geotracking is supported."
                let restartSession = UIAlertAction(title: "Restart Session", style: .default) { (_) in
                    self.restartSession()
                }
                self.alertUser(withTitle: "Geotracking unavailable",
                               message: "\(errorDescription)\n\(recommendation)",
                               actions: [restartSession])
            }
        }
        
        // Re-run the ARKit session.
        let geoTrackingConfig = ARGeoTrackingConfiguration()
        geoTrackingConfig.planeDetection = [.horizontal]
        arView.session.run(geoTrackingConfig)
        geoAnchors.removeAll()
        
        arView.scene.anchors.removeAll()
        
        trackingStateLabel.text = ""
        
        // Remove all anchor overlays from the map view
        let anchorOverlays = mapView.overlays.filter { $0 is AnchorIndicator }
        mapView.removeOverlays(anchorOverlays)
        
        showToast("Running new AR session")
    }
    
    func addGeoAnchor(at worldPosition: SIMD3<Float>) {
        arView.session.getGeoLocation(forPoint: worldPosition) { (location, altitude, error) in
            if let error = error {
                self.alertUser(withTitle: "Cannot add geo anchor",
                               message: "An error occurred while translating ARKit coordinates to geo coordinates: \(error.localizedDescription)")
                return
            }
            self.addGeoAnchor(at: location, altitude: altitude)
        }
    }
    
    func addGeoAnchor(at location: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        var geoAnchor: ARGeoAnchor!
        if let altitude = altitude {
            geoAnchor = ARGeoAnchor(coordinate: location, altitude: altitude)
        } else {
            geoAnchor = ARGeoAnchor(coordinate: location)
        }
        
        addGeoAnchor(geoAnchor)
    }
    
    func addGeoAnchor(_ geoAnchor: ARGeoAnchor) {
        
        // Don't add a geo anchor if Core Location isn't sure yet where the user is.
        guard isGeoTrackingLocalized else {
            alertUser(withTitle: "Cannot add geo anchor", message: "Unable to add geo anchor because geotracking has not yet localized.")
            return
        }
        arView.session.add(anchor: geoAnchor)
    }
    
    var isGeoTrackingLocalized: Bool {
        if let status = arView.session.currentFrame?.geoTrackingStatus, status.state == .localized {
            return true
        }
        return false
    }
    
    func distanceFromDevice(_ coordinate: CLLocationCoordinate2D) -> Double {
        if let devicePosition = locationManager.location?.coordinate {
            return MKMapPoint(coordinate).distance(to: MKMapPoint(devicePosition))
        } else {
            return 0
        }
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for geoAnchor in anchors.compactMap({ $0 as? ARGeoAnchor }) {
            // Effect a spatial-based delay to avoid blocking the main thread.
            DispatchQueue.main.asyncAfter(deadline: .now() + (distanceFromDevice(geoAnchor.coordinate) / 10)) {
                // Add an AR placemark visualization for the geo anchor.
                self.arView.scene.addAnchor(Entity.placemarkEntity(for: geoAnchor))
            }
            // Add a visualization for the geo anchor in the map view.
            let anchorIndicator = AnchorIndicator(center: geoAnchor.coordinate)
            self.mapView.addOverlay(anchorIndicator)

            // Remember the geo anchor we just added
            let anchorInfo = GeoAnchorWithAssociatedData(geoAnchor: geoAnchor, mapOverlay: anchorIndicator)
            self.geoAnchors.append(anchorInfo)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.restartSession()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    /// - Tag: GeoTrackingStatus
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        
        geoCoachingController.update(for: geoTrackingStatus)
        configureUIForCoaching(geoTrackingStatus.state != .localized)
        
        var text = ""
        // In localized state, show geotracking accuracy
        if geoTrackingStatus.state == .localized {
            text += "Accuracy: \(geoTrackingStatus.accuracy.description)"
        } else {
            // Otherwise show details why geotracking couldn't localize (yet)
            switch geoTrackingStatus.stateReason {
            case .none:
                break
            case .worldTrackingUnstable:
                let arTrackingState = session.currentFrame?.camera.trackingState
                if case let .limited(arTrackingStateReason) = arTrackingState {
                    text += "\n\(geoTrackingStatus.stateReason.description): \(arTrackingStateReason.description)."
                } else {
                    fallthrough
                }
            default: text += "\n\(geoTrackingStatus.stateReason.description)."
            }
        }
        self.trackingStateLabel.text = text
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Notify GeoLocation session coaching that the tracking state is stable
        switch frame.camera.trackingState {
        case .normal:
            geoCoachingController.worldTrackingStateIsNormal(true)
        default:
            return
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Update location indicator with live estimate from Core Location
        guard let location = locations.last else { return }
        
        // Update map area
        let camera = MKMapCamera(lookingAtCenter: location.coordinate,
                                 fromDistance: CLLocationDistance(250),
                                 pitch: 0,
                                 heading: mapView.camera.heading)
        mapView.setCamera(camera, animated: false)
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let anchorOverlay = overlay as? AnchorIndicator {
            let anchorOverlayView = MKCircleRenderer(circle: anchorOverlay)
            anchorOverlayView.strokeColor = .white
            anchorOverlayView.fillColor = .blue
            anchorOverlayView.lineWidth = 2
            return anchorOverlayView
        }
        return MKOverlayRenderer()
    }
}
