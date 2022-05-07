/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Intended for use as a child view controller of DetailViewController. Represents the `RewardsProgram` model object.
*/

import UIKit

/// The `EmojiKnobSlider` assumes its knob will alternate between an emoji and the standard UISlider knob artwork. It overrides methods to ensure its
/// layout attributes don't change — thus the slider won't shift — when the knob size changes.
class EmojiKnobSlider: UISlider {
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return super.trackRect(forBounds: CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: 23)))
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        if currentThumbImage == nil {
            return super.thumbRect(
                forBounds: CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: 23)),
                trackRect: rect, value: value)
        } else {
            let skinnyKnobShift: CGFloat = CGFloat((1 - value / maximumValue) * -10 + 4)
            var rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
            rect.origin.x += skinnyKnobShift
            return rect
        }
    }
}

class RewardsProgramDetailViewController: UIViewController {

    static private let sliderPatternColor = UIColor(patternImage: #imageLiteral(resourceName: "slider_pattern"))

    @IBOutlet weak var topLeft: UIButton!
    @IBOutlet weak var topRight: UIButton!
    @IBOutlet weak var bottomLeft: UIButton!
    @IBOutlet weak var bottomRight: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var multiplierToggleButton: UIButton!
    @IBOutlet weak var sliderLabelAndMultiplierStack: UIStackView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var rootStack: UIStackView!
    @IBOutlet weak var bottomButtonsStack: UIStackView!
    @IBOutlet weak var pointsCount: UILabel!

    let program: RewardsProgram

    init(program: RewardsProgram) {
        self.program = program
        super.init(nibName: nil, bundle: nil)
    }
        
    init?(coder: NSCoder, program: RewardsProgram) {
        self.program = program
        super.init(coder: coder)
    }

    @available(*, unavailable, renamed: "init(coder:program:)")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 8, trailing: 10)
        bottomButtonsStack.isLayoutMarginsRelativeArrangement = true
        imageView.image = UIImage(systemName: program.imageName)!
        slider.preferredBehavioralStyle = .pad
        self.title = program.name
        self.titleLabel.text = program.name
        slider.minimumValue = 0
        slider.maximumValue = Float(program.points)
        pointsCount.text = String(slider.value)
        configureMenu()
        styleButtons()
        multiplierToggleButton.configuration?.baseBackgroundColor = UIColor.tintColor
        slider.value = Float(program.points / 2)
        updatePointsLabel()
    }
    
    @IBAction func pointsMultiplierToggled(_ sender: Any) {
        guard let toggleButton = sender as? UIButton else { return }
        if toggleButton.isSelected {
            selectedMultiplierIndex = 0
        } else {
            selectedMultiplierIndex = nil
        }
    }

    @IBAction func sliderAction(_ sender: Any) {
        updatePointsLabel()
    }

    @IBAction func redeemOption(_ sender: Any) { }

    @IBAction func donateOption(_ sender: Any) { }

    @IBAction func cashOutOption(_ sender: Any) { }

    // MARK: - View State
    private func updateState() {
        configureMenu()
        if let index = selectedMultiplierIndex {
            multiplierToggleButton.isSelected = true
            slider.setThumbImage("⚡️".image(textStyle: .title2), for: .normal)
            slider.minimumTrackTintColor = RewardsProgramDetailViewController.sliderPatternColor
            if index == 2 {
                // Activate "Mega Extreme Mode" if the user selects to 6× their points!
                view.tintColor = .systemRed
            } else {
                view.tintColor = nil
            }
        } else {
            multiplierToggleButton.isSelected = false
            slider.setThumbImage(nil, for: .normal)
            slider.minimumTrackTintColor = nil
            view.tintColor = nil
        }
        updatePointsLabel()
    }

    private let formatter: NumberFormatter = {
        let thousandsSeparatorNoDecimal = NumberFormatter()
        thousandsSeparatorNoDecimal.allowsFloats = false
        thousandsSeparatorNoDecimal.usesGroupingSeparator = true
        thousandsSeparatorNoDecimal.groupingSize = 3
        thousandsSeparatorNoDecimal.groupingSeparator = ","
        return thousandsSeparatorNoDecimal
    }()

    private func updatePointsLabel() {
        let multiplier: Float
        switch selectedMultiplierIndex {
        case 0:
            multiplier = 2
        case 1:
            multiplier = 3
        case 2:
            multiplier = 6
        default:
            multiplier = 1
        }

        pointsCount.text = formatter.string(from: NSNumber(value: slider.value * multiplier))
    }

    private func configureMenu() {
        multiplierActions.forEach { $0.state = .off }
        if let selectedMultiplierIndex = selectedMultiplierIndex {
            multiplierActions[selectedMultiplierIndex].state = .on
        }
        let menu = UIMenu(options: [], children: multiplierActions)
        multiplierToggleButton.menu = menu
    }

    /// These UIActions are reused each time the button's menu has to be recreated. We simply set the selection state on the selected item, if any,
    /// then they are copied as part of the button's menu copy when it is set.
    private lazy var multiplierActions: [UIAction] = {
        let children = ["2×", "3×", "6×"].map { title -> UIAction in
            UIAction(title: title, state: .off) { [weak self] action in
                switch action.title {
                case "2×":
                    self?.selectedMultiplierIndex = 0
                case "3×":
                    self?.selectedMultiplierIndex = 1
                case "6×":
                    self?.selectedMultiplierIndex = 2
                default:
                    self?.selectedMultiplierIndex = nil
                }
            }
        }
        return children
    }()

    private var selectedMultiplierIndex: Int? {
        didSet {
            updateState()
        }
    }

    private func styleButtons() {
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 60)
        // Adjusts the background color for any button configuration to reflect the selected state.
        let colorUpdateHandler: (UIButton) -> Void = { button in
            button.configuration?.baseBackgroundColor = button.isSelected ? UIColor.tintColor : UIColor.tintColor.withAlphaComponent(0.4)
        }

        zip([bottomLeft, bottomRight, topLeft, topRight], ["bed.double", "bag", "leaf", "bus.doubledecker"]).forEach { button, symbolName in
            buttonConfig.image = UIImage(systemName: symbolName)
            button!.configuration = buttonConfig
            button!.changesSelectionAsPrimaryAction = true
            button!.configurationUpdateHandler = colorUpdateHandler
            button?.preferredBehavioralStyle = .pad
        }
    }
    
    // MARK: Printing

    private func itemsToPrint() -> [AnyModelItem] {
        let itemsToPrint = [AnyModelItem(program)]
        return itemsToPrint
    }
    
    // This action will only be used when the RewardsProgramDetailViewController is firstResponder. This mainly happens if it has been opened in its
    // own window scene.
    override func printContent(_: Any?) {
        let renderer = ItemPrintPageRenderer(items: itemsToPrint())
        
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.orientation = .portrait
        info.jobName = program.name
        
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printPageRenderer = renderer
        printInteractionController.printInfo = info
        
        printInteractionController.present(animated: true)
    }
}
