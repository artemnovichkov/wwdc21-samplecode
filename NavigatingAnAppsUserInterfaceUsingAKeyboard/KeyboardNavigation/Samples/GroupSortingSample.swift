/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Example showing a column of two items, each with their own focus group.
*/

import UIKit

struct GroupSortingSample: MenuDescribable {

    static var title = "Group Sorting"
    static var iconName = "rectangle.3.offgrid"

    static var description = """
    Shows a column of two items on the left and a single item on the right. \
    Each of these items provide their own focus group so that they can each be \
    reached by pressing tab. Focus groups are then used to group them together so \
    that the left, vertically stacked items are enumerated before focus jumps to \
    the item on the right.
    """

    static func create() -> UIViewController { GroupSortingSampleViewController() }
}

class GroupSortingSampleViewController: UIViewController {

    let topLeading = FocusableView()
    let bottomLeading = FocusableView()
    let trailing = FocusableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let leadingContainer = UIView()
        leadingContainer.translatesAutoresizingMaskIntoConstraints = false

        self.topLeading.translatesAutoresizingMaskIntoConstraints = false
        self.bottomLeading.translatesAutoresizingMaskIntoConstraints = false
        self.trailing.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(containerView)
        containerView.addSubview(leadingContainer)
        leadingContainer.addSubview(self.topLeading)
        leadingContainer.addSubview(self.bottomLeading)
        containerView.addSubview(self.trailing)

        Layout.activate(
            // Container
            Layout.center(containerView, in: self.view),

            // Horizontal
            Layout.embed(leadingContainer, self.trailing, horizontallyIn: containerView),
            Layout.embed(self.topLeading, horizontallyIn: leadingContainer),
            Layout.embed(self.bottomLeading, horizontallyIn: leadingContainer),

            // Vertical
            Layout.embed(self.trailing, verticallyIn: containerView),
            Layout.embed(leadingContainer, verticallyIn: containerView),
            Layout.embed(self.topLeading, self.bottomLeading, verticallyIn: leadingContainer),

            // Aspect
            Layout.square(self.topLeading),
            Layout.square(self.bottomLeading),
            Layout.square(self.trailing, size: nil) // Trailing will size itself based on the above aspec and edge constraints.
        )

        // Set the focus groups of the focusable items.
        self.topLeading.focusGroupIdentifier = FocusGroups.topLeading
        self.bottomLeading.focusGroupIdentifier = FocusGroups.bottomLeading
        self.trailing.focusGroupIdentifier = FocusGroups.trailingColumn

        // To ensure that topLeading and bottomLeading come before trailing, group them together.
        leadingContainer.focusGroupIdentifier = FocusGroups.leadingColumn
    }
}
