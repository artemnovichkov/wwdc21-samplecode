/*
See LICENSE folder for this sample’s licensing information.

Abstract:
UICollectionViewCell subclass describing an SF Symbol image and its name.
 This cell illustrates how to apply a custom highlight effect.
*/

import UIKit

extension CustomCollectionViewCell {
#if targetEnvironment(macCatalyst)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with animationCoordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: animationCoordinator)
        
        // customize the border of the cell instead of putting a focus ring on top of it.
        if context.nextFocusedItem === self {
            let layer = self.imageContainer.layer
            layer.borderColor = self.tintColor.cgColor
            layer.borderWidth = 4.0
        } else if context.previouslyFocusedItem === self {
            let layer = self.imageContainer.layer
            layer.borderColor = UIColor.systemGray.cgColor
            layer.borderWidth = 1.0 / self.traitCollection.displayScale
        }
    }
#else
    override func updateConfiguration(using state: UICellConfigurationState) {
        // Create a configuration for the cell style that matches our cell design and update it for the current state.
        let backgroundConfiguration = UIBackgroundConfiguration.listPlainCell().updated(for: state)
        // The resolved background color can be assigned directly.
        self.imageContainer.backgroundColor = backgroundConfiguration.resolvedBackgroundColor(for: self.tintColor)
        // If the background color property is nil that means its the tint color. In that case use a white tint color
        // for the image view. Otherwise use the default label color.
        self.imageView.tintColor = backgroundConfiguration.backgroundColor == nil ? .white : .label
    }
#endif
}

class CustomCollectionViewCell: UICollectionViewCell {
    var data: SampleData? {
        didSet {
            let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 60.0))
            self.imageView.image = self.data?.icon.applyingSymbolConfiguration(configuration)?.withRenderingMode(.alwaysTemplate)
            self.label.text = self.data?.name
        }
    }

    private let imageView = UIImageView()
    private let label = UILabel()
    private let imageContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.imageContainer.translatesAutoresizingMaskIntoConstraints = false
        self.imageContainer.layer.borderColor = UIColor.systemGray.cgColor
        self.imageContainer.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.imageContainer.layer.cornerRadius = 16.0

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.adjustsFontForContentSizeCategory = true
        self.label.font = .preferredFont(forTextStyle: .body)
        self.label.textAlignment = .center
        self.label.numberOfLines = 0

        self.imageView.tintColor = .label
        self.imageView.contentMode = .scaleAspectFit

        self.contentView.addSubview(self.imageContainer)
        self.imageContainer.addSubview(self.imageView)
        self.contentView.addSubview(self.label)

        Layout.activate(
            // Vertical
            Layout.embed(self.imageContainer, self.label, verticallyIn: self.contentView, spacing: 8.0),

            // Horizontal
            [
                self.imageContainer.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
                self.imageContainer.leadingAnchor.constraint(greaterThanOrEqualTo: self.contentView.leadingAnchor),
                self.imageContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).with(priority: .defaultLow),
                self.label.widthAnchor.constraint(equalTo: self.imageContainer.widthAnchor, multiplier: 1.2)
            ],
            Layout.embed(self.label, horizontallyIn: self.contentView),

            // Image positioning.
            Layout.square(self.imageContainer),
            Layout.center(self.imageView, in: self.imageContainer),
            [
                self.imageView.leadingAnchor.constraint(greaterThanOrEqualTo: self.imageContainer.leadingAnchor),
                self.imageView.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor).with(priority: .defaultLow),
                self.imageView.topAnchor.constraint(greaterThanOrEqualTo: self.imageContainer.topAnchor),
                self.imageView.topAnchor.constraint(equalTo: self.imageView.topAnchor).with(priority: .defaultLow)
            ]
        )

        self.label.setContentHuggingPriority(.required, for: .vertical)
        self.label.setContentCompressionResistancePriority(.required, for: .vertical)

        // Set the focus effect to nil as this cell provides its own custom focus drawing.
        self.focusEffect = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.imageContainer.layer.borderWidth = 1.0 / self.traitCollection.displayScale
    }
}
