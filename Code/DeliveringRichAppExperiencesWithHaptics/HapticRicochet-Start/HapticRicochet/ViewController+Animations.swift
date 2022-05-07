/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The animation portion of the HapticRicochet app.
*/

import UIKit

extension ViewController {
    
    private var wallPadding: CGFloat { return 1 }
    
    func initializeWalls() {
        wallCollisions = UICollisionBehavior(items: [sphereView])
        wallCollisions.collisionDelegate = self
        
        // Express the walls using vertices.
        let upperLeft = CGPoint(x: -wallPadding, y: -wallPadding)
        let upperRight = CGPoint(x: windowWidth + wallPadding, y: -wallPadding)
        let lowerRight = CGPoint(x: windowWidth + wallPadding, y: windowHeight + wallPadding)
        let lowerLeft = CGPoint(x: -wallPadding, y: windowHeight + wallPadding)
        
        // Each wall is a straight line shifted one pixel offscreen to give an impression of existing at the boundary.
        
        // The left edge of the screen.
        wallCollisions.addBoundary(withIdentifier: NSString("leftWall"),
                                   from: upperLeft,
                                   to: lowerLeft)
        
        // The right edge of the screen.
        wallCollisions.addBoundary(withIdentifier: NSString("rightWall"),
                                   from: upperRight,
                                   to: lowerRight)
        
        // The top edge of the screen.
        wallCollisions.addBoundary(withIdentifier: NSString("topWall"),
                                   from: upperLeft,
                                   to: upperRight)
        
        // The bottom edge of the screen.
        wallCollisions.addBoundary(withIdentifier: NSString("bottomWall"),
                                   from: lowerRight,
                                   to: lowerLeft)
    }
    
    // Each bounce against the wall is a dynamic item behavior, which lets you tweak the elasticity to match the haptic effect.
    func initializeBounce() {
        bounce = UIDynamicItemBehavior(items: [sphereView])
        
        // Increase the elasticity to make the sphere bounce higher.
        bounce.elasticity = 0.66
    }
    
    // Represent gravity as a behavior in UIKit Dynamics.
    func initializeGravity() {
        gravity = UIGravityBehavior(items: [sphereView])
    }
    
    // The animator ties the gravity, sphere, and wall, so UIKit Dynamics is aware of all components.
    func initializeAnimator() {
        animator = UIDynamicAnimator(referenceView: view)
    }
    
