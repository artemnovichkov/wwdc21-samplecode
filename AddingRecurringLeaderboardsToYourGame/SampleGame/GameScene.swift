/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The SpriteKit scene for gameplay.
*/

import GameKit
import SpriteKit

protocol GameMenuDelegate: AnyObject {
    func retry()
    func finish()
    func resume()
}

protocol CountdownDelegate: AnyObject {
    func timeIsUp()
}

class GameScene: SKScene, CountdownDelegate, GameMenuDelegate {
    let backgroundNode: SKSpriteNode = {
        let node = SKSpriteNode(imageNamed: "gamebackground")
        node.anchorPoint = CGPoint(x: 0, y: 0)
        return node
    }()
    static let unscaledBackgroundHeight = CGFloat(752)
    static let unscaledWaterHeight = CGFloat(64)

    let menuButton: SKNode = {
        let node: SKNode
        let color = #colorLiteral(red: 0.6, green: 0.62, blue: 0.67, alpha: 1)
        if let gearImage = UIImage(systemName: "gearshape.fill") {
            let tintedGearImage = gearImage.withTintColor(color)
            guard let tintedGearData = tintedGearImage.pngData(),
                  let tintedGearImage = UIImage(data: tintedGearData) else {
                fatalError("failed to construct menu button")
            }
            let texture = SKTexture(image: tintedGearImage)
            node = SKSpriteNode(texture: texture, size: CGSize(width: 35, height: 35))
        } else {
            // Fall back to using a plain circle if the gearshape can't be loaded.
            let temp = SKShapeNode(circleOfRadius: 35)
            temp.fillColor = color
            node = temp
        }
        node.name = "menuButton"
        node.zPosition = 1
        return node
    }()
    static let menuButtonXPos = CGFloat(0.95)
    static let menuButtonYPos = CGFloat(0.91)

    let scoreLabel: SKLabelNode = {
        let node = SKLabelNode()
        node.zPosition = 1
        node.name = "score"
        return node
    }()
    static let scoreLabelXPos = CGFloat(0.19)
    static let scoreLabelYPos = CGFloat(0.8)
    static let scoreFontSize = CGFloat(90)
    static let scoreFont = "Copperplate"
    static let scoreShadowWidth = CGFloat(-5)
    static let scoreShadowSize = CGSize(width: -5, height: -5)

    var backgroundOnScreen: CGRect?
    var boatSpawningBounds: CGRect?

    var countdownNode: CountdownNode?
    static let countdownXPos = CGFloat(0.87)
    static let countdownYPos = CGFloat(0.89)

    var boatNode: SKSpriteNode?

    var gameMenuNode: GameMenuNode?
    static let gameMenuSize = CGSize(width: 300, height: 200)

    // Use these properties to place a leaderboard node appropriately on the background.
    static let leaderboardSize = CGSize(width: 220, height: 150)
    var leaderboardPosition: CGPoint?

    weak var gameController: GameControllerDelegate?

    var score: Int = 0 {
        didSet {
            // When the score changes, update the corresponding label text.
            setScoreLabelText(score: score)
        }
    }

    init(size: CGSize, gameController: GameControllerDelegate) {
        self.gameController = gameController
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)

        let preScaleBackgroundSize = backgroundNode.size

        // Scale the background so that the entire height of the image exactly
        // fills the screen. This might cause the width of the image to exceed
        // the screen width (e.g., on the iPhone SE).
        let backgroundScale = view.frame.size.height / backgroundNode.size.height
        backgroundNode.yScale = backgroundScale
        backgroundNode.xScale = backgroundScale
        self.addChild(backgroundNode)

        // Compute how much width of the background node is offscreen due to
        // scaling based on height.
        let offscreenWidth = (backgroundNode.size.width - view.frame.size.width) / backgroundScale
        backgroundOnScreen = CGRect(origin: CGPoint(x: 0, y: 0),
                                    size: CGSize(width: preScaleBackgroundSize.width - offscreenWidth,
                                                 height: preScaleBackgroundSize.height))

