/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button that VoiceOver activates.
*/

import UIKit

class VoiceOverActivatableButton: UIButton {
 
    var activatedHandler: (() -> Void)?
    
    override func accessibilityActivate() -> Bool {
        guard let activatedHandler = activatedHandler else {
            return false
        }
        activatedHandler()
        return true
    }
}
