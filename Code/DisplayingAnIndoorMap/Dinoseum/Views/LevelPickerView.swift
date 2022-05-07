/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view displays IMDF level names as vertically-stacked buttons.
*/

import UIKit

@objc protocol LevelPickerDelegate: class {
    func selectedLevelDidChange(selectedIndex: Int)
}

class LevelPickerView: UIView {
    @IBOutlet weak var delegate: LevelPickerDelegate?
    @IBOutlet var backgroundView: UIVisualEffectView!
    @IBOutlet var stackView: UIStackView!

    var levelNames: [String] = [] {
        didSet {
            self.generateStackViewButtons()
        }
    }

    private var buttons: [UIButton] = []
    var selectedIndex: Int? {
        didSet {
            if let oldIndex = oldValue {
                buttons[oldIndex].backgroundColor = nil
            }

            if let index = selectedIndex {
                buttons[index].backgroundColor = UIColor(named: "LevelPickerSelected")
                delegate?.selectedLevelDidChange(selectedIndex: index)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        backgroundView.layer.cornerRadius = 10
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 3.0

        super.awakeFromNib()
    }

    private func generateStackViewButtons() {
        // Remove the existing stack view items, as we will re-create things from scratch.
        let existingViews = stackView.arrangedSubviews
        for view in existingViews {
            stackView.removeArrangedSubview(view)
        }
        buttons.removeAll()

        for (index, levelName) in levelNames.enumerated() {
            let levelButton = UIButton(type: .custom)
            levelButton.setTitle(levelName, for: .normal)
            levelButton.setTitleColor(.label, for: .normal)
            levelButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            // Associate the button with the index in the input list so we can reference it later.
            // Using 'tag' because all the buttons are private and controlled entirely by this control, and because the tag
            // property is only used for one purpose, to associate the index of a level with a button when it's been tapped.
            levelButton.tag = index

            stackView.addArrangedSubview(levelButton)
            levelButton.addTarget(self, action: #selector(levelSelected(sender:)), for: .primaryActionTriggered)

            // Add a separator view between each button.
            if index < levelNames.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor.separator
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }

            buttons.append(levelButton)
        }
    }
    
    @objc
    private func levelSelected(sender: UIButton) {
        let selectedIndex = sender.tag
        precondition(selectedIndex >= 0 && selectedIndex < levelNames.count)
        self.selectedIndex = selectedIndex
    }
}
