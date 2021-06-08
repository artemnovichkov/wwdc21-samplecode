/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for gameplay.
*/

import UIKit
import GameKit

protocol GameControllerDelegate: AnyObject {
    func endGame()
}

class GameViewController: UIViewController, GameControllerDelegate {
    weak var titleScreenDelegate: TitleScreenControllerDelegate?

    func endGame() {
        titleScreenDelegate?.dismissGame()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let view = self.view as? SKView else { return }
        
        // Configure and present the game scene.
        let scene = GameScene(size: view.bounds.size, gameController: self)
        scene.scaleMode = .aspectFill
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
    }
}
