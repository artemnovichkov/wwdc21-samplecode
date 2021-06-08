# Using MusicKit to Integrate with Apple Music

Find an album in Apple Music that corresponds to a CD in a user's collection, and present the information associated with the album.

## Overview

- Note: This sample code project is associated with WWDC21 session [10294: Meet MusicKit for Swift](https://developer.apple.com/wwdc21/10294/).

## Configure the Sample Code Project

This sample code project must be run on a physical device.

Before you run the sample code project in Xcode:

1. In the project navigator, select the project and go to the Signing & Capabilities tab.
2. Select your own developer team from the Team popup menu.
3. Choose a new bundle identifier for the `MusicAlbums` target, and enter it in the Bundle Identifier field. The bundle identifier within the project has an associated App ID, so you need a unique identifier to create your own App ID. Use a reverse-DNS format for your identifier, as described in [Preparing Your App For Distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution).
4. In Safari, visit the [Certificates, Identifiers, and Profiles](https://developer.apple.com/account/resources) section of the developer web site.
5. Select Identifiers and click the "+" button to create a new App ID for `MusicAlbums`. Follow the steps until you reach the "Register an App ID" page.
6. For the Bundle ID, select "explicit", and enter the bundle identifier you chose in step 2.
7. Select the App Services tab, and check the box next to MusicKit. There is no need to add any capabilities from the Capabilities tab.
8. Complete the App ID creation process.

Once your App ID is created, your Xcode project needs no additional configuration. The MusicKit App Service is a run-time service that is automatically associated with your app's bundle ID.
