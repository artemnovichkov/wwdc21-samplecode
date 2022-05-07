# Creating an Audio Device Driver
Create a configurable audio input source as a driver extension that runs in user space.

## Overview

- Note: This sample code project is associated with WWDC21 session [10190: Create Audio Drivers with DriverKit](https://developer.apple.com/wwdc21/10190/).

This sample shows how to create an audio driver extension using the AudioDriverKit framework. The sample provides a C++ DriverKit implementation to publish a single input audio device, input stream, volume control, and a data source selector control. 

The sample implements a dynamic environment that can support multiple audio devices and any other audio objects the AudioDriverKit framework provides. The audio device provides the following features:

* Configurable input device volume.
* Sine tone generator for the input stream's I/O buffer.
* Sine tone frequency data source selector control.
* 44.1 and 48 kHz sample rates.
* Mono channel of audio I/O in 16-bit, linear PCM format.
* Example of a string based custom property.

The project provides a sample application that can install and activate the audio driver extension. The sample application also connects to the audio driver extension through a custom user client connection.  The custom user client shows an example of how to change the data source selector value directly on the audio driver extension.

## Configure the Sample Code Project

To activate the sample driver, you need to create an explicit App ID and provisioning profile with the following entitlements:

- `com.apple.developer.driverkit`
- `com.apple.developer.driverkit.allow-any-userclient-access`

The sample app also needs an explicit App ID and provisioning profile with the following entitlements:

- `com.apple.developer.driverkit`

For information on how to perform this configuration, see [Requesting Entitlements for DriverKit Development][1].

To bypass this configuration and use ad hoc signing to test the driver in your local development environment, perform the following steps:
1. Disable System Integrity Protection (SIP) on your system so it recognizes ad hoc-signed DriverKit extensions. For more information, see [Disabling and Enabling System Integrity Protection][2].
2. Configure the `SimpleAudioDriver` and `SimpleAudio`  targets to use local signing. Select each target, and then select its "Build Settings" tab. Find the "Code Signing Identity" build setting and select "Sign to Run Locally".

Build the `SimpleAudio` target, then copy the app to the Applications folder and launch the app. Press "Install Driver". If you are prompted with a "System Extension Blocked" dialog, open System Preferences and go to the Security & Privacy pane. Unlock the pane if necessary, and click “Allow” to complete the installation. After approving the app for use on your Mac, the audio device is available to Core Audio. To inspect the newly installed device, use the Audio MIDI Setup app (`Applications/Utilities`).

To uninstall the driver, return to the sample app and click "Remove Driver". You can also uninstall the driver by deleting the sample app, which also stops and removes the dext.

[1]:	https://developer.apple.com/documentation/driverkit/requesting_entitlements_for_driverkit_development "A link to the Requesting Entitlements for DriverKit Development article."
[2]:	https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection "A link to the Disabling and Enabling System Integrity Protection article."
