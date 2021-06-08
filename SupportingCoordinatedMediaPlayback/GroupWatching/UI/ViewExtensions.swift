/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View and color extensions.
*/

import UIKit

extension UIColor {
    static let baseBackground = UIColor(white: 0.05, alpha: 1.0)
    static let contentBackground = UIColor(white: 0.08, alpha: 1.0)
    
    static let selectedBackground = UIColor(white: 0.15, alpha: 1.0)
    static let highlightedBackground = UIColor(white: 0.20, alpha: 1.0)
}

public extension UIView {
    
    func pinToSuperviewEdges(padding: CGFloat = 0.0) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: padding),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -padding),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -padding)
        ])
    }
}

