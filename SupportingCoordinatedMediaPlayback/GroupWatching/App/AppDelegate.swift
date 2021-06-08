/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's delegate object.
*/

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        do {
            // Configure the audio session for movie playback.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Unable to set the audio session category: \(error)")
        }
        
        return true
    }
}

