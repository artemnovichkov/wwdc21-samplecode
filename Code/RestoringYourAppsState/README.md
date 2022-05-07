# Restoring Your App's State

Provide continuity for the user by preserving current activities.

## Overview

This sample project demonstrates how to preserve your appʼs state information and restore the app to that previous state on subsequent launches. During a subsequent launch, restoring your interface to the previous interaction point provides continuity for the user, and lets them finish active tasks quickly.

When using your app, the user performs actions that affect the user interface. For example, the user might view a specific page of information, and after the user leaves the app, the operating system might terminate it to free up the resources it holds. The user should be able to return to where they left off — and UI state restoration is a core part of making that experience seamless.

This sample app demonstrates the use of state preservation and restoration for scenarios where the system interrupts the app. The sample project manages a set of products. Each product has a title, an image, and other metadata you can view and edit. The project shows how to preserve and restore a product in its `DetailParentViewController`.

The sample supports two state preservation approaches. In iOS 13 and later, apps save the state for each window scene using [`NSUserActivity`](https://developer.apple.com/documentation/foundation/nsuseractivity) objects. In iOS 12 and earlier, apps preserve the state of their user interfaces by saving and restoring the configuration of view controllers. 

For scene-based apps, UIKit asks each scene to save its state information using an [`NSUserActivity`](https://developer.apple.com/documentation/foundation/nsuseractivity) object. `NSUserActivity` is a core part of modern state restoration with [`UIScene`](https://developer.apple.com/documentation/uikit/uiscene) and [`UISceneDelegate`](https://developer.apple.com/documentation/uikit/uiscenedelegate). In your own apps, you use the activity object to store information needed to recreate your scene's interface and restore the content of that interface. If your app doesn't support scenes, use the view-controller-based state restoration process to preserve the state of your interface instead. 

For additional information about state restoration, see [Preserving Your App's UI Across Launches](https://developer.apple.com/documentation/uikit/view_controllers/preserving_your_app_s_ui_across_launches).

## Configure the Sample Code Project

In Xcode, select your development team on the iOS target's General tab.

## Enable State Preservation and Restoration

To provide the necessary activity object, the sample implements the [`stateRestorationActivity(for:)`](https://developer.apple.com/documentation/uikit/uiscenedelegate/3238061-staterestorationactivity) method of its scene delegate as shown in the example below. Implementing this method tells the system that the sample supports user-activity-based state restoration. The implementation of this method returns the activity object from the scene's [`userActivity`](https://developer.apple.com/documentation/uikit/uiresponder/1621089-useractivity) property, which the sample populates when the scene becomes inactive.

``` swift
func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
    return scene.userActivity
}
```

For view-controller-based state restoration, this sample opts in to state preservation and restoration using the app delegate’s [`application(_:shouldSaveApplicationState:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623089-application) and [` application(_:shouldRestoreApplicationState:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622987-application) methods. Both methods return a `Bool` value that indicates whether the step should occur. This sample returns `true` for both functions.

This example enables the preservation of state for the app:
``` swift
func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
    return true
}
```

This example enables the restoration of state for the app:
``` swift
func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
    return true
}
```

## Restore the App State with an Activity Object

Scene-based state restoration is the recommended way to restore the app’s user interface. An [`NSUserActivity`](https://developer.apple.com/documentation/foundation/nsuseractivity) object captures the app's state at the current moment in time. For this sample, the app preserves and restores the product information as the user displays or edits it. The sample app saves the product's data in an `NSUserActivity` object when the user closes the app or the app enters the background. When the user launches the app again, the sample's [`scene(_:willConnectTo:options:)`](https://developer.apple.com/documentation/uikit/uiscenedelegate/3197914-scene) method checks for the presence of an activity object. If one is present, the method configures the detail view controller that the activity object specifies.

## Restore the App State Using View Controllers

This sample preserves its state by saving the state of its view controller hierarchy. View controllers adopt the [`UIStateRestoring`](https://developer.apple.com/documentation/uikit/uistaterestoring) protocol, which defines methods for saving custom state information to an archive and restoring that information later.

The sample specifies which of its view controllers to save, and assigns a restoration identifier to that view controller. A restoration identifier is a string that UIKit uses to identify a view controller or other user interface element. The identifier for each view controller must be unique. The sample assigns the identifiers in Interface Builder, but this can aso occur in code.

The sample assigns a restoration ID for each view controller in the storyboard file. This information is available by selecting the view controller and looking at the Identity Inspector. The Storyboard ID for that view controller is usually the same as the Restoration ID.

This sample saves the state information in the detail view controller's [`encodeRestorableState(with:)`](https://developer.apple.com/documentation/appkit/nsresponder/1526236-encoderestorablestate) method, and it restores that state in the [`restoreState(with:)`](https://developer.apple.com/documentation/appkit/nsresponder/1526253-restorestate) method. Because it already encapsulates the view controller's state in an [`NSUserActivity`](https://developer.apple.com/documentation/foundation/nsuseractivity) object, the implementations of these methods operate on the existing activity object. The sample then calls the required `super` object from these methods, which allows UIKit to restore the rest of the view controller's inherited state.

This example enables the state preservation of `InfoViewController`:
``` swift
override func encodeRestorableState(with coder: NSCoder) {
    super.encodeRestorableState(with: coder)

    coder.encode(product?.identifier.uuidString, forKey: InfoViewController.restoreProductKey)
}
```

This example enables the state restoration of  `InfoViewController`:
``` swift
override func decodeRestorableState(with coder: NSCoder) {
    super.decodeRestorableState(with: coder)
    
    guard let decodedProductIdentifier =
        coder.decodeObject(forKey: InfoViewController.restoreProductKey) as? String else {
        fatalError("A product did not exist in the restore. In your app, handle this gracefully.")
    }
    product = DataModelManager.sharedInstance.product(fromIdentifier: decodedProductIdentifier)
}
```

## Test State Restoration on a Device

This sample restores the following user interface:

* Detail View Controller — Tap a product in the collection view to open its detail information. The app restores the selected product and selected tab.
* Detail View Controller's Edit State — In the detail view, tap Edit. The app restores the edit view and its content.
* Secondary Window — (iPad only) Drag a product from the collection view over to the left or right of the device screen to create a second scene window. The app restores that scene and its product. Another way to create the secondary window is to tap and hold a product from the collection view through its contextual menu and select Open New Window.

When debugging the sample project, the system automatically deletes its preserved state when the user force quits the app. Deleting the preserved state information is a safety precaution. In addition, the system also deletes the preserved state if this app crashes at launch time. To test the sample app’s ability to restore the sample's state, do not use the app switcher to force quit it during debugging. Instead, use Xcode to stop the app, or stop the app programmatically. One technique is to suspend the sample app using the Home button, and then stop the debugger in Xcode. Launch the sample app again using Xcode, and UIKit initiates the state restoration process.
