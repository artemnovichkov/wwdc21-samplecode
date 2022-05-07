/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for the game.
*/

import SceneKit
import UIKit
import GameController

class GameViewControllerTVOS: GCEventViewController {
    var gameView: SCNView? {
        return view as? SCNView
    }
    var gameController: GameController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let gameView = self.gameView else { return }
        
        gameController = GameController(scnView: gameView)

        // Configure the view's background.
        gameView.backgroundColor = UIColor.black
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, and so on that aren't in use.
    }
}
