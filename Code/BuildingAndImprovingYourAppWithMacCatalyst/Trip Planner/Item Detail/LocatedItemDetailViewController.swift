/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A View Controller for representing any model item with a location and image.
*/

import UIKit
import MapKit

class LocatedItemDetailViewController: UIViewController {

    let modelItem: LocatedItem

    init(modelItem: LocatedItem) {
        self.modelItem = modelItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installImageView()
        installDynamicStack()
        installButtons()
        installSubtextAndMapView()
        installPriceRangeIfNeeded()
    }

    lazy var specialBarButtonImage: UIImage? = {
        if let restaurant = modelItem as? Restaurant,
           let iconImage = restaurant.iconImage {
            return iconImage
        } else {
            return nil
        }
    }()

    override func loadView() {
        view = UIView()

        // The image goes behind everything else, and will be blurred
        let imageBackground = makeImageView(shareEnabled: false)
        view.addSubview(imageBackground)
        imageBackground.contentMode = .scaleToFill
        imageBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageBackground.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageBackground.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageBackground.topAnchor.constraint(equalTo: view.topAnchor),
            imageBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.tintColor = modelItem.downsampledColor

        // The visual effect view goes directly on top of the image
        view.addSubview(visualEffect)
        NSLayoutConstraint.activate([
            visualEffect.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffect.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Everything else is an ancestor of the visual effect view's content view
        visualEffect.contentView.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: visualEffect.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: visualEffect.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: visualEffect.safeAreaLayoutGuide.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: visualEffect.safeAreaLayoutGuide.bottomAnchor)
        ])

        scroll.addSubview(rootVStack)
        rootVStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootVStack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            rootVStack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            rootVStack.topAnchor.constraint(equalTo: scroll.topAnchor),
            rootVStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            rootVStack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])
    }

    // MARK: Subviews
    private var rootVStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = UIStackView.spacingUseSystem
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return stack
    }()

    private var dynamicStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = 10
        return stack
    }()

    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()
    private var buttonCompactConstraints: [NSLayoutConstraint] = []
    private var buttonRegularConstraints: [NSLayoutConstraint] = []

    private let mapAndSubtextStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = UIStackView.spacingUseSystem
        return stack
    }()

    private var scroll: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    private var visualEffect: UIVisualEffectView = {
        let vev = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        vev.translatesAutoresizingMaskIntoConstraints = false
        return vev
    }()

    private lazy var heroImageView: UIView = {
        let imageView = makeImageView(shareEnabled: true)
        imageView.contentMode = .scaleAspectFill
        let interaction = UIToolTipInteraction(defaultToolTip: modelItem.altText)
        imageView.addInteraction(interaction)
        return imageView
    }()

    private let buttons: [UIButton] = {
        var config = UIButton.Configuration.filled()

        let transforms = (-2...1).map { alphaStep in
            UIConfigurationColorTransformer { color in
                var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
                color.getRed(&r, green: &g, blue: &b, alpha: nil)
                let increasedWhite: CGFloat = (CGFloat(alphaStep) * 0.07) + 1
                return UIColor(red: increasedWhite * r, green: increasedWhite * g, blue: increasedWhite * b, alpha: 1.0)
            }
        }

        let directions = UIButton(type: .system)
        config.title = "Get Directions"
        config.image = UIImage(systemName: "arrow.triangle.turn.up.right.circle")
        config.background.backgroundColorTransformer = transforms[0]
        directions.configuration = config

        let tripPlan = UIButton(type: .system)
        config.title = "ML Trip Planner"
        config.image = UIImage(systemName: "person.circle")
        config.background.backgroundColorTransformer = transforms[1]
        tripPlan.configuration = config

        let podcast = UIButton(type: .system)
        config.title = "Site Audio Tour"
        config.image = UIImage(systemName: "headphones.circle")
        config.background.backgroundColorTransformer = transforms[2]
        podcast.configuration = config

        let arTour = UIButton(type: .system)
        config.title = "AR Walkthrough"
        config.image = UIImage(systemName: "viewfinder.circle")
        config.background.backgroundColorTransformer = transforms[3]
        arTour.configuration = config

        return [directions, tripPlan, podcast, arTour]
    }()

    private func makeImageView(shareEnabled: Bool) -> UIImageView {
        guard let image = modelItem.image else {
            Swift.debugPrint("Missing image for \(modelItem)")
            return UIImageView()
        }
        let imageView = shareEnabled ? SharingImageView(image: image) : UIImageView(image: image)
        return imageView
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [self] context in
            updateDynamicStack(using: size)
            dynamicStack.setNeedsLayout()
            dynamicStack.layoutIfNeeded()
        }, completion: nil)
    }

    private func updateDynamicStack(using size: CGSize?) {
        let currentButtonWidth = buttonStack.subviews.first?.sizeThatFits(UIView.layoutFittingCompressedSize).width ?? .zero
        let minimumRequiredTextWidth: CGFloat = 300

        let workingSize: CGSize = size ?? view.frame.size

        if workingSize.width < currentButtonWidth + minimumRequiredTextWidth {
            dynamicStack.axis = .vertical
            buttonRegularConstraints.forEach { $0.isActive = false }
            buttonCompactConstraints.forEach { $0.isActive = true }
        } else {
            dynamicStack.axis = .horizontal
            buttonCompactConstraints.forEach { $0.isActive = false }
            buttonRegularConstraints.forEach { $0.isActive = true }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateDynamicStack(using: nil)
    }
    
    // MARK: Printing
    
    fileprivate func itemsToPrint() -> [AnyModelItem] {
        let itemsToPrint = [AnyModelItem(modelItem)]
        return itemsToPrint
    }
    
    // This action will only be used when the LocatedItemDetailViewController is firstResponder. This mainly happens if it has been opened in
    // its own window scene.
    override func printContent(_: Any?) {
        let renderer = ItemPrintPageRenderer(items: itemsToPrint())
        
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.orientation = .portrait
        info.jobName = modelItem.name
        
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printPageRenderer = renderer
        printInteractionController.printInfo = info
        
        printInteractionController.present(animated: true)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(self.printContent(_:)) {
            return ItemPrintPageRenderer.canPrint(items: itemsToPrint())
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }
}

extension LocatedItemDetailViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
            suggestedActions -> UIMenu? in
            return UIMenu(title: "main", image: nil, identifier: nil, options: [], children: suggestedActions)
        })
    }

}

