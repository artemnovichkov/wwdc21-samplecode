/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for the game's title screen.
*/

import UIKit
import GameKit

protocol TitleScreenControllerDelegate: AnyObject {
    func dismissGame()
}

class TitleScreenViewController: UIViewController, GKLocalPlayerListener, GKGameCenterControllerDelegate, TitleScreenControllerDelegate {

    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var titleStackView: UIStackView!
    @IBOutlet var titleStackViewCenterX: NSLayoutConstraint!
    @IBOutlet var titleStackViewCenterY: NSLayoutConstraint!
    @IBOutlet var titleStackViewWidth: NSLayoutConstraint!

    @IBOutlet var backgroundImageLeading: NSLayoutConstraint!
    @IBOutlet var backgroundImageTop: NSLayoutConstraint!
    
    var gameVC: GameViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBackground(size: view.frame.size)
        
        let myBlendLayer = playButton.layer
        myBlendLayer.setValue(false, forKey: "allowsGroupBlending")
        myBlendLayer.compositingFilter = "linearLightBlendMode"
        myBlendLayer.allowsGroupOpacity = false

        GKAccessPoint.shared.isActive = true
        GKAccessPoint.shared.location = .topLeading
        authenticateLocalPlayer()
    }

    func updateBackground(size: CGSize) {
        guard size.width > size.height else { return }
        backgroundImageTop.constant = 0
        backgroundImageLeading.constant = size.width - (2436.0 / 1125.0) * size.height
        backgroundImage.image = #imageLiteral(resourceName: ("titlebkgnd.landscape"))
        titleStackViewCenterX.constant = -size.width / 7
        titleStackViewCenterY.constant = 0
        titleStackViewWidth.constant = size.width * 0.38
        titleStackView.spacing = 20
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            self.updateBackground(size: size)
        })
    }

    @IBAction func showGameVC(_ sender: UIButton) {
        if let gameVC = storyboard?.instantiateViewController(identifier: "GameViewController") as? GameViewController {
            gameVC.titleScreenDelegate = self
            self.gameVC = gameVC
            GKAccessPoint.shared.isActive = false
            present(gameVC, animated: true)
        }
    }
    
    // MARK: TitleScreenController delegate methods
    func dismissGame() {
        gameVC?.dismiss(animated: true) {
            GKAccessPoint.shared.isActive = true
        }
    }
    
    // MARK: GameKit delegate methods
    
    // Uncomment the body of this method after you configure a Game Center feature, such as
    // leaderboards, in App Store Connect. For more information
    // on authentication, see
    // https://developer.apple.com/documentation/gamekit/authenticating_a_player.
    func authenticateLocalPlayer() {
        /*
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                self.view?.window?.rootViewController?.present(viewController, animated: true)
            } else if localPlayer.isAuthenticated {
                NSLog("local player is authenticated")
                localPlayer.register(self)
            } else {
                NSLog("player is not authenticated!!!")
            }
        }
         */
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
