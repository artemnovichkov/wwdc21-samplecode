/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller implementation for the HapticRicochet app.
*/

import UIKit

import CoreHaptics
import CoreMotion

import Combine

class ViewController: UIViewController, UICollisionBehaviorDelegate {
    
    // A single circular view that represents the sphere.
    var sphereView: UIView!
    var spherePositionPublisher: Cancellable?
    let kSphereRadiusSmall: CGFloat = 39
    let kSphereRadiusLarge: CGFloat = 78
    let kSphereColor = #colorLiteral(red: 0.9696919322, green: 0.654135406, blue: 0.5897029042, alpha: 1)
    let kShieldColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
    let kSphereImplosionColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 0)
    let kMaxShieldWidth: CGFloat = 15
    
    var isAnimating = false
    
    private let kDisabledBackgroundColor = UIColor.systemBackground
    private let kEnabledBackgroundColor = UIColor.systemBackground
    private var enabledImageView: UIImageView?
    
    enum SphereState {
        case none
        case small
        case large
        case shield
    }
    
    var sphereState: SphereState = .none
    var rollingTextureEnabled = false
    
    // The haptic engine and state.
    var engine: CHHapticEngine!
    var engineNeedsStart = true
    var spawnPlayer: CHHapticPatternPlayer!
    var growPlayer: CHHapticPatternPlayer!
    var shieldPlayer: CHHapticPatternPlayer!
    var implodePlayer: CHHapticPatternPlayer!
    var collisionPlayerSmall: CHHapticPatternPlayer!
    var collisionPlayerLarge: CHHapticPatternPlayer!
    var collisionPlayerShield: CHHapticPatternPlayer!
    var texturePlayer: CHHapticPatternPlayer!
    
    lazy var supportsHaptics: Bool = {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()
    
    // An animator that the app uses.
    var animator: UIDynamicAnimator!
    
    // The behaviors to give the sphere physical realism.
    var gravity: UIGravityBehavior!
    var wallCollisions: UICollisionBehavior!
    var bounce: UIDynamicItemBehavior!
    
    // Properties to manage motion data from the accelerometer and gyroscope.
    var motionManager: CMMotionManager!
    var motionQueue: OperationQueue!
    var motionData: CMAccelerometerData!
    
    private var foregroundToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    
    // Properties to track the screen dimensions.
    lazy var windowWidth: CGFloat = { UIScreen.main.bounds.size.width }()
    lazy var windowHeight: CGFloat = { UIScreen.main.bounds.size.height }()

    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var prefersStatusBarHidden: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = kDisabledBackgroundColor
        initializeBackgroundImage()
        
        // Create and configure haptics before doing anything else, because the game begins immediately.
        createAndStartHapticEngine()
        initializeSpawnHaptics()
        initializeGrowHaptics()
        initializeShieldHaptics()
        initializeImplodeHaptics()
        initializeTextureHaptics()
        initializeCollisionHaptics()
        
        initializeSphere()
        initializeWalls()
        initializeBounce()
        initializeGravity()
        initializeAnimator()
        activateAccelerometer()
        
        addGestureRecognizers()
        addObservers()
        // Place the sphere at the center of the screen to start.
        spawn(view.center)
    }
    
    // Load and configure the background texture image.
    private func initializeBackgroundImage() {
        let backgroundImagePath = Bundle.main.path(forResource: "Dots - Coarse",
                                                           ofType: "png")!
        let backgroundImage = UIImage(contentsOfFile: backgroundImagePath)!
        enabledImageView = UIImageView(image: backgroundImage)
        enabledImageView!.contentMode = .scaleAspectFill
        enabledImageView!.frame = view.frame
        view.addSubview(enabledImageView!)
        enabledImageView!.isHidden = true
    }
    
    private func initializeSphere() {
        sphereView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        sphereView.backgroundColor = kSphereColor
        sphereView.layer.borderColor = kShieldColor.cgColor
        view.addSubview(sphereView)
        
        spherePositionPublisher = sphereView.publisher(for: \.layer.position)
            .sink() { position in self.handleSpherePositionChanged() }
    }
    
    @objc
    func handleSpherePositionChanged() {
        guard supportsHaptics, bounce != nil else { return }
        
        updateTexturePlayer(normalizedSphereVelocity)
    }
    
    // MARK: - UICollisionBehaviorDelegate
    
    func collisionBehavior(_ behavior: UICollisionBehavior,
                           beganContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?,
                           at point: CGPoint) {
        // Play collision haptic for supported devices.
        guard supportsHaptics && sphereState != .none else { return }

        playCollisionHaptic(normalizedSphereVelocity)
        
        if sphereState == .shield {
            if sphereView.layer.borderWidth > 0 {
                playShieldDamageAnimation(normalizedSphereVelocity)
            } else {
                let explosionThreshold: CGFloat = 0.2
                if CGFloat(normalizedSphereVelocity) >= explosionThreshold {
                    implode()
                }
            }
        }
    }
    
    @objc
    private func sphereTapped(_ tap: UITapGestureRecognizer) {
        guard !isAnimating else { return }
        
        switch sphereState {
        case .small:
            grow()
        case .large:
            shield()
        default:
            print("No action for the tap gesture during: \(sphereState)")
        }
    }
    
    @objc
    private func backgroundTapped(_ tap: UITapGestureRecognizer) {
        guard !isAnimating else { return }
        
        if sphereState == .none {
            spawn(tap.location(in: view))
        } else {
            if rollingTextureEnabled {
                rollingTextureEnabled = false
                view.backgroundColor = kDisabledBackgroundColor
                enabledImageView?.isHidden = true
                switch sphereState {
                case .none:
                    break
                case .small, .large, .shield:
                    stopPlayer(texturePlayer)
                }
            } else {
                rollingTextureEnabled = true
                view.backgroundColor = kEnabledBackgroundColor
                enabledImageView?.isHidden = false
                switch sphereState {
                case .none:
                    break
                case .small, .large, .shield:
                    startTexturePlayerIfNecessary()
                }
            }
        }
    }
    
    private func addGestureRecognizers() {
        let sphereTap = UITapGestureRecognizer(target: self, action: #selector(sphereTapped))
        sphereView.addGestureRecognizer(sphereTap)
        
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(backgroundTap)
    }
    
    private func addObservers() {
        backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                 object: nil,
                                                                 queue: nil) { [weak self] _ in
            guard let self = self, self.supportsHaptics else { return }
            
            self.stopHapticEngine()

        }

        foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                 object: nil,
                                                                 queue: nil) { [weak self] _ in
            guard let self = self, self.supportsHaptics else { return }
                                                                    
            self.restartHapticEngine()
            self.startTexturePlayerIfNecessary()
        }
    }
}
