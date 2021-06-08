/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The popover view controller to describe each menu choice in MenuViewController.
*/

import UIKit

class DescriptionPopoverViewController: UIViewController {

    private let _title: String
    private let _description: String

    init(withTitle title: String, description: String) {
        self._title = title
        self._description = description
        super.init(nibName: nil, bundle: nil)

        let closeCommand = UIKeyCommand(title: "Close popover", action: #selector(close), input: UIKeyCommand.inputEscape)
        self.addKeyCommand(closeCommand)

        // Also trigger on tab. The popover is the only item that would potentially be focusable right now, so we don't
        // block the focus system. Users may want to 'tab' into the sidebar again though, so handle this like escape.
        let tabCommand = UIKeyCommand(action: #selector(close), input: "\t")
        tabCommand.wantsPriorityOverSystemBehavior = true
        self.addKeyCommand(tabCommand)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        self.view.addSubview(titleLabel)

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.numberOfLines = 0
        self.view.addSubview(descriptionLabel)

        let padding = 20.0

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),

            descriptionLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            descriptionLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),

            titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: padding),
            descriptionLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1.0),
            descriptionLabel.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -padding)
        ])

        titleLabel.text = self._title
        descriptionLabel.text = self._description
    }

    override var preferredContentSize: CGSize {
        get {
            self.view.systemLayoutSizeFitting(
                CGSize(width: 320.0, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel)
        }
        set {
            self.preferredContentSize = newValue
        }
    }

    @objc
    func close() {
        self.dismiss(animated: true)
    }

}
