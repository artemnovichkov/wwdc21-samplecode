/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSButton subclass used in the comment popover for selecting a reaction.
*/

import Cocoa

class ReactionButton: NSButton {
    
    private let selectedReactionColor = NSColor.systemIndigo
    private let unselectedReactionColor = NSColor.systemGray
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // The button's image should retain its tint color even in off state.
        if let reactionButtonCell = cell as? NSButtonCell {
            reactionButtonCell.showsStateBy = []
            reactionButtonCell.highlightsBy = []
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let reactionButtonCell = cell as? NSButtonCell {
            super.draw(dirtyRect)
            
            let cornerRadius = frame.height / 2.0
            let roundedPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
            
            let fillColor = (state == .on) ? selectedReactionColor : unselectedReactionColor
            fillColor.set()
            roundedPath.fill()
            
            reactionButtonCell.drawImage(image!, withFrame: bounds, in: self)
        }
    }
}
