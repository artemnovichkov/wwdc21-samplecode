/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A store that generates placeholder images of larger assets.
*/

import Foundation
import UniformTypeIdentifiers
import CoreGraphics
import os
import ImageIO

class PlaceholderStore: FileBasedCache {
    override init(directory: URL,
                  imageFormat: UTType = .jpeg,
                  logger: Logger = .default,
                  fileManager: FileManager = .default) {
        super.init(directory: directory, imageFormat: imageFormat, logger: logger, fileManager: fileManager)
        self.isPlaceholderStore = true
    }
    
    override func addByMovingFromURL(_ url: URL, forAsset id: Asset.ID) {
        self.downsample(from: url, to: self.url(forID: id))
    }
    
    func downsample(from sourceURL: URL, to destinationURL: URL) {
        signposter.withIntervalSignpost("PlaceholderDownsample", id: signposter.makeSignpostID()) {
            let readOptions: [CFString: Any] = [
                // Save the new image and don't retain any extra memory.
                kCGImageSourceShouldCache: false
            ]
        
            guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, readOptions as CFDictionary)
            else {
                self.logger.error("Could not make image source from \(sourceURL, privacy: .public)")
                return
            }
            
            let imageSize = sizeFromSource(source)
            
            let writeOptions = [
                // When the image data is read, only read the data that is needed.
                kCGImageSourceSubsampleFactor: subsampleFactor(maxPixelSize: 100, imageSize: imageSize),
                // When data is written, ensure the longest dimension is 100px.
                kCGImageDestinationImageMaxPixelSize: 100,
                // Compress the image as much as possible.
                kCGImageDestinationLossyCompressionQuality: 0.0
                // Merge the readOptions since `CGImageDestinationAddImageFromSource` is used
                // which both reads (makes a CGImage) and writes (saves to CGDestination).
            ].merging(readOptions, uniquingKeysWith: { aSide, bSide in aSide })
            
            guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL,
                                                                    imageFormat.identifier as CFString,
                                                                    1,
                                                                    writeOptions as CFDictionary)
            else {
                self.logger.error("Could not make image destination for \(destinationURL, privacy: .public)")
                return
            }
            CGImageDestinationAddImageFromSource(destination, source, 0, writeOptions as CFDictionary)
            CGImageDestinationFinalize(destination)
        }
    }
    
    func subsampleFactor(maxPixelSize: Int, imageSize: CGSize) -> Int {
        let largerDimensionMultiple = max(imageSize.width, imageSize.height) / CGFloat(maxPixelSize)
        let subsampleFactor = floor(log2(largerDimensionMultiple))
        return Int(subsampleFactor.rounded(.towardZero))
    }
    
    func sizeFromSource(_ source: CGImageSource) -> CGSize {
        let options: [CFString: Any] = [
            // Get the image's size without reading it into memory.
            kCGImageSourceShouldCache: false
        ]
                
        let properties = CGImageSourceCopyPropertiesAtIndex(
            source, 0, options as NSDictionary
        ) as? [String: CFNumber]
                
        let width = properties?[kCGImagePropertyPixelWidth as String] ?? 1 as CFNumber
        let height = properties?[kCGImagePropertyPixelHeight as String] ?? 1 as CFNumber
        
        return CGSize(width: Int(truncating: width), height: Int(truncating: height))
    }
}
