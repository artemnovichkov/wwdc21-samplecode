# Synchronizing a Local Store to the Cloud

Share data between a user’s devices and other iCloud users.

## Overview

- Note: This sample code project is associated with the WWDC21 session [10015: Build Apps that Share Data Through CloudKit and Core Data ](https://developer.apple.com/videos/play/wwdc2021/10015/).

## Configure the Sample Code Project

Before you run the sample code project in Xcode:

1. Set your bundle identifier. 
    - Select the CoreDataCloudKitDemo project.
    - Select the General tab.
    - In the Identity section, set the Bundle Identifier to your reverse domain name followed by the project name.  
2. Set your development team.
    - Select the CoreDataCloudKitDemo project
        - Select the Signing & Capabilities tab.
        - Select your development team from the dropdown list.
3. Update the product bundle identifier for the test targets. 
    - Select the CoreDataCloudKitDemoUnitTests target.
        - Select the Signing & Capabilities tab.
        - Select your development team from the dropdown list.
        - Select the Build Settings Tab.
        - Find product bundle identifier and change it to a value appropriate for your team.

## Configuration Options

To facilitate testing the application supports the following configuration options parsed in to properties by the `AppDelegate` class:

- `-CDCKDTesting`
    - Set to `1` to store files in a special directory, `TestStores`, so that tests do not overwrite user data.
- `-CDCKDAllowCloudKitSync`
    - Set to `0` to disable CloudKit sync during testing
- `com.apple.CoreData.ConcurrencyDebug`
    - Enables Core Data multi-threading assertions to verify the correct queue is used for all Core Data operations.
