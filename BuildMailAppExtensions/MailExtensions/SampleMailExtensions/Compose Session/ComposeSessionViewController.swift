/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The compose session view controller.
*/

import MailKit

class ComposeSessionViewController: MEExtensionViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    var datasource: NSTableViewDiffableDataSource<String, SpecialProjectHandler.SpecialProject>?
    
    let header = "Project Name"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = NSTableViewDiffableDataSource<String, SpecialProjectHandler.SpecialProject>(tableView: tableView, cellProvider: {
            table, column, row, project in
            if let cell = self.tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView {
                cell.textField?.stringValue = project.rawValue
                return cell
            }
            return NSView()
        })
        var snap = NSDiffableDataSourceSnapshot<String, SpecialProjectHandler.SpecialProject>()
        snap.appendSections([header])
        snap.appendItems(SpecialProjectHandler.SpecialProject.allCases, toSection: header)
        datasource?.apply(snap, animatingDifferences: true, completion: nil)
    }

}

extension ComposeSessionViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let selectedTableView = notification.object as? NSTableView {
            let row = selectedTableView.selectedRow
            if let project = datasource?.itemIdentifier(forRow: row) {
                SpecialProjectHandler.sharedHandler.selectedSpecialProject = project
            }
        }
    }
}