        // Use the unscaled water height and the unscaled background height to
        // determine how much of the scaled background is water.
        boatSpawningBounds = CGRect(x: 0,
                                    y: 0,
                                    width: backgroundOnScreen!.width,
                                    height: backgroundOnScreen!.height * GameScene.unscaledWaterHeight / GameScene.unscaledBackgroundHeight)

        setupInitialGameplay()
    }

    // Add the score, countdown, and menu button on top of the background node,
    // and kick off the boat logic.
    // Use this when the view first appears, and when the game is retried.
    func setupInitialGameplay() {
        // Position the score label, set its text to the current score, and
        // add it as a child node to the background.
        //
        // In general, use the background as the parent for nodes so that
        // they scale appropriately with the background.
        scoreLabel.position = getPointOnBackground(GameScene.scoreLabelXPos, GameScene.scoreLabelYPos)
        setScoreLabelText(score: score)
        backgroundNode.addChild(scoreLabel)

        // Position the menu button and add it as a child node to the
        // background.
        menuButton.position = getPointOnBackground(GameScene.menuButtonXPos, GameScene.menuButtonYPos)
        backgroundNode.addChild(menuButton)

        // Configure the leaderboard postition to be used when adding a leaderboard node.
        leaderboardPosition = CGPoint(x: self.backgroundOnScreen!.width * 0.19 - GameScene.leaderboardSize.width / 2,
                                      y: self.backgroundOnScreen!.height * 0.53 - GameScene.leaderboardSize.height / 2)

        setupCountdown()
        setupBoatNodeWithActions()
    }

    // Create a countdown node with 1 minute, and place it in the top right on
    // the background node.
    func setupCountdown() {
        countdownNode = CountdownNode(minutes: 1,
                                      seconds: 0,
                                      position: getPointOnBackground(GameScene.countdownXPos, GameScene.countdownYPos),
                                      delegate: self)
        backgroundNode.addChild(countdownNode!)
    }

    // This method, along with `touchesEnded`, is the main driver of gameplay.
    // It kicks off a sequence of actions to repeatedly add a boat to the scene,
    // then remove it.
    func setupBoatNodeWithActions() {
        // Randomly pick a boat image to create a sprite with.
        let boatNode = SKSpriteNode(imageNamed: Bool.random() ? "boat1" : "boat2")
        self.boatNode = boatNode
        boatNode.name = "boat"
        
        // Randomly pick a position on the water of the background image to
        // spawn the boat at.
        guard let bounds = boatSpawningBounds else { return }
        boatNode.position = CGPoint(x: Int.random(in: 0..<Int(bounds.width)) + Int(bounds.origin.x),
                                    y: Int.random(in: 0..<Int(bounds.height)) + Int(bounds.origin.y))

        // Add the boat to the background, but keep it hidden for now.
        boatNode.alpha = 0
        boatNode.zPosition = 1
        boatNode.isHidden = true
        backgroundNode.addChild(boatNode)

        // Run a sequence of actions:
        // 1. Wait for a random amount of time in (1s, 3s]
        // 2. Unhide the boat node
        // 3. Fade the boat node into the scene
        // 4. Wait for a random amount of time in (2s, 6s]
        // 5. Remove the current boat node
        // 6. Set up a new boat node
        boatNode.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(Int.random(in: 1..<3))),
                                    SKAction.run {
                                        boatNode.isHidden = false
                                    },
            SKAction.fadeIn(withDuration: TimeInterval(1)),
            SKAction.wait(forDuration: TimeInterval(Int.random(in: 2..<6))),
                                    SKAction.run {
                                        self.backgroundNode.removeChildren(in: [boatNode])
                                        self.setupBoatNodeWithActions()
                                    }
        ]))
    }

    // If the game menu is up, pass along the touch.
    // Otherwise:
    //     if the boat node is touched, increment the score, remove the
    //         current boat, and setup a new boat.
    //     if the menu button is touched, pause everything on the background,
    //         create a game menu, and display it.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            if let menuNode = gameMenuNode {
                menuNode.handleTouch(touch: touch, touchEnded: true)
            } else {
                let location = touch.location(in: backgroundNode)
                let touchedNode = backgroundNode.atPoint(location)
                if touchedNode == boatNode {
                    self.backgroundNode.removeChildren(in: [touchedNode])
                    score += 1
                    setupBoatNodeWithActions()
                    return
                } else if touchedNode == menuButton {
                    self.backgroundNode.isPaused = true

                    // The game menu displays the current score, so it looks
                    // nicer to remove the score from the background.
                    self.backgroundNode.removeChildren(in: [scoreLabel])

                    gameMenuNode = GameMenuNode(score: score,
                                                position: CGPoint(x: backgroundOnScreen?.midX ?? 0,
                                                                  y: backgroundOnScreen?.midY ?? 0),
                                                size: GameScene.gameMenuSize,
                                                isFinished: false,
                                                delegate: self)
                    backgroundNode.addChild(gameMenuNode!)
                }
            }
        }
    }

    // Nothing during gameplay relies on the `touchesBegan` method, but if the game menu
    // is up, pass along the touch.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            gameMenuNode?.handleTouch(touch: touch, touchEnded: false)
        }
    }

    // Nothing during gameplay relies on `touchesMoved` method, but if the game menu
    // is up, pass along the touch.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            gameMenuNode?.handleTouch(touch: touch, touchEnded: false)
        }
    }

    // Clear the game menu, put the score label back, and unpause the game.
    func resume() {
        if let node = gameMenuNode {
            gameMenuNode = nil
            node.removeAllChildren()
            backgroundNode.removeChildren(in: [node])
        }
        backgroundNode.addChild(scoreLabel)
        backgroundNode.isPaused = false
    }

    // Clear the game menu and setup the game again.
    func retry() {
        if let node = gameMenuNode {
            backgroundNode.removeChildren(in: [node])
            gameMenuNode = nil
        }

        setupInitialGameplay()
    }

    // Clear the present scene, and end the game.
    func finish() {
        view?.presentScene(nil)
        gameController?.endGame()
    }

    // When time is up, remove all the nodes and actions from the background,
    // present the game menu, and reset the score back to 0.
    func timeIsUp() {
        backgroundNode.removeAllChildren()
        backgroundNode.removeAllActions()

        gameMenuNode = GameMenuNode(score: score,
                                    position: CGPoint(x: backgroundOnScreen?.midX ?? 0,
                                                      y: backgroundOnScreen?.midY ?? 0),
                                    size: GameScene.gameMenuSize,
                                    isFinished: true,
                                    delegate: self)
        backgroundNode.addChild(gameMenuNode!)
        score = 0
    }

    // Update the score label with the current score.
    func setScoreLabelText(score: Int) {
        // Use an `NSAttributedString` with a shadow attribute to make the label
        // look nice.
        let shadow = NSShadow()
        shadow.shadowColor = #colorLiteral(red: 0.17, green: 0.18, blue: 0.25, alpha: 1)
        shadow.shadowOffset = GameScene.scoreShadowSize
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let scoreAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.shadow: shadow,
            NSAttributedString.Key.font: UIFont(name: GameScene.scoreFont, size: GameScene.scoreFontSize) ??
                UIFont.boldSystemFont(ofSize: GameScene.scoreFontSize),
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.6, green: 0.62, blue: 0.67, alpha: 1),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        scoreLabel.attributedText = NSAttributedString(string: "\(score)", attributes: scoreAttributes)
    }

    // Use this to help position elements on screen.
    // x and y should be in [0, 1]. (0, 0) represents the bottom left
    // of the screen, and (1, 1) the top right.
    func getPointOnBackground(_ xPos: CGFloat, _ yPos: CGFloat) -> CGPoint {
        return CGPoint(x: xPos * backgroundOnScreen!.width,
                       y: yPos * backgroundOnScreen!.height)
    }
}