    // Play the spawn transformation.
    func spawn(_ location: CGPoint) {
        let newPosition = boundedSphereCenter(location: location,
                                              radius: kSphereRadiusSmall)
        sphereView.layer.position = newPosition
        isAnimating = true
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.curveEaseIn],
                       animations: {
            self.startPlayer(self.spawnPlayer)
            self.sphereView.bounds = CGRect(x: 0, y: 0,
                                            width: self.kSphereRadiusSmall * 2,
                                            height: self.kSphereRadiusSmall * 2)
            self.sphereView.layer.cornerRadius = self.kSphereRadiusSmall
        }, completion: { _ in
            self.addAnimationBehaviors()
            self.animator.updateItem(usingCurrentState: self.sphereView)
            self.isAnimating = false
            self.startTexturePlayerIfNecessary()
        })
        
        sphereState = .small
    }

    // Play the grow transformation.
    func grow() {
        stopPlayer(texturePlayer)
        removeAnimationBehaviors()
        isAnimating = true
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            self.startPlayer(self.growPlayer)
            let newPosition = self.boundedSphereCenter(location: self.sphereView.layer.position,
                                                       radius: self.kSphereRadiusLarge)
            self.sphereView.layer.position = newPosition
            self.sphereView.bounds = CGRect(x: 0, y: 0,
                                            width: self.kSphereRadiusLarge * 2,
                                            height: self.kSphereRadiusLarge * 2)
            self.sphereView.layer.cornerRadius = self.kSphereRadiusLarge
        }, completion: { _ in
            self.addAnimationBehaviors()
            self.animator.updateItem(usingCurrentState: self.sphereView)
            self.isAnimating = false
            self.startTexturePlayerIfNecessary()
        })
        
        sphereState = .large
    }
    
    // Play the shield transformation.
    func shield() {
        let shieldAnimation = CASpringAnimation(keyPath: "borderWidth")
        shieldAnimation.fromValue = 0
        shieldAnimation.toValue = kMaxShieldWidth
        shieldAnimation.duration = 0.5
        shieldAnimation.damping = 9
        shieldAnimation.initialVelocity = 20.0
        
        CATransaction.setCompletionBlock {
            self.addAnimationBehaviors()
            self.animator.updateItem(usingCurrentState: self.sphereView)
            self.isAnimating = false
            self.startTexturePlayerIfNecessary()
        }
        
        stopPlayer(texturePlayer)
        removeAnimationBehaviors()
        
        // Start the player for haptics and audio.
        startPlayer(shieldPlayer)
        
        // Play the shield animation.
        isAnimating = true
        sphereView.layer.add(shieldAnimation, forKey: "Width")
        sphereView.layer.borderWidth = kMaxShieldWidth
        sphereState = .shield
    }
    
    // Play the implode transformation.
    func implode() {
        stopPlayer(texturePlayer)
        removeAnimationBehaviors()
        isAnimating = true
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.startPlayer(self.implodePlayer)
            let expandFactor: CGFloat = 0.9
            self.sphereView.bounds = CGRect(x: 0, y: 0, width: self.kSphereRadiusLarge * (expandFactor * 2),
                                            height: self.kSphereRadiusLarge * (expandFactor * 2))
            self.sphereView.layer.cornerRadius = self.kSphereRadiusLarge * expandFactor
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                let expandFactor: CGFloat = 1.1
                let newPosition = self.boundedSphereCenter(location: self.sphereView.layer.position,
                                                           radius: self.kSphereRadiusLarge * expandFactor)
                self.sphereView.layer.position = newPosition
                
                self.sphereView.bounds = CGRect(x: 0, y: 0, width: self.kSphereRadiusLarge * (expandFactor * 2),
                                                height: self.kSphereRadiusLarge * (expandFactor * 2))
                self.sphereView.layer.cornerRadius = self.kSphereRadiusLarge * expandFactor
            }, completion: { _ in
                UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1.0,
                               initialSpringVelocity: 20.0, options: [.curveEaseOut], animations: {
                    self.sphereView.bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
                    self.sphereView.layer.cornerRadius = 0
                    self.sphereView.backgroundColor = self.kSphereImplosionColor
                }, completion: { _ in
                    self.animator.updateItem(usingCurrentState: self.sphereView)
                    self.isAnimating = false
                    self.sphereView.backgroundColor = self.kSphereColor
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                        if self.sphereState == .none && !self.isAnimating {
                            self.spawn(self.view.center)
                        }
                    })
                })
            })
        })
        
        sphereState = .none
    }
    
    func playShieldDamageAnimation(_ magnitude: Float) {
        let impactScaleFactor: CGFloat = 3.5
        let scaledImpact = CGFloat(magnitude) * impactScaleFactor
        let minImpact: CGFloat = 2
        let shrinkAmount = max(scaledImpact, minImpact)
        
        UIView.animate(withDuration: 0, delay: 0, options: [.curveEaseIn], animations: {
            if shrinkAmount >= self.sphereView.layer.borderWidth {
                self.sphereView.layer.borderWidth = 0
            } else {
                self.sphereView.layer.borderWidth -= shrinkAmount
            }
        }, completion: { _ in
            self.isAnimating = false
        })
    }
    
    private func addAnimationBehaviors() {
        // Add bounce, gravity, and collision behavior.
        animator.addBehavior(bounce)
        animator.addBehavior(gravity)
        animator.addBehavior(wallCollisions)
    }
    
    private func removeAnimationBehaviors() {
        // Remove bounce, gravity, and collision behavior.
        animator.removeBehavior(bounce)
        animator.removeBehavior(gravity)
        animator.removeBehavior(wallCollisions)
    }
    
    private func boundedSphereCenter(location: CGPoint, radius: CGFloat) -> CGPoint {
        var boundedPosition = location
        
        if location.x - radius < view.frame.minX + wallPadding {
            boundedPosition.x = view.frame.minX + wallPadding + radius
        }
        if location.x + radius > view.frame.maxX - wallPadding {
            boundedPosition.x = view.frame.maxX - wallPadding - radius
        }
        if location.y - radius < view.frame.minY + wallPadding {
            boundedPosition.y = view.frame.minY + wallPadding + radius
        }
        if location.y + radius > view.frame.maxY - wallPadding {
            boundedPosition.y = view.frame.maxY - wallPadding - radius
        }
        
        return boundedPosition
    }
}

