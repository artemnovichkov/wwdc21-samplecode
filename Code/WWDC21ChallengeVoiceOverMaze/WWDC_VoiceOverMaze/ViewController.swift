/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that sets up the main interface.
*/

import UIKit

class ViewController: UIViewController {

    var instructionsLabel: UILabel!
    var titleLabel: UILabel!
    var scrollView: UIScrollView!
    var startButton: VoiceOverActivatableButton!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .white
        titleLabel.text = NSLocalizedString("InitialInstructionsTitle", comment: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.minimumContentSizeCategory = .accessibilityLarge
        titleLabel.sizeToFit()

        instructionsLabel = UILabel()
        instructionsLabel.font = UIFont.preferredFont(forTextStyle: .body)
        instructionsLabel.textColor = .white
        instructionsLabel.text = NSLocalizedString("InitialInstructionsContent", comment: "")
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .center
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.adjustsFontForContentSizeCategory = true
        instructionsLabel.minimumContentSizeCategory = .accessibilityLarge
        instructionsLabel.sizeToFit()

        startButton = VoiceOverActivatableButton()
        startButton.setTitleColor(.white, for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle(NSLocalizedString("EnterButton", comment: ""), for: .normal)
        startButton.activatedHandler = {
            let controller = MazeViewController(nibName: nil, bundle: nil)
            self.present(controller, animated: true, completion: nil)
        }
        startButton.sizeToFit()
        startButton.layer.borderColor = UIColor.white.cgColor
        startButton.layer.borderWidth = 2.0
        startButton.layer.cornerRadius = 8.0
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceHorizontal = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.view.setNeedsLayout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black

        scrollView.addSubview(instructionsLabel)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        view.addSubview(startButton)

        let guide = self.view.safeAreaLayoutGuide
        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            scrollView.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9),
            scrollView.heightAnchor.constraint(lessThanOrEqualTo: guide.heightAnchor, multiplier: 0.9),
            scrollView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -20),

            instructionsLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: 0),
            instructionsLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: 0),

            startButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -50),
            startButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            startButton.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9)
        ]
        
        NSLayoutConstraint.activate(constraints)
        self.accessibilityElements = [ titleLabel!, instructionsLabel!, startButton! ]
    }
    
     override func viewDidLayoutSubviews() {
        scrollView.contentSize = instructionsLabel.frame.size
         if instructionsLabel.frame.origin.y < 0 {
             scrollView.contentInset.top = -instructionsLabel.frame.origin.y
             scrollView.contentOffset.y = instructionsLabel.frame.origin.y
         } else {
             scrollView.contentInset.top = 0
             scrollView.contentOffset.y = 0

         }
     }

}

