/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extensions and helpers.
*/

import MapKit
import ARKit
import RealityKit

// A map overlay for geo anchors the user has added.
class AnchorIndicator: MKCircle {
    convenience init(center: CLLocationCoordinate2D) {
        self.init(center: center, radius: 3.0)
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        get {
            return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
        }
        set (newValue) {
            columns.3.x = newValue.x
            columns.3.y = newValue.y
            columns.3.z = newValue.z
        }
    }
}

extension Entity {
    static func placemarkEntity(for arAnchor: ARAnchor) -> AnchorEntity {
        let placemarkAnchor = AnchorEntity(anchor: arAnchor)
        
        let sphereIndicator = generateSphereIndicator(radius: 0.1)
        
        // Move the indicator up by half its height so that it doesn't intersect with the ground.
        let height = sphereIndicator.visualBounds(relativeTo: nil).extents.y
        sphereIndicator.position.y = height / 2
        
        // The move function animates the indicator to expand and rise up 3 meters from the ground like a balloon.
        // Elevated GeoAnchors are easier to see, and are high enough to stand under.
        let distanceFromGround: Float = 3
        sphereIndicator.move(by: [0, distanceFromGround, 0], scale: .one * 10, after: 0.5, duration: 5.0)
        placemarkAnchor.addChild(sphereIndicator)
        
        return placemarkAnchor
    }
    
    static func generateSphereIndicator(radius: Float) -> Entity {
        let indicatorEntity = Entity()
        
        let innerSphere = ModelEntity.blueSphere.clone(recursive: true)
        indicatorEntity.addChild(innerSphere)
        let outerSphere = ModelEntity.transparentSphere.clone(recursive: true)
        indicatorEntity.addChild(outerSphere)
        
        return indicatorEntity
    }
    
    func move(by translation: SIMD3<Float>, scale: SIMD3<Float>, after delay: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var transform: Transform = .identity
            transform.translation = self.transform.translation + translation
            transform.scale = self.transform.scale * scale
            self.move(to: transform, relativeTo: self.parent, duration: duration, timingFunction: .easeInOut)
        }
    }
}

extension ModelEntity {
    static let blueSphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.066), materials: [UnlitMaterial(color: #colorLiteral(red: 0, green: 0.3, blue: 1.4, alpha: 1))])
    static let transparentSphere = ModelEntity(
        mesh: MeshResource.generateSphere(radius: 0.1),
        materials: [SimpleMaterial(color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.25), roughness: 0.3, isMetallic: true)])
}

extension ViewController {
    func alertUser(withTitle title: String, message: String, actions: [UIAlertAction]? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if let actions = actions {
                actions.forEach { alert.addAction($0) }
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .default))
            }
            self.present(alert, animated: true)
        }
    }
    
    func showToast(_ message: String, duration: TimeInterval = 2) {
        DispatchQueue.main.async {
            self.toastLabel.numberOfLines = message.components(separatedBy: "\n").count
            self.toastLabel.text = message
            self.toastLabel.isHidden = false
            
            // use tag to tell if label has been updated
            let tag = self.toastLabel.tag + 1
            self.toastLabel.tag = tag
            
            if duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    // Do not hide if showToast is called again, before this block kicks in.
                    if self.toastLabel.tag == tag {
                        self.toastLabel.isHidden = true
                    }
                }
            }
        }
    }
}

extension UIView {
    func fillParentView(withInset inset: CGFloat = 0) {
        if let parentView = superview {
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: inset).isActive = true
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -inset).isActive = true
            topAnchor.constraint(equalTo: parentView.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor).isActive = true
        }
    }
}

extension ARGeoTrackingStatus.StateReason {
    var description: String {
        switch self {
        case .none: return "None"
        case .notAvailableAtLocation: return "Geotracking is unavailable here. Please return to your previous location to continue"
        case .needLocationPermissions: return "App needs location permissions"
        case .worldTrackingUnstable: return "Limited tracking"
        case .geoDataNotLoaded: return "Downloading localization imagery. Please wait"
        case .devicePointedTooLow: return "Point the camera at a nearby building"
        case .visualLocalizationFailed: return "Point the camera at a building unobstructed by trees or other objects"
        case .waitingForLocation: return "ARKit is waiting for the system to provide a precise coordinate for the user"
        case .waitingForAvailabilityCheck: return "ARKit is checking Location Anchor availability at your locaiton"
        @unknown default: return "Unknown reason"
        }
    }
}

extension ARGeoTrackingStatus.Accuracy {
    var description: String {
        switch self {
        case .undetermined: return "Undetermined"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}

extension ARCamera.TrackingState.Reason {
    var description: String {
        switch self {
        case .initializing: return "Initializing"
        case .excessiveMotion: return "Too much motion"
        case .insufficientFeatures: return "Insufficient features"
        case .relocalizing: return "Relocalizing"
        @unknown default: return "Unknown"
        }
    }
}
