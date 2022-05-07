/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A specalized collection view cell containing an Add to Siri button.
*/

import UIKit
import IntentsUI
import SoupKit

class AddToSiriCollectionViewCell: UICollectionViewCell {
    var data: (OrderSoupIntent?, INUIAddVoiceShortcutButtonDelegate?) {
        didSet {
            setNeedsUpdateConfiguration()
        }
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        var content = AddToSiriCellContentConfiguration().updated(for: state)
        content.intent = data.0
        content.delegate = data.1
        contentConfiguration = content
    }
}

struct AddToSiriCellContentConfiguration: UIContentConfiguration, Hashable {
    
    var intent: OrderSoupIntent?
    weak var delegate: INUIAddVoiceShortcutButtonDelegate?
    
    func makeContentView() -> UIView & UIContentView {
        return AddToSiriCollectionViewCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
    
    static func == (lhs: AddToSiriCellContentConfiguration, rhs: AddToSiriCellContentConfiguration) -> Bool {
        return lhs.intent == rhs.intent
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(intent)
    }
}

private class AddToSiriCollectionViewCellContentView: UIView, UIContentView {

    init(configuration: AddToSiriCellContentConfiguration) {
        super.init(frame: .zero)
        apply(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? AddToSiriCellContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }
    
    private var addShortcutButton: INUIAddVoiceShortcutButton! = nil
    
    private var appliedConfiguration: AddToSiriCellContentConfiguration!
    
    private func apply(configuration: AddToSiriCellContentConfiguration) {
        guard appliedConfiguration != configuration else { return }
        appliedConfiguration = configuration
        guard let orderSoupIntent = appliedConfiguration.intent else { return }

        addShortcutButton = INUIAddVoiceShortcutButton(style: .automaticOutline)
        addShortcutButton.shortcut = INShortcut(intent: orderSoupIntent)
        addShortcutButton.delegate = configuration.delegate

        addShortcutButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(addShortcutButton)
        centerXAnchor.constraint(equalTo: addShortcutButton.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: addShortcutButton.centerYAnchor).isActive = true
        heightAnchor.constraint(equalTo: addShortcutButton.heightAnchor).isActive = true
        addShortcutButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 146).isActive = true
        
        backgroundColor = .systemGroupedBackground
    }
}
