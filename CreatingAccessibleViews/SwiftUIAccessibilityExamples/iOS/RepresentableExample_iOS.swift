/*
See LICENSE folder for this sample’s licensing information.

Abstract:
iOS UIViewRepresentable implementations.
*/

import SwiftUI
import UIKit

/// `UIView` used to demonstrate accessibility of `UIViewRepresentable` types.
final class RepresentableUIView: UIView {
    var color: UIColor

    init(_ color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        self.isAccessibilityElement = true
        layer.backgroundColor = color.cgColor
        layer.cornerRadius = defaultCornerRadius
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

/// `UIViewController` type used to demonstrate accessibility.
final class RepresentableUIViewController: UIViewController {
    override func loadView() {
        self.view = RepresentableUIView(.blue)
    }
}

/// `UIViewControllerRepresentable` used to demonstrate accessibility.
struct RepresentableViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<RepresentableViewController>)
        -> RepresentableUIViewController {
        RepresentableUIViewController()
    }

    func updateUIViewController(
        _ nsViewController: RepresentableUIViewController,
        context: UIViewControllerRepresentableContext<RepresentableViewController>) {
    }
}

/// `UIViewRepresentable` type used to demonstrate accessibility.
struct RepresentableView: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<RepresentableView>)
        -> RepresentableUIView {
        RepresentableUIView(.red)
    }

    func updateUIView(_ nsView: RepresentableUIView, context: UIViewRepresentableContext<RepresentableView>) {
    }
}
