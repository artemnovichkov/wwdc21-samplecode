/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Loads a poster image.
*/

import UIKit
import AVFoundation

class Poster {
    
    private let imageLoadingTimeout = 5.0
    
    private let url: URL
    private let time: CMTime
    
    private let imageURL: URL
    private var imageGenerator: AVAssetImageGenerator!
    
    init(url: URL, posterTime: TimeInterval) {
        self.url = url
        self.time = CMTime(seconds: posterTime, preferredTimescale: 1000)
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Build a local image URL in the Documents directory for the movie URL.
        imageURL = docsURL.appendingPathComponent("\(abs(url.hashValue))").appendingPathExtension("png")
    }
    
    func loadImage(completion: @escaping (UIImage?) -> Void) {
        if FileManager.default.fileExists(atPath: imageURL.path) {
            // The file already exists, load it from disk.
            completion(UIImage(contentsOfFile: imageURL.path)!)
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                var posterImage: UIImage?
                let posterTime = NSValue(time: self.time)
                let semaphore = DispatchSemaphore(value: 0)
                self.imageGenerator = AVAssetImageGenerator(asset: AVAsset(url: self.url))
                self.imageGenerator.generateCGImagesAsynchronously(forTimes: [posterTime]) { [weak self] _, image, _, _, _ in
                    guard let self = self else { return }
                    if let image = image {
                        let uiImage = UIImage(cgImage: image)
                        // Write the image to the Documents directory.
                        try? uiImage.pngData()?.write(to: self.imageURL)
                        posterImage = uiImage
                        semaphore.signal()
                    }
                }
                // Wait for up to imageLoadingTimeout seconds to generate a poster image.
                if semaphore.wait(timeout: .now() + self.imageLoadingTimeout) == .timedOut {
                    self.imageGenerator.cancelAllCGImageGeneration()
                }
                // Pass back the loaded image, or nil if the generator can't create it.
                completion(posterImage)
            }
        }
    }
}
