/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view subclass that creates four subviews of the specified generic type and lays them out in a 2x2 grid.
*/

import UIKit

/// A view that creates four subviews of the specified generic type and lays them out in a 2x2 grid.
/// Optionally a hairline divider can be shown horizontally or vertically between them
class GridView<T: UIView>: UIView {
    class HairlineView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = .systemFill
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            let hairline = 1.0 / self.traitCollection.displayScale
            return CGSize(width: hairline, height: hairline)
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            self.invalidateIntrinsicContentSize()
        }
    }

    let topLeading = T()
    let topTrailing = T()
    let bottomLeading = T()
    let bottomTrailing = T()

    private let horizontalHairline = HairlineView()
    private let verticalHairline = HairlineView()

    var showsHorizontalDivider: Bool = false {
        didSet {
            self.horizontalHairline.isHidden = !self.showsHorizontalDivider
        }
    }
    var showsVerticalDivider: Bool = false {
        didSet {
            self.verticalHairline.isHidden = !self.showsVerticalDivider
        }
    }

    func enumerateViews(_ enumerator: (UIView) -> Void) {
        enumerator(self.topLeading)
        enumerator(self.topTrailing)
        enumerator(self.bottomLeading)
        enumerator(self.bottomTrailing)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.horizontalHairline.isHidden = true
        self.verticalHairline.isHidden = true

        self.topLeading.translatesAutoresizingMaskIntoConstraints = false
        self.topTrailing.translatesAutoresizingMaskIntoConstraints = false
        self.bottomLeading.translatesAutoresizingMaskIntoConstraints = false
        self.bottomTrailing.translatesAutoresizingMaskIntoConstraints = false
        self.horizontalHairline.translatesAutoresizingMaskIntoConstraints = false
        self.verticalHairline.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.topLeading)
        self.addSubview(self.topTrailing)
        self.addSubview(self.bottomLeading)
        self.addSubview(self.bottomTrailing)
        self.addSubview(self.horizontalHairline)
        self.addSubview(self.verticalHairline)

        Layout.activate(
            // horizontal
            Layout.embed(self.topLeading, self.topTrailing, horizontallyIn: self, hasPadding: true),
            Layout.embed(self.bottomLeading, self.bottomTrailing, horizontallyIn: self, hasPadding: true),

            // vertical
            Layout.embed(self.topLeading, self.bottomLeading, verticallyIn: self, hasPadding: true),
            Layout.embed(self.topTrailing, self.bottomTrailing, verticallyIn: self, hasPadding: true),

            // aspect
            Layout.square(self.topLeading),
            Layout.square(self.topTrailing),
            Layout.square(self.bottomLeading),
            Layout.square(self.bottomTrailing),

            // hairline
            Layout.center(self.horizontalHairline, in: self),
            Layout.embed(self.horizontalHairline, horizontallyIn: self),
            Layout.center(self.verticalHairline, in: self),
            Layout.embed(self.verticalHairline, verticallyIn: self)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class GridViewController<T: UIView>: UIViewController {
    let gridView = GridView<T>()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        self.gridView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.gridView)

        Layout.activate(Layout.center(self.gridView, in: self.view))
    }
}

