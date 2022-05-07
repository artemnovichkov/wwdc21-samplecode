/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A layer subclass that highlights text.
*/

import Cocoa
import QuartzCore

class AnnotationLayer: CALayer {
    var results: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textFilter: String = "" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(in ctx: CGContext) {
        guard !results.isEmpty else {
            opacity = 0.0
            return
        }
        
        // Fill the clip bounds with an opaque overlay.
        ctx.setFillColor(CGColor.black)
        let clipBounds = ctx.boundingBoxOfClipPath
        ctx.fill(clipBounds)
        
        ctx.saveGState()
        
        // Highlight the result boxes.
        ctx.setFillColor(CGColor.white)
        let width = bounds.size.width
        let height = bounds.size.height
        let cgPath = CGMutablePath()
        for ((pt1, pt2, pt3, pt4), string) in self.results {
            if textFilter.isEmpty || string.contains(textFilter) {
                cgPath.move(to: CGPoint(x: pt1.x * width, y: pt1.y * height))
                cgPath.addLine(to: CGPoint(x: pt2.x * width, y: pt2.y * height))
                cgPath.addLine(to: CGPoint(x: pt3.x * width, y: pt3.y * height))
                cgPath.addLine(to: CGPoint(x: pt4.x * width, y: pt4.y * height))
                cgPath.addLine(to: CGPoint(x: pt1.x * width, y: pt1.y * height))
                
            }
        }
        
        ctx.addPath(cgPath)
        ctx.fillPath()
        
        ctx.addPath(cgPath)
        
        ctx.setLineWidth(2.0)
        ctx.setStrokeColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        ctx.strokePath()
        
        ctx.restoreGState()
        
        opacity = 0.5
    }
}

