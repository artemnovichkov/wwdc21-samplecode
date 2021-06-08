# Simplifying User Authentication in a tvOS App

Build a fluid sign-in experience for your tvOS apps using AuthenticationServices.

## Overview

- Note: This sample code project is associated with WWDC21 session [10279: Simplify sign in for your tvOS apps](https://developer.apple.com/wwdc21/10279/).

## Configure the Sample Code Project

To configure the sample code project, perform the following steps in Xcode:

1) Add your Apple ID account and assign the target to a team so Xcode can enable the `Associated Domains` capability with your provisioning profile.
2) Configure your [web credentials domain](https://developer.apple.com/documentation/xcode/supporting-associated-domains) in the `Associated Domains` capability and your website's associated domains file.
3) Set up an Apple TV running tvOS 15 and an iPhone or iPad running iOS 15 or iPadOS 15.
4) Add the same Apple ID to both devices. Alternatively, you may [pair](https://support.apple.com/en-us/HT208088) the iPhone or iPad with the Apple TV.
5) Set the Apple TV as the run destination in the scheme pop-up menu.
6) In the toolbar, click Run, or choose Product > Run.
