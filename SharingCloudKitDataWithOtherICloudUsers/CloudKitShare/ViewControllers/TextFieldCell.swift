/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The table view cell class for text input.
*/

import UIKit

// The custom table view cell type for a cell with a text field.
//
class TextFieldCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }

    // MARK: - UITextFieldDelegate
    //
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
