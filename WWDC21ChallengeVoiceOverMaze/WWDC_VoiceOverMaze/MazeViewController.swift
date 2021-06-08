/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that sets up the maze.
*/

import UIKit

struct ButtonInfo {
    enum Decision {
        case dive, leavePool, left, right, straight, turnBack, enter
    }
    var decision: Decision
    var nextStage: Int
    
    func decisionLabel() -> String {
        switch decision {
        case .dive:
            return "Dive"
        case .leavePool:
            return "Leave Pool"
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .straight:
            return "Straight"
        case .turnBack:
            return "Turn Back"
        case .enter:
            return "Enter"
        }
    }
}

class MazeViewController: UIViewController {

    class ButtonAccessibilityElement: UIAccessibilityElement {
        var buttonInfo: ButtonInfo?
        weak var mazeController: MazeViewController?
                
        override func accessibilityActivate() -> Bool {
            guard let mazeController = self.mazeController else {
                return false
            }
            guard let buttonInfo = buttonInfo else {
                return false
            }

            mazeController.initializeStage(buttonInfo.nextStage)
            return true
        }
    }

    var instructionLabel: UILabel?
    private func instructionString(_ stage: Int) -> String? {
        let instructions: [Int: String] = [
            1: """
                You wake up a small pool of water. The dulcitone sounds of birds and squirrels nibbling on your toes
                brings your awareness back. What do you want to do?
                """,
            2: "The pool is only a few inches deep. You scrape your knees.",
            3: "You come to a compacted dirt pathway. Your fingers reach out to let the native flora slip effortless through your grasp.",
            4: "You walk for a minute past an apple orchard. Each apple has been grown to exacting specifications. You reach an intersection.",
            5: "You walk past a dense forest. A ground squirrel eyes you warily before attacking. You're forced to turn back.",
            6: "You meander down a meandering path. Turkey vultures circle in formation above you. You reach an intersection.",
            7: "You start walking down a long curved path. Eventually you start running. After thirty minutes you reach an intersection.",
            8: "You look up and see curved glass stretching as far as the eye can see. In the distance is a door.",
            9: "You pass a gaggle of chairs and tables meant for outdoor dining and reach an intersection.",
            10: "You pass chairs and tables meant for gastronomical indulgence. You reach a crossroads.",
            11: "The pathway opens up and in the dazzling sun, a giant expanse of glass extends to the horizon. A door can be seen in the distance.",
            12: """
                As you begin to walk, you notice the pathway has a single-digit degree curvature. After thirty minutes you
                reach an intersection near an orchard.
                """,
            13: "The cool indoor air refreshes your senses. You think you may yet escape. You follow a squeaky concrete floor past many doors.",
            14: "You walk until you reach a set of glass doors. The doors are locked and rattling them has no effect on their disposition.",
            15: "You reach a small indoor cafe. You attempt to procure a glass of water, but you don't have the proper access codes.",
            16: "A gush of mellifluous air buffets you. You make your way down a pristine concrete hallway.",
            17: """
                You reach a locked set of glass doors. The metal bars, while yielding under pressure, offer no passage further.
                You're forced to turn back.
                """,
            18: """
                As you look up, you notice sunlight streaming through a wide set of doors. You start to run and as you burst forth,
                you realize you've escaped from Castle Park. Only three months have elapsed.
                """
        ]
        return instructions[stage]
    }
    
    private func buttonInfo(_ stage: Int) -> [ButtonInfo]? {
        let buttons: [Int: [ButtonInfo]] = [
            1: [ButtonInfo(decision: .dive, nextStage: 2), ButtonInfo(decision: .leavePool, nextStage: 3)],
            2: [ButtonInfo(decision: .leavePool, nextStage: 3)],
            3: [ButtonInfo(decision: .left, nextStage: 4), ButtonInfo(decision: .straight, nextStage: 5),
                 ButtonInfo(decision: .right, nextStage: 6)],
            4: [ButtonInfo(decision: .left, nextStage: 7), ButtonInfo(decision: .straight, nextStage: 8),
                 ButtonInfo(decision: .right, nextStage: 9), ButtonInfo(decision: .turnBack, nextStage: 3)],
            5: [ButtonInfo(decision: .turnBack, nextStage: 3) ],
            6: [ButtonInfo(decision: .left, nextStage: 10), ButtonInfo(decision: .straight, nextStage: 11),
                 ButtonInfo(decision: .right, nextStage: 12), ButtonInfo(decision: .turnBack, nextStage: 3)],
            7: [ButtonInfo(decision: .left, nextStage: 3), ButtonInfo(decision: .straight, nextStage: 10),
                 ButtonInfo(decision: .right, nextStage: 11), ButtonInfo(decision: .turnBack, nextStage: 12)],
            8: [ButtonInfo(decision: .enter, nextStage: 16), ButtonInfo(decision: .turnBack, nextStage: 4)],
            9: [ButtonInfo(decision: .straight, nextStage: 12), ButtonInfo(decision: .turnBack, nextStage: 1),
                 ButtonInfo(decision: .left, nextStage: 11), ButtonInfo(decision: .right, nextStage: 6)],
            10: [ButtonInfo(decision: .straight, nextStage: 7), ButtonInfo(decision: .right, nextStage: 8),
                  ButtonInfo(decision: .left, nextStage: 4), ButtonInfo(decision: .turnBack, nextStage: 9)],
            11: [ButtonInfo(decision: .enter, nextStage: 13), ButtonInfo(decision: .turnBack, nextStage: 6)],
            12: [ButtonInfo(decision: .straight, nextStage: 9), ButtonInfo(decision: .left, nextStage: 8),
                  ButtonInfo(decision: .right, nextStage: 4), ButtonInfo(decision: .turnBack, nextStage: 6)],
            13: [ButtonInfo(decision: .left, nextStage: 15), ButtonInfo(decision: .right, nextStage: 14)],
            14: [ButtonInfo(decision: .turnBack, nextStage: 13)],
            15: [ButtonInfo(decision: .straight, nextStage: 16), ButtonInfo(decision: .right, nextStage: 18),
                  ButtonInfo(decision: .turnBack, nextStage: 11)],
            16: [ButtonInfo(decision: .left, nextStage: 17), ButtonInfo(decision: .right, nextStage: 15)],
            17: [ButtonInfo(decision: .turnBack, nextStage: 16)],
            18: []
            ]
        return buttons[stage]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.accessibilityViewIsModal = true
        view.backgroundColor = .black
        initializeStage(1)
    }
    