// MARK: View Layout
extension LocatedItemDetailViewController {
    private func installImageView() {
        heroImageView.layer.cornerRadius = 6.0
        heroImageView.layer.masksToBounds = true

        rootVStack.addArrangedSubview(heroImageView)

        heroImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 350.0).isActive = true
    }

    private func installDynamicStack() {
        rootVStack.addArrangedSubview(dynamicStack)
    }

    private func installSubtextAndMapView() {
        let textView = UITextView()
        textView.text = modelItem.caption
        textView.font = UIFont.preferredFont(forTextStyle: .subheadline)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false

        let labelWrapper = UIView()
        labelWrapper.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalToSystemSpacingAfter: labelWrapper.leadingAnchor, multiplier: 1.0),
            labelWrapper.trailingAnchor.constraint(equalToSystemSpacingAfter: textView.trailingAnchor, multiplier: 1.0),
            textView.topAnchor.constraint(equalToSystemSpacingBelow: labelWrapper.topAnchor, multiplier: 1.0),
            labelWrapper.bottomAnchor.constraint(equalToSystemSpacingBelow: textView.bottomAnchor, multiplier: 1.0)
        ])
        labelWrapper.backgroundColor = .systemGroupedBackground.withAlphaComponent(0.6)
        labelWrapper.layer.cornerRadius = 3.0
        labelWrapper.clipsToBounds = true

        let mapView = MKMapView()
        mapView.layer.cornerRadius = 4.0
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = true // default

        #if targetEnvironment(macCatalyst)
        mapView.showsPitchControl = true
        mapView.showsZoomControls = true
        #endif

        mapAndSubtextStack.addArrangedSubview(labelWrapper)
        mapAndSubtextStack.addArrangedSubview(mapView)
        mapView.region = MKCoordinateRegion(center: modelItem.location.coordinate, latitudinalMeters: 1600, longitudinalMeters: 1600)

        let isLeftToRight = view.effectiveUserInterfaceLayoutDirection == .leftToRight
        dynamicStack.insertArrangedSubview(mapAndSubtextStack, at: isLeftToRight ? 0 : 1)

        // Stretch the label and map as wide as they'll go without interfering with the buttons
        let optionalWidthMap = mapView.widthAnchor.constraint(equalTo: view.widthAnchor)
        optionalWidthMap.priority = .defaultHigh + 100
        optionalWidthMap.isActive = true
        labelWrapper.widthAnchor.constraint(equalTo: mapView.widthAnchor).isActive = true
        let labelAndMap = mapAndSubtextStack.widthAnchor.constraint(equalTo: view.widthAnchor)
        labelAndMap.priority = .defaultHigh
        labelAndMap.isActive = true

        // Give the map a somewhat arbitrary aspect ratio
        mapView.heightAnchor.constraint(equalTo: mapView.widthAnchor, multiplier: 0.7).isActive = true
    }

    private func installButtons() {
        let maxWidth: CGFloat = buttons.reduce(0) { result, button in
            button.sizeToFit()
            return max(result, button.frame.size.width)
        }

        buttons.forEach { button in
            buttonStack.addArrangedSubview(button)
        }

        buttonCompactConstraints = buttons.map { button in
            button.widthAnchor.constraint(equalTo: dynamicStack.widthAnchor)
        }

        buttonRegularConstraints = buttons.map { button in
            let equalWidthsConstraint = button.widthAnchor.constraint(equalToConstant: maxWidth)
            equalWidthsConstraint.priority = .defaultHigh + 200
            equalWidthsConstraint.isActive = true
            return equalWidthsConstraint
        }

        dynamicStack.addArrangedSubview(buttonStack)
    }

    private func installPriceRangeIfNeeded() {
        guard let price = (modelItem as? Lodging)?.priceRange ?? (modelItem as? Restaurant)?.priceRange else {
            return
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: price.localeIdentifier)

        let priceLabel = UILabel()
        priceLabel.showsExpansionTextWhenTruncated = true

        priceLabel.text = "\(formatter.string(for: price.lower)!)...\(formatter.string(for: price.upper)!)"
        buttonStack.insertArrangedSubview(priceLabel, at: 0)
    }
}
