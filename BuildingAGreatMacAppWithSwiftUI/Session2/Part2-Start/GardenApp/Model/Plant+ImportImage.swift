/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The plant extension to support importing an image.
*/

import AppKit
import Foundation
import UniformTypeIdentifiers

extension Plant {
    static var importImageTypes = NSImage.imageTypes.compactMap { UTType($0) }

    /// Extracts image data from the given item providers, and saves the image to disk.
    /// The specified closure will be called with the URL for the extracted image file if successful.
    ///
    /// Note: because this method uses `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`
    /// internally, it is currently not marked as `async`.
    static func importImageFromProviders(_ itemProviders: [NSItemProvider], completion: @escaping (URL?) -> Void) -> Bool {
        guard let provider = itemProviders.first else { return false }
        for type in importImageTypes {
            let typeIdentifier = type.identifier
            if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
                    guard let data = data, let directoryURL = imageDirectory()
                    else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    do {
                        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                        var imageURL = directoryURL.appendingPathComponent(UUID().uuidString)
                        if let fileExtension = type.preferredFilenameExtension {
                            imageURL.appendPathExtension(fileExtension)
                        }
                        try data.write(to: imageURL)
                        DispatchQueue.main.async {
                            completion(imageURL)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

private func imageDirectory() -> URL? {
    guard var result = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask).first
    else { return nil }
    result.appendPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
    result.appendPathComponent("images", isDirectory: true)
    return result
}
