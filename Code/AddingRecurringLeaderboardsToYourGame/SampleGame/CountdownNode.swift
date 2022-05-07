/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SpriteKit node that displays a seconds-precise countdown to 0.
*/

import SpriteKit

// Displays a label node that counts down for the specified amount of time.
// When countdown ends, invoke the appropriate method on the
// countdown delegate.
class CountdownNode: SKNode {
    let countdownLabel = SKLabelNode()
    var currentSeconds: Int

    weak var countdownDelegate: CountdownDelegate?

    init(minutes: Int,
         seconds: Int,
         position: CGPoint,
         delegate: CountdownDelegate) {
        self.countdownDelegate = delegate
        self.currentSeconds = minutes * 60 + seconds
        super.init()
        self.zPosition = 1
        self.position = position

        countdownLabel.zPosition = 4
        countdownLabel.position = CGPoint(x: 0, y: 0)
        countdownLabel.name = "countdown"
        countdownLabel.alpha = 1
        self.addChild(countdownLabel)

        countdown()
    }

    // Run the actions that update the countdown text every second,
    // and finish when the number of seconds reaches 0.
    func countdown() {
        if currentSeconds == 0 {
            removeAllChildren()
            countdownDelegate?.timeIsUp()
            return
        }
        countdownLabel.run(SKAction.sequence([
            SKAction.run {
                self.setCountdownText()
                self.currentSeconds -= 1
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                self.countdown()
            }
        ]))
    }
    
    func setCountdownText() {
        // Use an `NSAttributedString` object with a shadow for the countdown label.
        let shadow = NSShadow()
        shadow.shadowColor = #colorLiteral(red: 0.17, green: 0.18, blue: 0.25, alpha: 1)
        shadow.shadowOffset = CGSize(width: -5, height: -5)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.shadow: shadow,
            NSAttributedString.Key.font: UIFont(name: "Copperplate", size: 30) ?? UIFont.boldSystemFont(ofSize: 30),
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.61, green: 0.62, blue: 0.67,alpha: 1),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        // Compute the minutes and seconds left; pad the seconds string with
        // an extra '0' if remaining seconds is a single digit.
        let minutes = self.currentSeconds / 60
        let seconds = self.currentSeconds % 60
        let secondsStr = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        countdownLabel.attributedText = NSAttributedString(string: "\(minutes):\(secondsStr)",
                                                           attributes: attributes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
