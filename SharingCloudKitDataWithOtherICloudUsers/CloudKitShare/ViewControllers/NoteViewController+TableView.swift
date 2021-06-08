/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of NoteViewController that manages the tableView data source and delegate.
*/

import UIKit

// MARK: - UITableViewDataSource and UITableViewDelegate
//
extension NoteViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard topicCacheOrNil != nil else {
            fatalError("Topic cache should not be nil now!")
        }
        
        let identifiers = [TableCellReusableID.rightDetail, TableCellReusableID.textField]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.row], for: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Topic"
            cell.detailTextLabel?.text = topicName
            
        } else if indexPath.row == 1, let textFieldCell = cell as? TextFieldCell {
            textFieldCell.titleLabel.text = "Title"
            textFieldCell.textField.placeholder = "Required"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
