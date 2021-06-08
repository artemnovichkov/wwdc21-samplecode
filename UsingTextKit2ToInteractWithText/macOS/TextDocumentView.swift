/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSView subclass for managing text in the app's document.
*/

import Cocoa

class TextDocumentLayer: CALayer {
    override class func defaultAction(forKey event: String) -> CAAction? {
        // Suppress default animation of opacity when adding comment bubbles.
        return NSNull()
    }
}

class TextDocumentView: NSView, CALayerDelegate, NSTextViewportLayoutControllerDelegate, NSTextLayoutManagerDelegate {
    var textLayoutManager: NSTextLayoutManager? {
        willSet {
            if let tlm = textLayoutManager {
                tlm.delegate = nil
                tlm.textViewportLayoutController.delegate = nil
            }
        }
        didSet {
            if let tlm = textLayoutManager {
                tlm.delegate = self
                tlm.textViewportLayoutController.delegate = self
            }
            updateContentSizeIfNeeded()
            updateTextContainerSize()
            layer!.setNeedsLayout()
        }
    }
    
    var textContentStorage: NSTextContentStorage?
    @IBOutlet var documentViewController: TextDocumentViewController!
    var showLayerFrames: Bool = false
    var slowAnimations: Bool = false

    private var boundsDidChangeObserver: Any? = nil
    
    private var contentLayer: CALayer! = nil
    private var selectionLayer: CALayer! = nil
    private var fragmentLayerMap: NSMapTable<NSTextLayoutFragment, CALayer>
    private var padding: CGFloat = 5.0
    
