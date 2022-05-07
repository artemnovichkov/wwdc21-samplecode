/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UICollectionViewCell subclass that provides two main behaviors on top of `UICollectionViewCell`:
                1. On catalyst, allows double taps to be recognized on the cell to open a new window of the item that cell represents.
                2. On iOS and Catalyst, update the cell's background configuration to style the cell differently for selected and non-selected states.
*/

import UIKit

class ImageCollectionViewConfigurationCell: UICollectionViewCell {
    
    #if targetEnvironment(macCatalyst)
    
    private let doubleTapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    var doubleTapCallback: (() -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizers()
    }
    
    private func addGestureRecognizers() {
        guard doubleTapGestureRecognizer.view == nil else {
            return
        }
        
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.cancelsTouchesInView = false
        doubleTapGestureRecognizer.delaysTouchesEnded = false
        doubleTapGestureRecognizer.addTarget(self, action: #selector(doubleTap(_:)))
        addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc
    func doubleTap(_ sender: UITapGestureRecognizer) {
        doubleTapCallback?()
    }
    
    #endif
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell().updated(for: state)
        
        backgroundConfig.cornerRadius = 3.0
        
        if state.isSelected {
            backgroundConfig.backgroundColor = self.tintColor
            backgroundConfig.strokeWidth = 1
            backgroundConfig.strokeColor = self.tintColor
        } else {
            backgroundConfig.backgroundColor = .clear
            backgroundConfig.strokeColor = .clear
        }
        
        backgroundConfiguration = backgroundConfig
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        #if targetEnvironment(macCatalyst)
        doubleTapCallback = nil
        #endif
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
    }
}