    private func showWinningUI() {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "challengeBadge"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = configureTitleLabel()
        let escapeLabel = configureEscapeLabel()
        let enjoyLabel = configureEnjoyLabel()
        let linkLabel = configureLinkLabel()

        self.view.addSubview(imageView)
        self.view.addSubview(titleLabel)
        self.view.addSubview(escapeLabel)
        self.view.addSubview(enjoyLabel)
        self.view.addSubview(linkLabel)
        
        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 100),
            imageView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9),

            escapeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            escapeLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            escapeLabel.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9),

            enjoyLabel.topAnchor.constraint(equalTo: escapeLabel.bottomAnchor, constant: 20),
            enjoyLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            enjoyLabel.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9),

            linkLabel.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -50),
            linkLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            linkLabel.widthAnchor.constraint(equalTo: guide.widthAnchor, multiplier: 0.9)
        ])
        
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
    
    func configureTitleLabel() -> UILabel {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = #colorLiteral(red: 0.52156863, green: 0.86666667, blue: 0.39215686, alpha: 1)
        titleLabel.text = NSLocalizedString("Congratulations", comment: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.minimumContentSizeCategory = .accessibilityLarge
        titleLabel.sizeToFit()
        
        return titleLabel
    }
    
    func configureEscapeLabel() -> UILabel {
        let escapeLabel = UILabel()
        escapeLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
        escapeLabel.textColor = .white
        escapeLabel.text = NSLocalizedString("ExitFromCastlePark", comment: "")
        escapeLabel.translatesAutoresizingMaskIntoConstraints = false
        escapeLabel.numberOfLines = 0
        escapeLabel.textAlignment = .center
        escapeLabel.adjustsFontForContentSizeCategory = true
        escapeLabel.minimumContentSizeCategory = .accessibilityLarge
        escapeLabel.sizeToFit()
        
        return escapeLabel
    }
    
    func configureEnjoyLabel() -> UILabel {
        let enjoyLabel = UILabel()
        enjoyLabel.font = UIFont(descriptor: (UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1).withSymbolicTraits(.traitBold))!,
                                 size: 0)
        enjoyLabel.textColor = .white
        enjoyLabel.text = NSLocalizedString("Enjoy", comment: "")
        enjoyLabel.translatesAutoresizingMaskIntoConstraints = false
        enjoyLabel.numberOfLines = 0
        enjoyLabel.textAlignment = .center
        enjoyLabel.adjustsFontForContentSizeCategory = true
        enjoyLabel.minimumContentSizeCategory = .accessibilityLarge
        enjoyLabel.sizeToFit()
        
        return enjoyLabel
    }
    
    func configureLinkLabel() -> UILabel {
        let linkLabel = UILabel()
        linkLabel.isUserInteractionEnabled = true
        linkLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(linkTap)))
        linkLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        linkLabel.textColor = .white
        let attrString = NSMutableAttributedString(string: NSLocalizedString("AccessibilityLink", comment: ""))
        attrString.setAttributes([.underlineStyle: NSNumber(1),
                                    .foregroundColor: UIColor.yellow ],
                                 range: NSRange(attrString.string.range(of: "developer.apple.com/accessibility")!,
                                                in: attrString.string))
        linkLabel.attributedText = attrString
        linkLabel.translatesAutoresizingMaskIntoConstraints = false
        linkLabel.numberOfLines = 0
        linkLabel.textAlignment = .center
        linkLabel.adjustsFontForContentSizeCategory = true
        linkLabel.sizeToFit()
        
        return linkLabel
    }
    
    @objc
    func linkTap() {
        UIApplication.shared.open(URL(string: "https://developer.apple.com/accessibility")!)
    }
    
    private func initializeStage(_ stage: Int) {
        guard stage != 18 else {
            self.view.accessibilityElements = nil
            self.showWinningUI()
            return
        }
        
        let instructionString = self.instructionString(stage)
        guard let buttons = self.buttonInfo(stage) else {
            return
        }
        
        var elements = [UIAccessibilityElement]()
        
        let instructions = UIAccessibilityElement(accessibilityContainer: self)
        instructions.accessibilityLabel = instructionString
        instructions.accessibilityFrameInContainerSpace = CGRect(x: 10, y: 50, width: Int(self.view.frame.size.width) - 20, height: 100)
        elements.append(instructions)
        
        var yPosition: Int = 200
        for buttonInfo in buttons {
            let element = ButtonAccessibilityElement(accessibilityContainer: self)
            element.buttonInfo = buttonInfo
            element.accessibilityLabel = buttonInfo.decisionLabel()
            element.mazeController = self
            element.accessibilityFrameInContainerSpace = CGRect(x: 10, y: yPosition, width: Int(self.view.frame.size.width) - 20, height: 100)
            yPosition += 100
            elements.append(element)
        }
        
        self.view.accessibilityElements = elements
        
        UIAccessibility.post(notification: .layoutChanged, argument: instructions)
    }
}
