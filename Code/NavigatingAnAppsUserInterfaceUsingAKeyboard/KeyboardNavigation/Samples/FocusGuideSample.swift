/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing focus guides.
*/

import UIKit

struct FocusGuideSample: MenuDescribable {

    static var title = "Focus Guides"
    static var iconName = "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"

    static var description = """
    In this example focus guides are used to remember the last focused item in a row \
    of two.

    When using the arrow keys to move between the top and the bottom row of this 2x2 \
    grid, focus will always jump to the item that was last focused in this row.

    To  achieve this, there are two focus guides, one per row. Focus can still move \
    freely inside of a row because focus guides are ignored when they overlap with the \
    currently focused item.
    """

    static func create() -> UIViewController { FocusGuideViewController() }

}

class FocusGuideViewController: GridViewController<FocusableView> {
    let topFocusGuide = UIFocusGuide()
    let bottomFocusGuide = UIFocusGuide()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the default environments the guides should point to
        // this will make sure that we always start with the leading item.
        self.topFocusGuide.preferredFocusEnvironments = [ self.gridView.topLeading ]
        self.bottomFocusGuide.preferredFocusEnvironments = [ self.gridView.bottomLeading ]

        self.gridView.showsHorizontalDivider = true

        self.gridView.addLayoutGuide(self.topFocusGuide)
        self.gridView.addLayoutGuide(self.bottomFocusGuide)

        // Position guides so that they overlap the top / bottom row of items.
        Layout.activate(
            // Horizontal
            Layout.embed(self.topFocusGuide, horizontallyIn: self.gridView),
            Layout.embed(self.bottomFocusGuide, horizontallyIn: self.gridView),

            // Vertical
            Layout.embed(self.topFocusGuide, self.bottomFocusGuide, verticallyIn: self.gridView, spacing: 0.0),
            [ self.topFocusGuide.heightAnchor.constraint(equalTo: self.bottomFocusGuide.heightAnchor) ]
        )

        self.updateFocusGuideIndicator()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // Another thing we can do with guides is to update them to point to the last focused item from a list of items.
        if let nextItem = context.nextFocusedItem {
            if nextItem === self.gridView.topLeading || nextItem === self.gridView.topTrailing {
                self.topFocusGuide.preferredFocusEnvironments = [ nextItem ]
            } else if nextItem === self.gridView.bottomLeading || nextItem === self.gridView.bottomTrailing {
                self.bottomFocusGuide.preferredFocusEnvironments = [ nextItem ]
            }

            coordinator.addCoordinatedAnimations({
                self.updateFocusGuideIndicator()
            })
        }
    }

    func updateFocusGuideIndicator() {
        // Just for better visibility, highlight the view that is the preferred environment of a focus guide.
        self.gridView.enumerateViews({ view in
            let isChosenOne = view === self.topFocusGuide.preferredFocusEnvironments.first ||
            view === self.bottomFocusGuide.preferredFocusEnvironments.first
            
            view.layer.borderColor = UIColor.tintColor.cgColor
            view.layer.borderWidth = isChosenOne ? 1.0 : 0.0
        })
    }
}
