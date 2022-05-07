# Connecting to a Service with Passkeys

Allow users to sign in to a service without typing a password.

## Overview

- Note: This sample code project is associated with WWDC21 session [10106: Move Beyond Passwords](https://developer.apple.com/wwdc21/10106/).

## Configure the Sample Code Project

To build and run this sample on your device:
1. Open the sample with Xcode 13 or later.
2. Select the Shiny project.
3. For the project's target, choose your team from the Team drop-down menu in the Signing & Capabilities pane to let Xcode automatically manage your provisioning profile.
4. Add the Associated Domains capability, and specify your domain with the `webcredentials` service.
5. Ensure an `apple-app-site-association` (AASA) file is present on your domain, in the `.well-known` directory, and it contains entry for this app's App ID for the `webcredentials` service.
6. In the `AccountManager.swift` file, replace all occurrances of `example.com` with the name of your domain.
7. Turn on the Syncing Platform Authenticator setting on your iOS device in Settings > Developer. If you're running the Catalyst app on macOS, select Enable Syncing Platform Authenticator in Safari's Develop menu.
