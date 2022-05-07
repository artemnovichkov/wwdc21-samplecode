/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for the game.
*/

import Cocoa
import SceneKit

class GameViewControllerMacOS: NSViewController {
    var gameView: GameViewMacOS {
        guard let gameView = view as? GameViewMacOS else {
            fatalError("Expected \(GameViewMacOS.self) from Main.storyboard.")
        }
        return gameView
    }
    
    var gameController: GameController?

    override func viewDidLoad() {
        super.viewDidLoad()

        gameController = GameController(scnView: gameView)

        // Set the view's backround.
        gameView.backgroundColor = NSColor.black

        // Link the view and controller together.
        gameView.viewController = self
    }
}

class GameViewMacOS: SCNView {
    weak var viewController: GameViewControllerMacOS?

    // MARK: - EventHandler
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        (overlaySKScene as? Overlay)?.layout2DOverlay()
    }

    override func viewDidMoveToWindow() {
        // Disable on retina.
        layer?.contentsScale = 1.0
    }
}
