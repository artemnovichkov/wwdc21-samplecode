/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SpriteKit node for displaying an in-game menu.
*/

import SpriteKit

// A `SKNode` object that displays a menu to the player consisting of:
// 1. The player's current score,
// 2. A 'Finish' label, for ending gameplay and going back to the title screen,
// 3. Either a 'Resume' label that resumes a paused game or
//    a 'Retry' label that starts a new game.
class GameMenuNode: SKNode {
    let backgroundNode: SKShapeNode

    let scoreNode: SKLabelNode
    static let scoreFontSize = CGFloat(90)
    static let scoreFont = "Copperplate-Light"
    static let scoreShadowWidth = CGFloat(-5)
    static let scoreShadowSize = CGSize(width: -5, height: -5)

    let finishNode: SKLabelNode
    let retryNode: SKLabelNode?
    let resumeNode: SKLabelNode?
    static let menuOptionFontSize = CGFloat(20)
    static let menuOptionFont = "Copperplate"
    static let menuOptionFontBold = "Copperplate-Bold"

    weak var gameMenuDelegate: GameMenuDelegate?

    init(score: Int,
         position: CGPoint,
         size: CGSize,
         isFinished: Bool,
         delegate: GameMenuDelegate) {
        self.gameMenuDelegate = delegate

        // Set up the background of the menu: a rectangle of specified size
        // with a hard-coded color.
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: 15)
        backgroundNode.fillColor = #colorLiteral(red: 0.48, green: 0.49, blue: 0.59, alpha: 0.7)
        backgroundNode.lineWidth = 0

        // Calculate these values to help align label nodes later.
        let quarterWidth = backgroundNode.frame.size.width / 4
        let eighthHeight = backgroundNode.frame.size.height / 8

        scoreNode = GameMenuNode.getScoreNode(score: score)
        backgroundNode.addChild(scoreNode)

        finishNode = GameMenuNode.getMenuOptionNode(name: "finish", text: "Finish")
        // Horizontally center the node in the middle of the left half of the
        // background. Vertically center the node in the bottom fourth of the
        // background.
        finishNode.position = CGPoint(x: -quarterWidth, y: -3 * eighthHeight)
        backgroundNode.addChild(finishNode)

        // If the game is finished, show the 'Retry' label; otherwise, show the 'Resume' label.
        // Horizontally center the node in the middle of the right half of the
        // background. Vertically center the node in the bottom fourth of the
        // background.
        if isFinished {
            retryNode = GameMenuNode.getMenuOptionNode(name: "retry", text: "Retry")
            retryNode!.position = CGPoint(x: quarterWidth, y: -3 * eighthHeight)
            resumeNode = nil
            backgroundNode.addChild(retryNode!)
        } else {
            resumeNode = GameMenuNode.getMenuOptionNode(name: "resume", text: "Resume")
            resumeNode!.position = CGPoint(x: quarterWidth, y: -3 * eighthHeight)
            retryNode = nil
            backgroundNode.addChild(resumeNode!)
        }

        super.init()
        self.position = position
        self.zPosition = 1

        self.addChild(backgroundNode)
    }

    // Instantiate and format a `SKLabelNode` object for the given score value.
    class func getScoreNode(score: Int) -> SKLabelNode {
        // Use an `NSAttributedString` object with a shadow for the score label.
        let scoreShadow = NSShadow()
        scoreShadow.shadowColor = #colorLiteral(red: 0.17, green: 0.18, blue: 0.25, alpha: 1)
        scoreShadow.shadowOffset = GameMenuNode.scoreShadowSize
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.shadow: scoreShadow,
            NSAttributedString.Key.font: UIFont(name: GameMenuNode.scoreFont, size: GameMenuNode.scoreFontSize) ??
                UIFont.systemFont(ofSize: GameMenuNode.scoreFontSize),
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        // No need to set a position for the score node; it's going to be right
        // in the center of the background node, which is the default position.
        let scoreNode = SKLabelNode()
        scoreNode.name = "score"
        scoreNode.attributedText = NSAttributedString(string: "\(score)", attributes: attributes)
        scoreNode.zPosition = 1
        return scoreNode
    }

    // Instantiate and format a `SKLabelNode` object for a menu option.
    class func getMenuOptionNode(name: String, text: String) -> SKLabelNode {
        let node = SKLabelNode()
        node.name = name
        node.text = text
        node.zPosition = 1
        node.fontSize = GameMenuNode.menuOptionFontSize
        node.fontName = GameMenuNode.menuOptionFont
        return node
    }

    // If the player touches a label, change its font to bold.
    // If the player's touch ends on a label, execute the corresponding action for that label.
    func handleTouch(touch: UITouch, touchEnded: Bool) {
        let position = touch.location(in: backgroundNode)
        let nodes = backgroundNode.nodes(at: position)

        // Start with all the labels unbolded.
        finishNode.fontName = GameMenuNode.menuOptionFont
        retryNode?.fontName = GameMenuNode.menuOptionFont
        resumeNode?.fontName = GameMenuNode.menuOptionFont

        // Bold whichever label is touched. Additionally, if `touchEnded` on a
        // node, call the corresponding `GameMenuDelegate` method.
        if nodes.contains(finishNode) {
            finishNode.fontName = GameMenuNode.menuOptionFontBold
            if touchEnded {
                gameMenuDelegate?.finish()
            }
        } else if retryNode != nil && nodes.contains(retryNode!) {
            retryNode?.fontName = GameMenuNode.menuOptionFontBold
            if touchEnded {
                gameMenuDelegate?.retry()
            }
        } else if resumeNode != nil && nodes.contains(resumeNode!) {
            resumeNode?.fontName = GameMenuNode.menuOptionFontBold
            if touchEnded {
                gameMenuDelegate?.resume()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
