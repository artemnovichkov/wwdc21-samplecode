/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate class.
*/

import UIKit

extension UIApplication {
    
    /** The activityTypes are included in your Info.plist file under the `NSUserActivityTypes` array.
        More info: https://developer.apple.com/documentation/foundation/nsuseractivity
    */
    static var userActivitiyTypes: [String]? {
        return Bundle.main.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String]
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}
