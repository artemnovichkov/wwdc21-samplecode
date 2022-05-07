/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application delegate class.
*/

import UIKit

/** Important Note:
    With the application scene life cycle, UIKit no longer calls the following functions on the UIApplicationDelegate.
        applicationWillEnterForeground(_ application: UIApplication)
        applicationDidEnterBackground(_ application: UIApplication)
        applicationDidBecomeActive(_ application: UIApplication)
        applicationWillResignActive(_ application: UIApplication)
    These UISceneDelegate functions replace them:
        func sceneWillEnterForeground(_ scene: UIScene)
        func sceneDidEnterBackground(_ scene: UIScene)
        func sceneDidBecomeActive(_ scene: UIScene)
        func sceneWillResignActive(_ scene: UIScene)
 
    If you choose to use the app scene life cycle (opting in with UIApplicationSceneManifest in the Info.plist),
    but still deploy to iOS 12.x, you need both sets of delegate functions.
 */

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /** The app delegate must implement the window from UIApplicationDelegate
        protocol to use a main storyboard file.
    */
    var window: UIWindow?
        
    // MARK: - Application Life Cycle

    /** Tells the delegate the app controller has finished launching.
        Here you will do any one-time app data setup.
    */
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    /** iOS 12.x
        Tells the delegate that the app is about to enter the foreground.
        Equivalent API for scenes in UISceneDelegate: "sceneWillEnterForeground(_:)"
    */
    func applicationWillEnterForeground(_ application: UIApplication) {
        //..
    }
    
    /** iOS 12.x
        Tells the delegate that the app has become active.
        Equivalent API for scenes in UISceneDelegate:: "sceneDidBecomeActive(_:)"
    */
    func applicationDidBecomeActive(_ application: UIApplication) {
        //..
    }
    
    /** iOS 12.x
        Tells the delegate that the app is about to become inactive.
        Equivalent API for scenes in UISceneDelegate:: sceneWillResignActive(_:)
    */
    func applicationWillResignActive(_ application: UIApplication) {
        // Save any pending changes to the product list.
        DataModelManager.sharedInstance.saveDataModel()
    }
    
    /** iOS 12.x
        Tells the delegate that the app is now in the background.
        Equivalent API for scenes in UISceneDelegate:: sceneDidEnterBackground(_:)
    */
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save any pending changes to the product list.
        DataModelManager.sharedInstance.saveDataModel()
    }
    
    /** iOS 12.x
        Tells the delegate that the data for continuing an activity is available.
        Equivalent API for scenes is: scene(_:continue:)
    */
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return false // Not applicable here at the app delegate level.
    }
    
    // MARK: - Scene Configuration

    /** iOS 13 or later
        UIKit uses this delegate when it is about to create and vend a new UIScene instance to the application.
        Use this function to select a configuration to create the new scene with.
        You can define the scene configuration in code here, or define it in the Info.plist.
     
        The application delegate may modify the provided UISceneConfiguration within this function.
        If the UISceneConfiguration instance that returns from this function does not have a systemType
        that matches the connectingSession's, UIKit asserts.
    */
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        var sceneConfig = connectingSceneSession.configuration
        
        // Find the user activity, if available, to create the scene configuration.
        var currentActivity: NSUserActivity?
        options.userActivities.forEach { activity in
            currentActivity = activity
        }
        if currentActivity != nil {
            if currentActivity!.activityType == ImageSceneDelegate.ImageSceneActivityType() {
                sceneConfig = UISceneConfiguration(name: "Second Scene", sessionRole: .windowApplication)
            }
        }
        return sceneConfig
    }
    
    /** iOS 13 or later
        The system calls this delegate when it removes one or more representations from the -[UIApplication openSessions] set
        due to a user interaction or a request from the app itself. If the system discards sessions while the app isn't running,
        it calls this function shortly after the app’s next launch.
     
        Use this function to:
        Release any resources that were specific to the discarded scenes, as they will NOT return.
        Remove any state or data associated with this session, as it will not return (such as, unsaved draft of a document).
    */
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        //..
    }

}

// MARK: - State Restoration

extension AppDelegate {

    // For non-scene-based versions of this app on iOS 13.1 and earlier.
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    // For non-scene-based versions of this app on iOS 13.1 and earlier.
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    @available(iOS 13.2, *)
    // For non-scene-based versions of this app on iOS 13.2 and later.
    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    @available(iOS 13.2, *)
    // For non-scene-based versions of this app on iOS 13.2 and later.
    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
}
