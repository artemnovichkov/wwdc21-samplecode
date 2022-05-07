/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing a 2x2 grid of focusable items.
*/

import UIKit

struct GroupsSample: MenuDescribable {

    static var title = "Groups"
    static var iconName = "rectangle.grid.1x2"

    static var description = """
    Shows a 2x2 grid of focusable items where the top row and the bottom row items \
    are assigned to different focus groups. This allows tabbing between the two \
    rows while using the arrow keys to navigate between the two items in each group. \
    Or in other words: tab navigates vertically in this sample while arrow keys \
    navigate horizontally.
    """
    
    static func create() -> UIViewController { GroupsSampleViewController() }
}

class GroupsSampleViewController: GridViewController<FocusableView> {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.gridView.showsHorizontalDivider = true

        self.gridView.topLeading.focusGroupIdentifier = FocusGroups.topRow
        self.gridView.topTrailing.focusGroupIdentifier = FocusGroups.topRow
        self.gridView.bottomLeading.focusGroupIdentifier = FocusGroups.bottomRow
        self.gridView.bottomTrailing.focusGroupIdentifier = FocusGroups.bottomRow
    }
}
