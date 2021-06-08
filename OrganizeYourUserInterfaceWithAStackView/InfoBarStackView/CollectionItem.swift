/*
See LICENSE folder for this sample’s licensing information.

Abstract:
NSCollectionViewItem subclass custom rendering of selected items.
*/

import Cocoa

// A collection item displays an image.
class CollectionItem: NSCollectionViewItem {

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                // Create visual feedback for the selected collection view item.
                view.layer?.borderColor = NSColor.lightGray.cgColor
                view.layer?.borderWidth = 4
            } else {
                view.layer?.borderWidth = 0
            }
        }
    }
    
}
