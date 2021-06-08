# Implementing a Store In Your App Using the StoreKit API

Offer in-app purchases and manage entitlements using signed transactions and status information.

## Overview

- Note: This sample code project is associated with WWDC21 session [5011: Meet StoreKit 2](https://developer.apple.com/wwdc21/5011/).

## Configure the Sample Code Project

This sample code project uses StoreKit Testing in Xcode so you can build and run the sample app without completing any setup in App Store Connect. The project defines in-app products for the StoreKit Testing server in the `Products.storekit` file. The project includes the `Products.plist` as a resource file, which contains product identifiers mapped to emoji characters.

By default, StoreKit testing in Xcode is disabled. Follow these steps to select the `Products.storekit` configuration file and enable StoreKit testing in Xcode:
1. Click the scheme to open the scheme menu; choose Edit Scheme.
2. In the scheme editor, choose the Run action.
3. Click Options in the action settings.
4. For the StoreKit Configuration option, select the `Products.storekit` configuration file.

When the app initializes a store, the system reads `Products.plist` and uses the product identifiers to request products from the StoreKit testing server.
