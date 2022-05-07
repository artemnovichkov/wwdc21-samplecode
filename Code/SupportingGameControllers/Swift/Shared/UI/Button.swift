/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A basic node-based button.
*/

import SpriteKit

class Button: SKNode {
    var width: CGFloat {
        return size.width
    }

    var label: SKLabelNode?
    var background: SKSpriteNode?
    private(set) var actionClicked: Selector?
    private(set) var targetClicked: Any?
    var size = CGSize.zero

    func setText(_ txt: String) {
        label!.text = txt
    }

    func setBackgroundColor(_ col: SKColor) {
        guard let background = background else { return }
        background.color = col
    }

    func setClickedTarget(_ target: Any, action: Selector) {
        targetClicked = target
        actionClicked = action
    }

    // Initialize a new button.
    init(text txt: String) {
        super.init()

        // Create a label.
        let fontName: String = "Optima-ExtraBlack"
        label = SKLabelNode(fontNamed: fontName)
        label!.text = txt
        label!.fontSize = 18
        label!.fontColor = SKColor.white
        label!.position = CGPoint(x: CGFloat(0.0), y: CGFloat(-8.0))

        // Create the background.
        size = CGSize(width: CGFloat(label!.frame.size.width + 10.0), height: CGFloat(30.0))
        background = SKSpriteNode(color: SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.75)), size: size)

        // Add to the root node.
        addChild(background!)
        addChild(label!)

        // Track the mouse event.
        isUserInteractionEnabled = true
    }

    init(skNode node: SKNode) {
        super.init()

        // Track the mouse event.
        isUserInteractionEnabled = true
        size = node.frame.size
        addChild(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func height() -> CGFloat {
        return size.height
    }

#if os( OSX )
    override func mouseDown(with event: NSEvent) {
        setBackgroundColor(SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(1.0)))
    }

    override func mouseUp(with event: NSEvent) {
        setBackgroundColor(SKColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.75)))
        
        let posX = position.x + ((parent?.position.x) ?? CGFloat(0))
        let posY = position.y + ((parent?.position.y) ?? CGFloat(0))
        let windowPos = event.locationInWindow

        if abs(windowPos.x - posX) < width / 2 * xScale && abs(windowPos.y - posY) < height() / 2 * yScale {
            _ = (targetClicked! as AnyObject).perform(actionClicked, with: self)
        }
    }

#endif
#if os( iOS )
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        _ = (targetClicked! as AnyObject).perform(actionClicked, with: self)
    }
#endif
}
