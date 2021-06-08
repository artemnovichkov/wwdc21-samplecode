# Adopting New Safari Web Extension APIs

Improve your web extension in Safari with a non-persistent background page and new tab-override customization.

## Overview

- Note: This sample code project is associated with WWDC21 sessions [10027: Explore Safari Web Extension Improvements](https://developer.apple.com/wwdc21/10027/); and [10104: Meet Safari Web Extensions on iOS](https://developer.apple.com/wwdc21/10104/).

## Configure the Sample Code Project

Before you run the sample code project in Xcode:

On macOS:
1. Open Safari and choose Develop > Allow Unsigned Extensions.
2. In the project settings in Xcode, select the Sea Creator (macOS) target.
3. Click the Signing & Capabilities tab.
4. For Signing Certificate, choose Sign to Run Locally. (Leave Team set to None.)
5. Repeat steps 3 and 4 for the Sea Creator Extension (macOS) target.

On iOS, to run on a device:
1. In the project settings in Xcode, select the Sea Creator (iOS) target.
2. Click the Signing & Capabilities tab.
3. Select a development team.
4. Repeat the above steps for the Sea Creator Extension (iOS) target.
