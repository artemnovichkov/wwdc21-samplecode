/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Layout utility for building and embedding NSLayoutConstraints to views.
*/

import UIKit

protocol LayoutAnchorProviding {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

struct Layout {
    // The value we use to calculate all our spacings.
    static let defaultSpacing = 40.0

    static func activate(_ constraints: [NSLayoutConstraint]...) {
        NSLayoutConstraint.activate(constraints.flatMap({ $0 }))
    }

    static func embed(_ items: LayoutAnchorProviding...,
                      horizontallyIn container: LayoutAnchorProviding,
                      spacing: CGFloat = defaultSpacing,
                      hasPadding: Bool = false) -> [NSLayoutConstraint] {
        guard !items.isEmpty else { return [] }

        let padding = hasPadding ? spacing * 0.5 : 0.0

        var lastItem: LayoutAnchorProviding? = nil
        var constraints = [
            // Add leading and trailing constraints.
            items.first!.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            container.trailingAnchor.constraint(equalTo: items.last!.trailingAnchor, constant: padding)
        ]

        // Add intermediate constraints.
        for item in items {
            if let lastItem = lastItem {
                constraints.append(item.leadingAnchor.constraint(equalTo: lastItem.trailingAnchor, constant: spacing))
            }
            lastItem = item
        }

        return constraints
    }

    static func embed(_ items: LayoutAnchorProviding...,
                      verticallyIn container: LayoutAnchorProviding,
                      spacing: CGFloat = defaultSpacing,
                      hasPadding: Bool = false) -> [NSLayoutConstraint] {
        guard !items.isEmpty else { return [] }

        let padding = hasPadding ? spacing * 0.5 : 0.0

        var lastItem: LayoutAnchorProviding? = nil
        var constraints = [
            // Add leading and trailing constraints.
            items.first!.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            container.bottomAnchor.constraint(equalTo: items.last!.bottomAnchor, constant: padding)
        ]

        // Add intermediate constraints.
        for item in items {
            if let lastItem = lastItem {
                constraints.append(item.topAnchor.constraint(equalTo: lastItem.bottomAnchor, constant: spacing))
            }
            lastItem = item
        }

        return constraints
    }

    static func center(_ item: LayoutAnchorProviding, in container: LayoutAnchorProviding) -> [NSLayoutConstraint] {
        return [
            item.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            item.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ]
    }

    static func square(_ item: LayoutAnchorProviding, size: CGFloat? = defaultSpacing * 3.0) -> [NSLayoutConstraint] {
        var constraints = [ item.widthAnchor.constraint(equalTo: item.heightAnchor) ]
        if let size = size {
            constraints.append(item.widthAnchor.constraint(equalToConstant: size))
        }
        return constraints
    }
}

extension NSLayoutConstraint {
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

extension UIView: LayoutAnchorProviding {}
extension UILayoutGuide: LayoutAnchorProviding {}
