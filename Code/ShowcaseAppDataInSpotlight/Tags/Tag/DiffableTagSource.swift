/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The diffable data source class that provides tags for a table view.
*/

import UIKit

typealias DiffableTagSourceSnapshot = NSDiffableDataSourceSnapshot<Int, Tag>

class DiffableTagSource: UITableViewDiffableDataSource<Int, Tag> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
