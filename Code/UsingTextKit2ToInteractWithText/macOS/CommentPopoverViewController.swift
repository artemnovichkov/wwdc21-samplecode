/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSViewController subclass that contains the content for the comment popover.
*/

import Cocoa

class CommentPopoverViewController: NSViewController, NSPopoverDelegate {
    
    var documentViewController: TextDocumentViewController! = nil
    
    @IBOutlet private var commentField: NSTextField!
    
    private var selectedReaction: Reaction = .thumbsUp
    private let reactionAttachmentColor = NSColor.systemYellow
    
    private func imageForAttachment(with reaction: Reaction) -> NSImage {
        let symbolImageForReaction = NSImage(systemSymbolName: reaction.symbolName, accessibilityDescription: reaction.accessibilityLabel)!
        let reactionConfig = NSImage.SymbolConfiguration(textStyle: .title3, scale: .large)
        return symbolImageForReaction.withSymbolConfiguration(reactionConfig)!
    }
    
    func attributedString(for reaction: Reaction) -> NSAttributedString {
        let reactionAttachment = NSTextAttachment()
        reactionAttachment.image = imageForAttachment(with: reaction)
        let reactionAttachmentString = NSMutableAttributedString(attachment: reactionAttachment)
        // Add the foreground color attribute so the symbol icon renders with the reactionAttachmentColor (yellow).
        reactionAttachmentString.addAttribute(.foregroundColor, value: reactionAttachmentColor,
                                              range: NSRange(location: 0, length: reactionAttachmentString.length))
        return reactionAttachmentString
    }
    
    // Creating the comment.
    func attributedComment(_ comment: String, with reaction: Reaction) -> NSAttributedString {
        let reactionAttachmentString = attributedString(for: reaction)
        let commentWithReaction = NSMutableAttributedString(string: comment + " ")
        commentWithReaction.append(reactionAttachmentString)
        return commentWithReaction
    }
    
    // Text field handling, the user typed return or enter.
    @IBAction func returnPressed(_ sender: Any) {
        if !commentField.stringValue.isEmpty && selectedReaction != .none {
            let attributedCommentWithReaction = attributedComment(commentField.stringValue, with: selectedReaction)
            documentViewController.addComment(attributedCommentWithReaction)
            commentField.resignFirstResponder()
            dismiss(self)
        } else {
            // The comment data is not fully determined.
        }
    }
    
    func buttonForReaction(_ reaction: Reaction) -> NSButton? {
        if let button = view.viewWithTag(reaction.rawValue) as? NSButton {
            return button
        } else {
            return nil
        }
    }
    
    // Reaction button handling.
    @IBAction func reactionChanged(_ sender: NSButton) {
        let newReaction = Reaction(rawValue: sender.tag)
        let oldReaction = selectedReaction

        if newReaction != oldReaction {
            if let oldReactionButton = buttonForReaction(oldReaction) {
                // Toggle the old reaction button state.
                oldReactionButton.state = .off
            }
            selectedReaction = newReaction!
         } else {
             // User toggled the current reaction button to off.
             selectedReaction = .none
         }
    }
    
}
