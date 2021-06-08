/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app delegate class that handles remote notifications and manages the local caches.
*/

import UIKit
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private var currentUserRecordID: CKRecord.ID?
    private(set) var zoneCacheOrNil: ZoneLocalCache?
    private(set) var topicCacheOrNil: TopicLocalCache?

    // If your iCloud container identifier isn't in the form "iCloud.<bundle identifier>",
    // use CKContainer(identifier: <your container ID>) to create the container.
    // An iCloud container identifier is case-sensitive and must begin with "iCloud.".
    let container = CKContainer.default()

    func application( _ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Observe .zoneCacheDidChange and .zoneDidSwitch to update the topic cache, if necessary.
        //
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.zoneCacheDidChange(_:)),
            name: .zoneCacheDidChange, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.zoneDidSwitch(_:)),
            name: .zoneDidSwitch, object: nil)

        // Register for remote notifications. The local caches rely on subscription notifications,
        // so you need to grant notifications when the system asks.
        //
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
            if let error = error {
                print("notificationCenter.requestAuthorization returns error: \(error)")
            }
            if granted != true {
                print("notificationCenter.requestAuthorization is not granted!")
            }
        }
        application.registerForRemoteNotifications()
        return true
    }
}

// MARK: - Handling CloudKit notifications
//
extension AppDelegate {
    private func updateWithNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let zoneCache = zoneCacheOrNil else {
            fatalError("\(#function): zoneCache shouldn't be nil")
        }
        
        // Only notifications with a subscriptionID are of interest in this sample.
        //
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              let subscriptionID = notification.subscriptionID else {
            return
        }
        
        // Use CKDatabaseSubscription to synchronize the changes. Note that it doesn't support the default zones.
        //
        if notification.notificationType == .database {
            if let cloudKitDB = zoneCache.cloudKitDB(with: subscriptionID) {
                zoneCache.fetchChanges(from: cloudKitDB)
            }
        }
    }
    
    func application( _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("\(#function)")
        updateWithNotificationUserInfo(userInfo)
        completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("\(#function)")
        updateWithNotificationUserInfo(notification.request.content.userInfo)
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("\(#function)")
        updateWithNotificationUserInfo(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    // Print the token if the app successfully registers for remote notifications.
    //
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("\(#function). Device token: \(deviceToken.base64EncodedString())")
    }

    // Report the error if the app fails to register for remote notifications.
    //
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("!!! didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
}

// MARK: - UISceneSession life cycle
//
extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - Coordinating local cache Changes
//
// AppDelegate acts as the coordinator to manage the life cycle of the local cache.
// Refresh the topic cache when zonesDidChange happens; and refresh the UI when there is no cache.
//
extension AppDelegate {
    // Create a topic cache for the first zone, or return nil if there is no zone.
    //
    private func topicCacheForFirstZone() -> TopicLocalCache? {
        if let (cloudKitDB, zone) = zoneCacheOrNil?.firstZone() {
            return TopicLocalCache(container: container, cloudKitDB: cloudKitDB, zone: zone)
        }
        return nil
    }
    
    // Nullify the user record ID and zone cache, and post zoneCacheDidChange to update the UI.
    //
    func invalidateCurrentUser() {
        currentUserRecordID = nil // Clear the current user record ID.
        guard zoneCacheOrNil != nil else {
            return
        }
        zoneCacheOrNil = nil
        NotificationCenter.default.post(name: .zoneCacheDidChange, object: nil)
    }
    
    // Build the cache for the specified user.
    // Do nothing if the user is the same as the current user.
    //
    func buildZoneCacheIfNeed(for userRecordID: CKRecord.ID?) -> Bool {
        guard currentUserRecordID != userRecordID else {
            return false
        }
        currentUserRecordID = userRecordID
        zoneCacheOrNil = ZoneLocalCache(container)
        return true
    }
    
    // The notification handler of .zoneCacheDidChange. Update the topic cache if it's stale.
    //
    @objc
    func zoneCacheDidChange(_ notification: Notification) {
        // zoneCacheOrNil == nil: The zone cache is invalid,
        // so invalidate topicCacheOrNil and post .topicCacheDidChange.
        //
        if zoneCacheOrNil == nil || zoneCacheOrNil?.firstZone() == nil {
            topicCacheOrNil = nil
            NotificationCenter.default.post(name: .topicCacheDidChange, object: nil)
            return
        }
        
        // If topicCache is nil, build it up with the first zone and set it to self.topicCache.
        // TopicLocalCache.fetchChanges triggers the UI update.
        // If the first zone doesn't exist, post to clear the UI immediately.
        //
        guard let topicCache = topicCacheOrNil else {
            topicCacheOrNil = topicCacheForFirstZone()
            if topicCacheOrNil == nil {
                NotificationCenter.default.post(name: .topicCacheDidChange, object: nil)
            }
            return
        }
        
        // The topic cache is ready, so grab the notification payload.
        //
        guard let zoneChanges = notification.userInfo?[UserInfoKey.zoneCacheChanges] as? ZoneCacheChanges else {
            return
        }
                        
        // If the current zone doesn't exist, move to the first zone, or clear the cache if no zone exists.
        // If topicCacheForFirstZone() returns nil because of no first zone,
        // use NotificationCenter.default to post .topicCacheDidChange to clear the UI immediately.
        //
        if zoneChanges.cloudKitDB.databaseScope == topicCache.cloudKitDB.databaseScope,
            zoneChanges.zoneIDsDeleted.contains(topicCache.zone.zoneID) {
            topicCacheOrNil = topicCacheForFirstZone()
            if topicCacheOrNil == nil {
                NotificationCenter.default.post(name: .topicCacheDidChange, object: nil)
            }
            return
        }

        // If the current zone has changes, fetch the changes.
        //
        if zoneChanges.cloudKitDB.databaseScope == topicCache.cloudKitDB.databaseScope,
            zoneChanges.zoneIDsChanged.contains(topicCache.zone.zoneID) {
            topicCache.fetchChanges()
            return
        }
    }
    
    @objc
    func zoneDidSwitch(_ notification: Notification) {
        guard let payload = notification.userInfo?[UserInfoKey.zoneSwitched] as? ZoneSwitched else {
            return
        }
        topicCacheOrNil = TopicLocalCache(container: container, cloudKitDB: payload.cloudKitDB, zone: payload.zone)
    }
}