    override init(frame: CGRect) {
        fragmentLayerMap = .weakToWeakObjects()
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fragmentLayerMap = .weakToWeakObjects()
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = .white
        selectionLayer = TextDocumentLayer()
        contentLayer = TextDocumentLayer()
        layer?.addSublayer(selectionLayer)
        layer?.addSublayer(contentLayer)
        fragmentLayerMap = NSMapTable.weakToWeakObjects()
        padding = 5.0
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    deinit {
       if let observer = boundsDidChangeObserver {
           NotificationCenter.default.removeObserver(observer)
       }
    }
    
    override var isFlipped: Bool { return true }
    
    func layoutSublayers(of layer: CALayer) {
        assert(layer == self.layer)
        textLayoutManager?.textViewportLayoutController.layoutViewport()
        updateContentSizeIfNeeded()
    }
    
    // NSResponder
    override var acceptsFirstResponder: Bool { return true }
    
    // Responsive scrolling.
    override class var isCompatibleWithResponsiveScrolling: Bool { return true }
    override func prepareContent(in rect: NSRect) {
        layer!.setNeedsLayout()
        super.prepareContent(in: rect)
    }
    
    // MARK: - NSTextViewportLayoutControllerDelegate
    
    func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let overdrawRect = preparedContentRect
        let visibleRect = self.visibleRect
        var minY: CGFloat = 0
        var maxY: CGFloat = 0
        if overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minY = min(overdrawRect.minY, max(visibleRect.minY, 0))
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // We use visible rect directly if preparedContentRect does not intersect.
            // This can happen if overdraw has not caught up with scrolling yet, such as before the first layout.
            minY = visibleRect.minY
            maxY = visibleRect.maxY
        }
        return CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)
    }
    
    func textViewportLayoutControllerWillLayout(_ controller: NSTextViewportLayoutController) {
        contentLayer.sublayers = nil
        CATransaction.begin()
    }
    
    private func animate(_ layer: CALayer, from source: CGPoint, to destination: CGPoint) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = source
        animation.toValue = destination
        animation.duration = slowAnimations ? 2.0 : 0.3
        layer.add(animation, forKey: nil)
    }
    
    private func findOrCreateLayer(_ textLayoutFragment: NSTextLayoutFragment) -> (TextLayoutFragmentLayer, Bool) {
        if let layer = fragmentLayerMap.object(forKey: textLayoutFragment) as? TextLayoutFragmentLayer {
            return (layer, false)
        } else {
            let layer = TextLayoutFragmentLayer(layoutFragment: textLayoutFragment, padding: padding)
            fragmentLayerMap.setObject(layer, forKey: textLayoutFragment)
            return (layer, true)
        }
    }
    
    func textViewportLayoutController(_ controller: NSTextViewportLayoutController,
                                      configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let (layer, layerIsNew) = findOrCreateLayer(textLayoutFragment)
        if !layerIsNew {
            let oldPosition = layer.position
            let oldBounds = layer.bounds
            layer.updateGeometry()
            if oldBounds != layer.bounds {
                layer.setNeedsDisplay()
            }
            if oldPosition != layer.position {
                animate(layer, from: oldPosition, to: layer.position)
            }
        }
        if layer.showLayerFrames != showLayerFrames {
            layer.showLayerFrames = showLayerFrames
            layer.setNeedsDisplay()
        }
        
        contentLayer.addSublayer(layer)
    }
    
    func textViewportLayoutControllerDidLayout(_ controller: NSTextViewportLayoutController) {
        CATransaction.commit()
        updateSelectionHighlights()
        updateContentSizeIfNeeded()
        adjustViewportOffsetIfNeeded()
    }
    
    private func updateSelectionHighlights() {
        if !textLayoutManager!.textSelections.isEmpty {
            selectionLayer.sublayers = nil
            for textSelection in textLayoutManager!.textSelections {
                for textRange in textSelection.textRanges {
                    textLayoutManager!.enumerateTextSegments(in: textRange,
                                                             type: .highlight,
                                                             options: []) {(textSegmentRange, textSegmentFrame, baselinePosition, textContainer) in
                        var highlightFrame = textSegmentFrame
                        highlightFrame.origin.x += padding
                        let highlight = TextDocumentLayer()
                        if highlightFrame.size.width > 0 {
                            highlight.backgroundColor = selectionColor.cgColor
                        } else {
                            highlightFrame.size.width = 1 // fatten up the cursor
                            highlight.backgroundColor = caretColor.cgColor
                        }
                        highlight.frame = highlightFrame
                        selectionLayer.addSublayer(highlight)
                        return true // keep going
                    }
                }
            }
        }
    }
    
    // Colors support.
    var selectionColor: NSColor { return .selectedTextBackgroundColor }
    var caretColor: NSColor { return .black }
    
    // Live resize.
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        adjustViewportOffsetIfNeeded()
        updateContentSizeIfNeeded()
    }
    
    // Scroll view support.
    private var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else { return nil }
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }
    
    func updateContentSizeIfNeeded() {
        let currentHeight = bounds.height
        var height: CGFloat = 0
        let endRange = NSTextRange(location: textLayoutManager!.documentRange.endLocation)
        textLayoutManager!.ensureLayout(for: endRange)
        textLayoutManager!.enumerateTextLayoutFragments(from: textLayoutManager!.documentRange.endLocation,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false // stop
        }
        height = max(height, enclosingScrollView?.contentSize.height ?? 0)
        if abs(currentHeight - height) > 1e-10 {
            let contentSize = NSSize(width: self.bounds.width, height: height)
            setFrameSize(contentSize)
        }
    }
    
    private func adjustViewportOffsetIfNeeded() {
        let viewportLayoutController = textLayoutManager!.textViewportLayoutController
        let contentOffset = scrollView!.contentView.bounds.minY
        if contentOffset < scrollView!.contentView.bounds.height &&
            viewportLayoutController.viewportRange!.location.compare(textLayoutManager!.documentRange.location) == .orderedDescending {
            // Nearing top, see if we need to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLayoutController.viewportRange!.location.compare(textLayoutManager!.documentRange.location) == .orderedSame {
            // At top, see if we need to adjust and reduce space above.
            adjustViewportOffset()
        }
    }
    
    private func adjustViewportOffset() {
        let viewportLayoutController = textLayoutManager!.textViewportLayoutController
        var layoutYPoint: CGFloat = 0
        textLayoutManager!.enumerateTextLayoutFragments(from: viewportLayoutController.viewportRange!.location,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
            return true
        }
        if layoutYPoint != 0 {
            let adjustmentDelta = bounds.minY - layoutYPoint
            viewportLayoutController.adjustViewport(adjustmentDelta)
            scroll(CGPoint(x: scrollView!.contentView.bounds.minX, y: scrollView!.contentView.bounds.minY + adjustmentDelta))
        }
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        let clipView = scrollView?.contentView
        if clipView != nil {
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: clipView)
        }
        
        super.viewWillMove(toSuperview: newSuperview)
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        
        let clipView = scrollView?.contentView
        if clipView != nil {
            boundsDidChangeObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                                   object: clipView,
                                                   queue: nil) { [weak self] notification in
                self!.layer?.setNeedsLayout()
            }
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateTextContainerSize()
    }
    
    private func updateTextContainerSize() {
        let textContainer = textLayoutManager!.textContainer
        if textContainer != nil && textContainer!.size.width != bounds.width {
            textContainer!.size = NSSize(width: bounds.size.width, height: 0)
            layer?.setNeedsLayout()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        var point = convert(event.locationInWindow, from: nil)
        point.x -= padding
        let nav = textLayoutManager!.textSelectionNavigation
        
        textLayoutManager!.textSelections = nav.textSelections(interactingAt: point,
                                                               containerLocation: textLayoutManager!.documentRange.location,
                                                               anchors: [],
                                                               modifiers: [],
                                                               selecting: true, bounds: .zero)
        layer?.setNeedsLayout()
    }

    override func mouseDragged(with event: NSEvent) {
        var point = convert(event.locationInWindow, from: nil)
        point.x -= padding
        let nav = textLayoutManager!.textSelectionNavigation
        
        textLayoutManager!.textSelections = nav.textSelections(interactingAt: point,
                                                               containerLocation: textLayoutManager!.documentRange.location,
                                                               anchors: textLayoutManager!.textSelections,
                                                               modifiers: .extend,
                                                               selecting: true,
                                                               bounds: .zero)
        layer?.setNeedsLayout()
    }
    
    func addComment(_ comment: NSAttributedString, below parentFragment: NSTextLayoutFragment) {
        guard let fragmentParagraph = parentFragment.textElement as? NSTextParagraph else { return }
        
        if let fragmentDepthValue = fragmentParagraph.attributedString.attribute(.commentDepth, at: 0, effectiveRange: nil) as? NSNumber? {
            let fragmentDepth = fragmentDepthValue?.uintValue ?? 0
            
            let commentWithNewline = NSMutableAttributedString(attributedString: comment)
            commentWithNewline.append(NSAttributedString(string: "\n"))
            
            // Apply our comment attribute to the entire range.
            commentWithNewline.addAttribute(.commentDepth,
                                            value: NSNumber(value: fragmentDepth + 1),
                                            range: NSRange(location: 0, length: commentWithNewline.length))
            
            let insertLocation = parentFragment.rangeInElement.endLocation
            let insertIndex = textLayoutManager!.offset(from: textLayoutManager!.documentRange.location, to: insertLocation)
            textContentStorage!.performEditingTransaction {
                textContentStorage!.textStorage?.insert(commentWithNewline, at: insertIndex)
            }
            layer?.setNeedsLayout()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let textLayoutManager = textLayoutManager else {
            fatalError("textLayoutManager must not be nil")
        }
        if event.clickCount == 2 && !textLayoutManager.textSelections.isEmpty {
            // Double-click in the text element.
            let clickedLocation = textLayoutManager.textSelections[0].textRanges[0].location
            if let clickedFragment = textLayoutManager.textLayoutFragment(for: clickedLocation) {
                documentViewController.showCommentPopover(for: clickedFragment)
            }
        }
    }
    
    // Center Selection
    override func centerSelectionInVisibleArea(_ sender: Any?) {
        if !textLayoutManager!.textSelections.isEmpty {
            let viewportOffset =
                textLayoutManager!.textViewportLayoutController.relocateViewport(textLayoutManager!.textSelections[0].textRanges[0].location)
            scroll(CGPoint(x: 0, y: viewportOffset))
        }
    }
    
    // MARK: - NSTextLayoutManagerDelegate
    
    func textLayoutManager(_ textLayoutManager: NSTextLayoutManager,
                           textLayoutFragmentFor location: NSTextLocation,
                           in textElement: NSTextElement) -> NSTextLayoutFragment {
        let index = textLayoutManager.offset(from: textLayoutManager.documentRange.location, to: location)
        let commentDepthValue = textContentStorage!.textStorage!.attribute(.commentDepth, at: index, effectiveRange: nil) as! NSNumber?
        if commentDepthValue != nil {
            let layoutFragment = BubbleLayoutFragment(textElement: textElement, range: textElement.elementRange)
            layoutFragment.commentDepth = commentDepthValue!.uintValue
            return layoutFragment
        } else {
            return NSTextLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
    }
}
