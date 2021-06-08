/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The section background view.
*/

import UIKit

class SectionBackgroundDecorationView: UICollectionReusableView {
    private var gradientLayer = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
}

extension SectionBackgroundDecorationView {
    func configure() {
        gradientLayer.colors = [UIColor.systemBackground.withAlphaComponent(0).cgColor, UIColor.systemPink.withAlphaComponent(0.5).cgColor]
        layer.addSublayer(gradientLayer)
        gradientLayer.frame = layer.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = layer.bounds
    }
}
