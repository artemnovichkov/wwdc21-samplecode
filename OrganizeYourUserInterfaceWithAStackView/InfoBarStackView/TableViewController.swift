/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Stack item view controller for displaying a simple NSTableView.
*/

import Cocoa

class TableViewController: BaseViewController {
    private struct TableItemKeys {
        static let kFirstNameKey = "firstname"
        static let kLastNameKey = "lastname"
        static let kPhoneKey = "phone"
    }
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var myContentArray: NSArrayController!
    
    override func headerTitle() -> String { return NSLocalizedString("Table Header Title", comment: "") }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.enclosingScrollView?.borderType = .noBorder
        
        // Add the people as sample table data to the table view.
        let person1: [String: String] = [
            TableItemKeys.kFirstNameKey: "Joe",
            TableItemKeys.kLastNameKey: "Smith",
            TableItemKeys.kPhoneKey: "(444) 444-4444"
        ]
        myContentArray.addObject(person1)
        
        let person2: [String: String] = [
            TableItemKeys.kFirstNameKey: "Sally",
            TableItemKeys.kLastNameKey: "Allen",
            TableItemKeys.kPhoneKey: "(555) 555-5555"
        ]
        myContentArray.addObject(person2)
        
        let person3: [String: String] = [
            TableItemKeys.kFirstNameKey: "Mary",
            TableItemKeys.kLastNameKey: "Miller",
            TableItemKeys.kPhoneKey: "(777) 777-7777"
        ]
        myContentArray.addObject(person3)
        
        let person4: [String: String] = [
            TableItemKeys.kFirstNameKey: "John",
            TableItemKeys.kLastNameKey: "Zitmayer",
            TableItemKeys.kPhoneKey: "(888) 888-8888"
        ]
        myContentArray.addObject(person4)
        
        // Adjust the tableView's scroll view frame height constraint to match the content in the table.
        let headerView = tableView.headerView
        let headerRect = headerView?.headerRect(ofColumn: 0)
        if let people = myContentArray.arrangedObjects as? [AnyObject] {
            let preferredSize = people.count * (Int(tableView.rowHeight) + 2) + Int((headerRect?.size.height)!)
            
            heightConstraint?.constant = CGFloat(preferredSize)
            savedDefaultHeight = CGFloat(preferredSize)
        }
    }

}

// MARK: - NSTableViewDelegate

extension TableViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow < 0 {
            debugPrint("table: row de-selected")
        } else {
            // Report the selected person in the table.
            if let selectedPerson = myContentArray.selectedObjects.first as? [String: String] {
                let name = selectedPerson[TableItemKeys.kFirstNameKey]! + " " + selectedPerson[TableItemKeys.kLastNameKey]!
                debugPrint("table: row \(tableView.selectedRow) was selected: \(name as String)")
            }
        }
        
        // Invalidate state restoration, which will in turn eventually call "encodeRestorableState".
        invalidateRestorableState()
    }
    
}

// MARK: - State Restoration

extension TableViewController {
    // Restorable key for the table view's selection.
    private static let tableSelectionKey = "tableSelectionKey"
    
    /// Encode state. Helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        
        coder.encode(myContentArray.selectionIndex, forKey: TableViewController.tableSelectionKey)
        super.encodeRestorableState(with: coder)
    }
    
    /// Decode state. Helps restore any previously stored state of the table view view's selection.
    override func restoreState(with coder: NSCoder) {
        
        super.restoreState(with: coder)
        let savedTableSelection = coder.decodeInteger(forKey: TableViewController.tableSelectionKey)
        _ = myContentArray.setSelectionIndex(savedTableSelection)
    }
    
}
