/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Heuristical methods for rendering emoji as images. Note that this code is not guaranteed to fit all emoji into the drawn image.
*/

import UIKit

extension String {
    func image(textStyle: UIFont.TextStyle = .body) -> UIImage? {
        if let image = UIImage(named: self) {
            return image
        }
        if let image = UIImage(systemName: self) {
            return image
        }
        let pointSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        
        // Hueristic to fit the wider emoji like flags
        let padding: CGFloat = 0.35 * pointSize
        let paddedScaledSize = CGSize(width: pointSize + padding, height: pointSize + padding)
        let render = UIGraphicsImageRenderer(size: paddedScaledSize)
        return render.image { context in
            
            let rect = CGRect(origin: .init(x: 0, y: 0), size: paddedScaledSize)

            (self as NSString).draw(in: rect, withAttributes: [.font: UIFont.preferredFont(forTextStyle: textStyle)])
        }
    }
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    var isSingleEmoji: Bool { count == 1 && containsEmoji }
    
    var containsEmoji: Bool { contains { $0.isEmoji } }
}
