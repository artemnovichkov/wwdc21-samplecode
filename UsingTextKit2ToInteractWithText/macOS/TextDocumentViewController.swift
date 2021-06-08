/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Primary NSViewController subclass for the sample's Document.
*/

import Cocoa

class TextDocumentViewController: NSViewController, NSTextContentManagerDelegate, NSTextContentStorageDelegate {

    private var textContentStorage: NSTextContentStorage
    private var textLayoutManager: NSTextLayoutManager
    private var fragmentForCurrentComment: NSTextLayoutFragment?
    private var showComments = true
    var commentColor: NSColor { return .white }
    
    @IBOutlet private weak var toggleCommentsButton: NSButton!
    @IBOutlet private weak var textDocumentView: TextDocumentView!

    required init?(coder: NSCoder) {
        textLayoutManager = NSTextLayoutManager()
        textContentStorage = NSTextContentStorage()
        super.init(coder: coder)
        textContentStorage.delegate = self
        textContentStorage.addTextLayoutManager(textLayoutManager)
        let textContainer = NSTextContainer(size: NSSize(width: 200, height: 0))
        textLayoutManager.textContainer = textContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if textContentStorage.textStorage!.length == 0 {
            if let docURL = Bundle.main.url(forResource: "menu", withExtension: "rtf") {
                do {
                    try textContentStorage.textStorage?.read(from: docURL, documentAttributes: nil, error: ())
                } catch {
                    // Could not read menu content.
                }
            }
        }
        textDocumentView.textContentStorage = textContentStorage
        textDocumentView.textLayoutManager = textLayoutManager
        textDocumentView.updateContentSizeIfNeeded()
        textDocumentView.documentViewController = self
    }
    
    // Commenting.
    @IBAction func toggleComments(_ sender: NSButton) {
        showComments = (sender.state == .on)
        textDocumentView.layer?.setNeedsLayout()
    }
    
    func addComment(_ comment: NSAttributedString) {
        textDocumentView.addComment(comment, below: fragmentForCurrentComment!)
        fragmentForCurrentComment = nil
    }
    
    var commentFont: NSFont {
        var commentFont = NSFont.preferredFont(forTextStyle: .title3, options: [:])
        let commentFontDescriptor = commentFont.fontDescriptor.withSymbolicTraits(.italic)
        commentFont = NSFont(descriptor: commentFontDescriptor, size: commentFont.pointSize)!
        return commentFont
    }
    
    // Debug UI.
    @IBAction func toggleLayerFrames(_ sender: NSButton) {
        // Turn on/off viewing layer frames.
        textDocumentView.showLayerFrames = (sender.state == .on)
        textDocumentView.layer?.setNeedsLayout()
    }
    @IBAction func toggleSlowAnimation(_ sender: NSButton) {
        // Turn on/off slow animation of each layer.
        textDocumentView.slowAnimations = (sender.state == .on)
    }
    
    // Popover management.
    func showCommentPopover(for layoutFragment: NSTextLayoutFragment) {
        fragmentForCurrentComment = layoutFragment
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let popoverVC = storyboard.instantiateController(withIdentifier: "CommentPopoverViewController") as? CommentPopoverViewController {
            popoverVC.documentViewController = self
            present(popoverVC, asPopoverRelativeTo: layoutFragment.layoutFragmentFrame,
                    of: textDocumentView,
                    preferredEdge: .maxY, behavior: .transient)
        }
    }
    
    // MARK: - NSTextContentManagerDelegate
    
    func textContentManager(_ textContentManager: NSTextContentManager,
                            shouldEnumerate textElement: NSTextElement,
                            with options: NSTextElementProviderEnumerationOptions) -> Bool {
        // The text content manager calls this method to determine whether each text element should be enumerated for layout.
        // To hide comments, tell the text content manager not to enumerate this element if it's a comment.
        if !showComments {
            if let paragraph = textElement as? NSTextParagraph {
                let commentDepthValue = paragraph.attributedString.attribute(.commentDepth, at: 0, effectiveRange: nil)
                if commentDepthValue != nil {
                    return false
                }
            }
        }
        return true
    }
    
    // MARK: - NSTextContentStorageDelegate
    
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        // In this method, we'll inject some attributes for display, without modifying the text storage directly.
        var paragraphWithDisplayAttributes: NSTextParagraph? = nil
        
        // First, get a copy of the paragraph from the original text storage.
        let originalText = textContentStorage.textStorage!.attributedSubstring(from: range)
        if originalText.attribute(.commentDepth, at: 0, effectiveRange: nil) != nil {
            // Use white colored text to make our comments visible against the bright background.
            let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: commentFont, .foregroundColor: commentColor]
            let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
            // Use the display attributes for the text of the comment itself, without the reaction.
            // The last character is the newline, second to last is the attachment character for the reaction.
            let rangeForDisplayAttributes = NSRange(location: 0, length: textWithDisplayAttributes.length - 2)
            textWithDisplayAttributes.addAttributes(displayAttributes, range: rangeForDisplayAttributes)
            
            // Create our new paragraph with our display attributes.
            paragraphWithDisplayAttributes = NSTextParagraph(attributedString: textWithDisplayAttributes)
        } else {
            return nil
        }
        // If the original paragraph wasn't a comment, this return value will be nil.
        // The text content storage will use the original paragraph in this case.
        return paragraphWithDisplayAttributes
    }
    
}
