/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SpriteKit node for displaying sorted leaderboard entries consisting of rank,
 display name, and score.
*/

import SpriteKit

struct LeaderboardEntry {
    let displayName: String
    let score: Int
}

// Displays a single entry in a leaderboard, consisting of a background
// rectangle, a label for the rank positioned on the left, a label for the
// display name positioned in the center, and a label for the score positioned on
// the right.
class EntryNode: SKNode {
    private let backgroundNode: SKShapeNode

    private let rankNode: SKLabelNode = {
        let node = SKLabelNode()
        node.fontSize = 17
        node.fontName = "HelveticaNeue-Medium"
        node.fontColor = SKColor.white
        node.verticalAlignmentMode = .center
        node.horizontalAlignmentMode = .center
        node.zPosition = 1
        return node
    }()
    // Declare variables for where to place the rank node on a normalized (1x1 size) background.
    private static let rankPosX = CGFloat(0.07)
    private static let rankPosY = CGFloat(0.5)

    private let displayNameNode: SKLabelNode = {
        let node = SKLabelNode()
        node.fontSize = 17
        node.fontName = "HelveticaNeue"
        node.fontColor = SKColor.white
        node.verticalAlignmentMode = .center
        node.horizontalAlignmentMode = .left
        node.zPosition = 1
        return node
    }()
    // Declare variables for where to place the display node on a normalized background.
    private static let displayNamePosX = CGFloat(0.18)
    private static let displayNamePosY = CGFloat(0.5)

    private let scoreNode: SKLabelNode = {
        let node = SKLabelNode()
        node.fontSize = 17
        node.fontName = "HelveticaNeue-Light"
        node.fontColor = SKColor.white
        node.verticalAlignmentMode = .center
        node.horizontalAlignmentMode = .right
        node.zPosition = 1
        return node
    }()
    // Declare variables for where to place the score node on a normalized background.
    private static let scorePosX = CGFloat(0.92)
    private static let scorePosY = CGFloat(0.5)

    // Create an entry node for the given rank and entry. If the entry is `nil`,
    // empty strings are used for the display name and score text.
    init(size: CGSize, position: CGPoint, rank: Int, entry: LeaderboardEntry?) {
        backgroundNode = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: 0),
                                                  size: size),
                                     cornerRadius: 18)
        backgroundNode.lineWidth = 0
        backgroundNode.zPosition = 0

        rankNode.text = "\(rank)"
        rankNode.position = CGPoint(x: backgroundNode.frame.width * EntryNode.rankPosX,
                                    y: backgroundNode.frame.height * EntryNode.rankPosY)
        backgroundNode.addChild(rankNode)

        super.init()

        setNameAndScore(entry: entry)
        backgroundNode.addChild(displayNameNode)
        backgroundNode.addChild(scoreNode)

        self.position = position
        self.zPosition = 1
        self.addChild(backgroundNode)
    }

    func setNameAndScore(entry: LeaderboardEntry?) {
        let displayName: String
        let scoreText: String
        if let entry = entry {
            // Truncate the display name to make sure it fits into the row.
            if entry.displayName.count > 12 {
                let index = entry.displayName.index(entry.displayName.startIndex, offsetBy: 12)
                displayName = entry.displayName[..<index].appending("...")
            } else {
                displayName = entry.displayName
            }
            scoreText = String(entry.score)
        } else {
            displayName = ""
            scoreText = ""
        }

        displayNameNode.text = "\(displayName)"
        displayNameNode.position = CGPoint(x: backgroundNode.frame.width * EntryNode.displayNamePosX,
                                           y: backgroundNode.frame.height * EntryNode.displayNamePosY)

        scoreNode.text = "\(scoreText)"
        scoreNode.position = CGPoint(x: backgroundNode.frame.width * EntryNode.scorePosX,
                                     y: backgroundNode.frame.height * EntryNode.scorePosY)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// This class displays a list of leaderboard entries ordered by score. The size and
// number of rows in the leaderboard is configurable. Ties are broken randomly.
class LeaderboardNode: SKNode {
    let backgroundNode: SKShapeNode
    var entryNodes: [EntryNode] = []
    
    init(numRows: Int, initialEntries entries: [LeaderboardEntry], position: CGPoint, size: CGSize) {
        backgroundNode = SKShapeNode(rect: CGRect(origin: CGPoint(x: 0, y: 0),
                                                  size: size),
                                     cornerRadius: 15)
        backgroundNode.fillColor = #colorLiteral(red: 0.48, green: 0.49, blue: 0.60, alpha: 0.7)
        backgroundNode.zPosition = 1
        backgroundNode.lineWidth = 0

        let rowSize = backgroundNode.frame.height / CGFloat(numRows)
        let sortedEntries = entries.sorted(by: { entry1, entry2 in return entry1.score > entry2.score })

        // For each row, create a corresponding `EntryNode` object with an appropriate
        // rank. If there aren't enough leaderboard entries to fill the rows,
        // use `nil` (the entry node will display the display name and score as empty strings).
        for row in 0..<numRows {
            let entryNode = EntryNode(size: CGSize(width: backgroundNode.frame.width,
                                                   height: rowSize),
                                      position: CGPoint(x: 0, y: rowSize * CGFloat(numRows - row - 1)),
                                      rank: row + 1,
                                      entry: row < sortedEntries.count ? sortedEntries[row] : nil)
            entryNode.zPosition = 1
            backgroundNode.addChild(entryNode)
            entryNodes.append(entryNode)
        }

        super.init()
        self.addChild(backgroundNode)
        self.position = position
    }
    
    // Update the leaderboard to reflect new entries. Existing entries will be
    // cleared.
    func updateEntries(entries: [LeaderboardEntry]) {
        let sortedEntries = entries.sorted(by: { entry1, entry2 in return entry1.score > entry2.score })
        for row in 0..<entryNodes.count {
            // Because the nodes are already initialized with their appropriate
            // rank, just set the display name and score.
            let entryNode = entryNodes[row]
            if row < sortedEntries.count {
                entryNode.setNameAndScore(entry: sortedEntries[row])
            } else {
                entryNode.setNameAndScore(entry: nil)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
