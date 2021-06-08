# Selecting Photos and Videos in iOS
Improve the user experience of finding and selecting assets by using the Photos picker.


## Overview
This sample shows how to use the [`PhotoKit`][10] Photos picker, and illustrates how to filter assets according to the user's selection. After you have a selection, you use an item provider to load the asset to display in the app. The sample also explores the new configuration options in iOS 15. 

- Note: This sample code project is associated with WWDC21 session [10046: Improve access to Photos in your app](https://developer.apple.com/videos/play/wwdc21/10046/).

## Understand the Photos Picker Benefits 
Both [`PHPickerViewController`][7] and [`UIImagePickerController`][8] use the out-of-process Photos picker user interface. The `PHPickerViewController` contains a powerful set of APIs that make it a great alternative to `UIImagePickerController`. `PHPickerViewController` improves stability and reliability, and includes several benefits to developers and users, such as the following:

- Deferred image loading and recovery UI
- Reliable handling of large and complex assets, like RAW and panoramic images
- User-selectable assets that aren't available for `UIImagePickerController`
- Configuration of the picker to only display Live Photos
- Availability of [`PHLivePhoto`][9] objects without library access
- Stricter validations against invalid inputs

Apps don't need to request photo library permission when using either class, so the sample app avoids requesting permission until it's necessary. A camera app, photo editing app, or library browsing app needs to use much more of [`PhotoKit`][10]'s functionality, but an app that's only setting a basic profile photo doesn't need photo library permission. An app that only saves photos to the photo library can use the Add Photos Only permission level when requesting authorization.

## Configure the Photos Picker
Before displaying the photo library, the sample creates a [`PHPickerConfiguration`][11] object using the shared photo library. Creating a configuration without a photo library provides only asset data, and doesn't include asset identifiers.

``` swift
var configuration = PHPickerConfiguration(photoLibrary: .shared())
```
[View in Source][13]

The picker displays all asset types by default. A filter configures the picker to display videos, images with live photos, or live photos only. The sample contains three buttons that reflect the available filter types. 

An app creates custom filters by combining filter options. For example, the following code displays live photos and videos:

```swift
var newFilter = PHPickerFilter.any(of: [.livePhotos, .videos])
```

A new feature in iOS 15 is the capability to change the selection behavior. The sample sets the selection property to `ordered`, which places a numbered checkmark when selecting items, and disables swipe to select. 

The preselection API allows for presenting the picker with selected photos. This gives the user the opportunity to select more photos, or to deselect preselected photos.

``` swift
// Set the filter type according to the user’s selection.
configuration.filter = filter
// Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
configuration.preferredAssetRepresentationMode = .current
// Set the selection behavior to respect the user’s selection order.
configuration.selection = .ordered
// Set the selection limit to enable multiselection.
configuration.selectionLimit = 0
// Set the preselected asset identifiers with the identifiers that the app tracks.
configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
```
[View in Source][13]

## Display a Picker with the Configuration
The sample creates and displays the picker using the configuration object. Displaying the photo library doesn't need user permission because it's running in a separate process. An app can't take screenshots of content and can only read the assets that the user selects. 

``` swift
let picker = PHPickerViewController(configuration: configuration)
picker.delegate = self
present(picker, animated: true)
```
[View in Source][13]

Apps are responsible for presenting and dismissing the photo library. The sample adopts to the photo library delegate that notifies the app when the user cancels the flow. 

See [Delivering a Great Privacy Experience in Your Photos App][1] to learn more about requesting authorization and limited library capabilities.


## Retrieve the Selected Results
When completing a picker session, the delegate provides a list of result objects that contain an item provider that allows for loading data asynchronously. The results contain local identifiers because of initializing the configuration with a photo library.

The sample stores the selected asset identifiers to preload them when displaying the photo library again.

``` swift
let existingSelection = self.selection
var newSelection = [String: PHPickerResult]()
for result in results {
    let identifier = result.assetIdentifier!
    newSelection[identifier] = existingSelection[identifier] ?? result
}

// Track the selection in case the user deselects it later.
selection = newSelection
selectedAssetIdentifiers = results.map(\.assetIdentifier!)
selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()

if selection.isEmpty {
    displayEmptyImage()
} else {
    displayNext()
}
```
[View in Source][5]


## Fetch Selected Asset Data for Display
An item provider gives an app the ability to load assets asynchronously and on demand. Before loading an object, the sample verifies that the object is available.

An item provider also allows for progress reporting. An asset may not be available on-device if iCloud Photos and Optimize Storage aren't active. In this case, it can take some time to download a large asset. An item provider returns a [`Progress`][12] object that conveys ongoing progress to an app.

``` swift
guard let assetIdentifier = selectedAssetIdentifierIterator?.next() else { return }
currentAssetIdentifier = assetIdentifier

let progress: Progress?
let itemProvider = selection[assetIdentifier]!.itemProvider
if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
    progress = itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
        DispatchQueue.main.async {
            self?.handleCompletion(assetIdentifier: assetIdentifier, object: livePhoto, error: error)
        }
    }
}
```
[View in Source][6]


## Load Asset Metadata
Retrieving metadata for an asset doesn't require special permission. An app can get the properties after loading an object from an item provider. However, it may not include all properties because of the transcoding process. 

The following code retrieves the property list by checking that the item provider conforms to an image type identifier. After confirming, it loads the data representation of an asset, which avoids losing information from transcoding, and allows for better metadata retrieval.


```swift
if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
    itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
        guard let data = data,
              let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) else { return }
        print(properties)
    }
}
```

[1]: https://developer.apple.com/documentation/photokit/delivering_a_great_privacy_experience_in_your_photos_app
[2]: x-source-tag://CreatePickerConfiguration
[3]: x-source-tag://ConfigurePicker
[4]: x-source-tag://CreatePickerController
[5]: x-source-tag://ParsePickerResults
[6]: x-source-tag://LoadItemProvider
[7]: https://developer.apple.com/documentation/photokit/phpickerviewcontroller
[8]: https://developer.apple.com/documentation/uikit/uiimagepickercontroller
[9]: https://developer.apple.com/documentation/photokit/phlivephoto
[10]: https://developer.apple.com/documentation/photokit
[11]: https://developer.apple.com/documentation/photokit/phpickerconfiguration
[12]: https://developer.apple.com/documentation/foundation/progress
[13]: x-source-tag://PresentPicker
