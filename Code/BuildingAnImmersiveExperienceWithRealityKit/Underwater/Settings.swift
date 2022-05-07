/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Configurable settings for the scene.
*/

import RealityKit
import Combine
import Foundation
import SwiftUI

class Settings: ObservableObject {
    @Published var separationWeight: Float = 2.8
    @Published var cohesionWeight: Float = 1.0
    @Published var alignmentWeight: Float = 1.0
    @Published var hungerWeight: Float = 1.8
    @Published var fearWeight: Float = 0.0
    @Published var topSpeed: Float = 0.018
    @Published var maxSteeringForce: Float = 5.0
    @Published var maxNeighborDistance: Float = 1.0
    @Published var desiredSeparation: Float = 0.2
    @Published var animationScalar: Float = 400.0
    @Published var attractorWeight: Float = 1.0
    @Published var bonkWeight: Float = 2.0
    @Published var timeScale: Float = 1.0
    /// Speed of the rotation of the model, independent of physics/movement.
    @Published var angularModelSpeed: Float = 1E+3
    @Published var useAngularModelSpeed: Bool = true

    @Published var postProcessing = PostProcessing.Options()
    @Published var character = Character.Options()
    @Published var view = UnderwaterView.DebugOptions()
    @Published var scattering: Bool = true
    @Published var octopus = OctopusOptions()

    static let fishOrigin = SIMD3<Float>(0, 0, -1)
    static let wanderRadius: Float = 0.7

    var maxSteeringForceVector: SIMD3<Float> {
        SIMD3<Float>(repeating: maxSteeringForce)
    }

    var topSpeedVector: SIMD3<Float> {
        SIMD3<Float>(repeating: topSpeed)
    }
}

struct SettingsComponent: RealityKit.Component {
    var settings: Settings
}

struct SettingsView: View {

    @StateObject var settings: Settings

    var body: some View {

        // View
        UnderwaterView.DebugOptionsView(options: $settings.view)

        // Movement
        if Feature.features.contains(where: { $0.hasMovement }) {
            MovementSettingsView()
                .environmentObject(settings)
        }

        // Postprocessing
        if Feature.features.contains(.postProcessing) {
            PostProcessing.Options.View(options: $settings.postProcessing)
        }

        // Character
        if Feature.features.contains(.diverCharacter) {
            Character.OptionsView(options: $settings.character)
        }

        // Scattering
        if Feature.features.contains(where: { $0.hasScattering }) {
            Toggle("Scattering", isOn: $settings.scattering)
        }

        // Octopus
        if Feature.features.contains(.octopus) {
            OctopusOptions.View(options: $settings.octopus)
        }
    }
}
