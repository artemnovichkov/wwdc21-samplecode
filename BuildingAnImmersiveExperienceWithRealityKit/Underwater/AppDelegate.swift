/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate.
*/

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FlockingSystem.registerSystem()
        MotionSystem.registerSystem()
        EatingSystem.registerSystem()
        AnimationSpeedSystem.registerSystem()
        WanderSystem.registerSystem()
        FearSystem.registerSystem()
        OctopusSystem.registerSystem()
        LevelOfDetailSystem.registerSystem()

        SettingsComponent.registerComponent()
        FlockingComponent.registerComponent()
        FlockLeader.registerComponent()
        AnimationSpeedComponent.registerComponent()
        MotionComponent.registerComponent()
        HungerComponent.registerComponent()
        AlgaeEaterComponent.registerComponent()
        PlanktonEaterComponent.registerComponent()
        FoodComponent.registerComponent()
        AlgaeComponent.registerComponent()
        PlanktonComponent.registerComponent()
        WanderAimlesslyComponent.registerComponent()
        FearComponent.registerComponent()
        ScaryComponent.registerComponent()
        SeaweedComponent.registerComponent()
        StarfishComponent.registerComponent()
        OctopusComponent.registerComponent()
        OctopusHidingLocationComponent.registerComponent()
        CameraComponent.registerComponent()
        LevelOfDetailComponent.registerComponent()

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

