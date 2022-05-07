/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility method on UIImage to allow getting the effective arverage average color of an image
*/

import UIKit

extension UIImage {
    
    /// A cached CIContext for downsampling because they can be expensive to create
    static private let ciContext = CIContext(options: [.workingColorSpace: NSNull()])

    /// The average color of all of the image's pixels, including alpha.
    var downsampledColor: UIColor? {
        guard let inputImage = CIImage(image: self) else {
            Swift.debugPrint("Failed to initialize CIImage from UIImage")
            return nil
        }
        let inputExtent = CIVector(x: inputImage.extent.origin.x,
                                   y: inputImage.extent.origin.y,
                                   z: inputImage.extent.size.width,
                                   w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent]) else {
            Swift.debugPrint("Failed to create Core Image CIAreaAverage filter")
            return nil
        }
        guard let outputImage = filter.outputImage else {
            Swift.debugPrint("Failed to process image with filter")
            return nil
        }
        var bitmap = [UInt16](repeating: 0, count: 4)
        UIImage.ciContext.render(outputImage,
                                 toBitmap: &bitmap,
                                 rowBytes: 8,
                                 bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                                 format: .RGBA16,
                                 colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / CGFloat(UInt16.max),
                       green: CGFloat(bitmap[1]) / CGFloat(UInt16.max),
                       blue: CGFloat(bitmap[2]) / CGFloat(UInt16.max),
                       alpha: CGFloat(bitmap[3]) / CGFloat(UInt16.max))
    }
}
