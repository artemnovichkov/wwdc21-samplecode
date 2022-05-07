/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Manages a collection of selected model items and posts notifications when it changes.
*/

import Foundation

/// A collection of model items selected by the user
class ModelItemsCollection {

    // We use an Array to preserve ordering
    var modelItems: [AnyModelItem] = [] {
        didSet {
            NotificationCenter.default.post(name: .modelItemsCollectionDidChange, object: self)
        }
    }

    func add(modelItems: [AnyModelItem]) {
        self.modelItems += modelItems.filter { !self.modelItems.contains($0) }
    }

    func remove(modelItems: [AnyModelItem]) {
        self.modelItems.removeAll { item in
            modelItems.contains { $0.itemID == item.itemID }
        }
    }

    /// Provides a human readable subtitle describing the collection of selected items
    /// - Parameter itemIdentifier The most recently selected item
    /// - Returns: A name describing the selected items
    func subtitle(forMostRecentlySelected itemIdentifier: SidebarItemIdentifier?) -> String {
        let newSelection: Set<AnyModelItem>
        let alreadySelected = Set(modelItems)
        switch itemIdentifier?.kind {
        case .leafModelItem(let modelItem)?:
            return modelItem.name
        case .expandableModelSection?, .expandableSection?, .expandableModelItem?:
            newSelection = Set(itemIdentifier!.kind.children)
        case nil:
            newSelection = []
        }
        // If we're heterogeneous, exit with the most general title:
        let union = alreadySelected.union(newSelection)
        if union.contains(where: { $0.rewardsProgram == nil }) && union.contains(where: { $0.rewardsProgram != nil }) {
            return "Countries & Rewards Programs"
        }
        if union.isEmpty {
            return ""
        }

        if let itemIdentifier = itemIdentifier, alreadySelected.allSatisfy(newSelection.contains(_:)) {
            // All selected items are members of the new selection -> use the title of the new selection
            return itemIdentifier.name
        } else if newSelection.first?.rewardsProgram != nil || alreadySelected.first?.rewardsProgram != nil {
            return "Rewards Programs"
        } else {
            return "Countries"
        }
    }
}

extension NSNotification.Name {
    static let modelItemsCollectionDidChange = Notification.Name("ModelItemsCollectionDidChange")
}
