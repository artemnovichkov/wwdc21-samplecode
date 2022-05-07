/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UILabel subclass for adding a round corner rectangle border for the label text.
*/

import UIKit

class TagLabel: UILabel {
    static func sizeOf(text: String, font: UIFont) -> CGSize {
        guard !text.isEmpty else { return CGSize(width: 0, height: 0) }
        
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        return CGSize(width: textSize.width + textSize.height, height: textSize.height)
    }
    
    override func drawText(in drawRect: CGRect) {
        let rect = drawRect.insetBy(dx: 1, dy: 1)
        defer { super.drawText(in: drawRect) }
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let minx = rect.minX, maxx = rect.maxX
        let miny = rect.minY, midy = rect.midY, maxy = rect.maxY
        let width = maxx - minx, height = maxy - miny
        
        guard width > height else { return }
        
        let radius = height / 2
        context.addArc(center: CGPoint(x: minx + radius, y: midy), radius: radius,
                       startAngle: 3 * .pi / 2, endAngle: .pi / 2, clockwise: true)
        context.addArc(center: CGPoint(x: maxx - radius, y: midy), radius: radius,
                       startAngle: .pi / 2, endAngle: 3 * .pi / 2, clockwise: true)
        
        context.closePath()
        context.setStrokeColor(textColor.cgColor)
        context.drawPath(using: .stroke)
    }
    
    override var intrinsicContentSize: CGSize {
        guard let string = text, !string.isEmpty else { return CGSize(width: 0, height: 0) }
        return TagLabel.sizeOf(text: string, font: font)
    }
}
