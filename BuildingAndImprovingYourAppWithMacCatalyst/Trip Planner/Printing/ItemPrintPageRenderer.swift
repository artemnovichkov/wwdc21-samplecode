/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Uses an `AnyModelObject`'s data layout and draw a custom print representation.
*/

import UIKit
import CoreGraphics

class ItemPrintPageRenderer: UIPrintPageRenderer {
    let items: [AnyModelItem]
    
    class func canPrint(items: [AnyModelItem]) -> Bool {
        // We can only print if any of the items are printable.
        !printableItems(items: items).isEmpty
    }

    private class func printableItems(items: [AnyModelItem]) -> [AnyModelItem] {
        let result: [AnyModelItem] = items.reduce(into: []) { result, item in
            // If the item has any of the properties we know how to print, add it to the list
            if !item.name.isEmpty {
                result.append(item)
            } else if let caption = item.caption, !caption.isEmpty {
                result.append(item)
            } else if let imageName = item.imageName, !imageName.isEmpty {
                if UIImage(named: imageName) != nil {
                    result.append(item)
                }
            }
        }
        return result
    }
    
    init(items: [AnyModelItem]) {
        let printableItems = ItemPrintPageRenderer.printableItems(items: items)
        self.items = printableItems
        super.init()
    }
    
    override var numberOfPages: Int {
        return items.count
    }

    override func drawContentForPage(at pageIndex: Int, in contentRect: CGRect) {
        // MARK: - Printer Helpers
        /// Draws `title` into `printingArea`
        /// - Parameters:
        ///   - title: The `String` to draw
        ///   - printingArea: The total area available for drawing. Drawing will occur in a rect contained by `printingArea`,
        ///    or possibly be clipped depending on the configuration of the drawing context.
        /// - Returns: The rect now occupied by the drawn `title` string and its margins in `printingArea` coordinates.
        func draw(title: String, into printingArea: CGRect) -> CGRect {
            var titleTextFrame: CGRect
            let titleTopMargin = 40.0

            if !title.isEmpty {
                let titleFontSize = 24.0
                let titleBottomMargin = 30.0

                let titleFont = UIFont(name: "Helvetica", size: titleFontSize)

                let titleParagraphStyle = NSMutableParagraphStyle()
                titleParagraphStyle.alignment = .center

                let titleAttributes = [NSAttributedString.Key.font: titleFont!,
                                       NSAttributedString.Key.paragraphStyle: titleParagraphStyle]

                let titleTextBounds = title.boundingRect(with: printingArea.size,
                                                         options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                         attributes: titleAttributes,
                                                         context: nil)

                titleTextFrame = CGRect(x: printingArea.midX - (titleTextBounds.width / 2.0),
                                            y: printingArea.origin.y + titleTopMargin,
                                        width: titleTextBounds.width,
                                            height: titleTextBounds.height + titleBottomMargin)

                title.draw(in: titleTextFrame, withAttributes: titleAttributes)

                titleTextFrame.origin.y = printingArea.origin.y
                titleTextFrame.size.height = titleTopMargin + titleTextBounds.height + titleBottomMargin
            } else {
                titleTextFrame = CGRect(origin: printingArea.origin, size: CGSize(width: printingArea.width, height: titleTopMargin))
            }
            return titleTextFrame
        }

        /// Draws `caption` into `printingArea`
        /// - Parameters:
        ///   - caption: The `String` to draw
        ///   - printingArea: The total area available for drawing. Drawing will occur in a rect contained by `printingArea`,
        ///    or possibly be clipped depending on the configuration of the drawing context.
        /// - Returns: The rect now occupied by the drawn `caption` string and its margins in `printingArea` coordinates.
        func draw(caption: String?, into printingArea: CGRect) -> CGRect {
            guard let caption = caption, !caption.isEmpty else { return .zero }

            let captionFontSize = 13.0
            let captionSideMargins = 50.0
            let captionBottomMargin = 20.0

            var captionArea = printingArea
            captionArea.origin.x += captionSideMargins
            captionArea.size.width -= 2.0 * captionSideMargins

            let captionFont = UIFont(name: "Helvetica", size: captionFontSize)

            let captionAttributes = [NSAttributedString.Key.font: captionFont!]

            let captionTextBounds = caption.boundingRect(with: captionArea.size,
                                                         options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                         attributes: captionAttributes,
                                                         context: nil)

            captionArea.size.height = captionTextBounds.height + captionBottomMargin
            caption.draw(in: captionArea, withAttributes: captionAttributes)

            return captionArea
        }

        /// Draws `image` into `printingArea`
        /// - Parameters:
        ///   - image: The `String` to draw
        ///   - printingArea: The total area available for drawing. Drawing will occur in a rect contained by `printingArea`,
        ///    or possibly be clipped depending on the configuration of the drawing context.
        /// - Returns: The entire now occupied by the drawn `title` string and its margins in `printingArea` coordinates.
        func draw(image: UIImage?, into printingArea: CGRect) -> CGRect {
            guard let image = image else { return .zero }

            var imageBox = printingArea

            var imageSize = image.size
            let scaleX = imageBox.width / imageSize.width
            let scaleY = imageBox.height / imageSize.height
            let scale = CGFloat.minimum(scaleX, scaleY)

            imageSize.width *= scale
            imageSize.height *= scale

            imageBox = CGRect(x: printingArea.midX - (imageSize.width / 2.0), // Horizontally center in the printing area
                              y: printingArea.midY - (imageSize.height / 2.0), // Vertically center in the printing area
                              width: imageSize.width,
                              height: imageSize.height)

            image.draw(in: imageBox)
            return imageBox
        }

        // MARK: - Procedural Printing
        let item = items[pageIndex]
        
        let title = item.name
        let caption = item.caption
        let image: UIImage? = item.imageName.flatMap { UIImage(named: $0) }
        guard let context = UIGraphicsGetCurrentContext() else {
            Swift.debugPrint("No current context for printing")
            return
        }
        
        context.saveGState()

        // Title
        var printRect = addMargins(to: contentRect)
        let titleRect = draw(title: title, into: printRect)

        // Caption
        let titleDownShift = titleRect.height
        printRect.origin.y += titleDownShift
        printRect.size.height -= titleDownShift
        let captionRect = draw(caption: caption, into: printRect)

        // Image
        let captionDownShift = captionRect.height
        printRect.origin.y += captionDownShift
        printRect.size.height -= captionDownShift
        _ = draw(image: image, into: printRect)

        context.restoreGState()
    }

    private func addMargins(to contentRect: CGRect) -> CGRect {
        var printRect = contentRect
        printRect.origin.x += 36
        printRect.origin.y += 36
        printRect.size.width -= 72
        printRect.size.height -= 72
        return printRect
    }
}
