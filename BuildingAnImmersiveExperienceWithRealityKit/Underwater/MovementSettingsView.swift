/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Configurable flocking settings view.
*/

import SwiftUI

struct MovementSettingsView: View {

    @EnvironmentObject var settings: Settings

    var parameters: [ParameterView.Parameter] {
        [
            ("Separation Weight", $settings.separationWeight),
            ("Cohesion Weight", $settings.cohesionWeight),
            ("Alignment Weight", $settings.alignmentWeight),
            ("Hunger Weight", $settings.hungerWeight),
            ("Bonk Weight", $settings.bonkWeight),
            ("Fear", $settings.fearWeight),
            ("Top Speed", $settings.topSpeed),
            ("Max Steer", $settings.maxSteeringForce),
            ("Anim", $settings.animationScalar),
            ("Att", $settings.attractorWeight),
            ("Max Neighbor Dist", $settings.maxNeighborDistance),
            ("Desired Sep", $settings.desiredSeparation),
            ("Time Scale", $settings.timeScale),
            ("Angular speed (models)", $settings.angularModelSpeed)
        ].map { .init(id: $0.0, binding: $0.1) }
    }

    var body: some View {
        ForEach(parameters) { parameter in
            ParameterView(parameter: parameter)
            Spacer()
        }
        Toggle("Use angular inertia (models)", isOn: $settings.useAngularModelSpeed)
    }
}

struct FlockingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MovementSettingsView()
    }
}
