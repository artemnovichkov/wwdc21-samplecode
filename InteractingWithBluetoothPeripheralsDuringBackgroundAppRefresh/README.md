# Interacting with Bluetooth Peripherals During Background App Refresh

Keep your complications up-to-date by reading values from a Bluetooth peripheral while your app is running in the background.

## Overview

- Note: This sample code project is associated with WWDC21 session [10005: Connecting Bluetooth Devices with Apple Watch](https://developer.apple.com/wwdc21/10005/).

## Configure the Sample Code Project

This sample only runs on physical devices.

This project contains 2 targets: *BARBluetooth* for iOS and *BARBluetooth WatchKit App* for watchOS. To get started:

1. Select the BARBluetooth target, then change the bundle ID to <Your iOS app bundle ID>. Select the right team to let Xcode automatically manage your provisioning profile.
2. Repeat step 1 for the WatchKit app and WatchKit Extension target. The bundle IDs should be <Your iOS app bundle ID>.watchkitapp and <Your iOS app bundle ID>.watchkitapp.watchkitextension respectively.
3. Next, for the WatchKit app target, select the Info tab, and change the value of WKCompanionAppBundleIdentifier key to <Your iOS app bundle ID>.
4. Finally, open the Info.plist file of the WatchKit Extension target, navigate to NSExtension > NSExtensionAttributes > WKAppBundleIdentifier key, and change the value of the key to <Your iOS app bundle ID>.watchkitapp.
4. Build and run the app on both Apple watch and iPhone.
5. On the phone, allow Bluetooth access in Settings->Privacy->Bluetooth->BARBluetooth and run the app.
6. On the watch, add the BARBluetooth widget to the active watch face.
7. On the watch, select the bluetooth peripheral (the phone) to connect to it.

The watch app reads a characteristic value from the phone and updates the complication during background runtime.
