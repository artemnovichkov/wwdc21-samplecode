/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class represents the player.
*/

import GameplayKit

class PlayerComponent: BaseComponent {
    public var character: Character!

    // Update the position.
    override func update(deltaTime seconds: TimeInterval) {
        positionAgentFromNode()
        super.update(deltaTime: seconds)
    }
}
