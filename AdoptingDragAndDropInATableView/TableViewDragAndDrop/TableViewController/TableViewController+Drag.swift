/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements the delegate methods for providing data for a drag interaction.
*/

import UIKit

extension TableViewController: UITableViewDragDelegate {
    // MARK: - UITableViewDragDelegate
    
    /**
         The `tableView(_:itemsForBeginning:at:)` method is the essential method
         to implement for allowing dragging from a table.
    */
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return model.dragItems(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
