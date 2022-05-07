/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The motion portion of the HapticRicochet app.
*/

import UIKit
import CoreMotion

extension ViewController {
    
    private var kMaxVelocity: Float { return 500 }
    
    var normalizedSphereVelocity: Float {
        let velocity = bounce.linearVelocity(for: bounce.items[0])
        let xVelocity = Float(velocity.x)
        let yVelocity = Float(velocity.y)
        let magnitude = sqrtf(xVelocity * xVelocity + yVelocity * yVelocity)
        return min(max(Float(magnitude) / kMaxVelocity, 0.0), 1.0)
    }
    
    func activateAccelerometer() {
        // Manage the motion events in a separate queue off of the main thread.
        motionQueue = OperationQueue()
        motionData = CMAccelerometerData()
        motionManager = CMMotionManager()
        
        guard let manager = motionManager else { return }
        
        manager.startDeviceMotionUpdates(to: motionQueue) { deviceMotion, error in
            guard let motion = deviceMotion else { return }
            
            let gravity = motion.gravity
            
            // Dispatch gravity updates back to the main queue because they affect the user interface.
            DispatchQueue.main.async {
                self.gravity.gravityDirection = CGVector(dx: gravity.x * 3.5,
                                                         dy: -gravity.y * 3.5)
            }
        }
    }
}
