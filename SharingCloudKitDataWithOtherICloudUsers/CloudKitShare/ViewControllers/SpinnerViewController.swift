/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The base class of the zone and main view controllers.
CloudKit operations need to reach out to the servers, so the view controllers need a spinner.
*/

import UIKit

// The string constants for the view controllers of this sample.
//
struct TableCellReusableID {
    static let basic = "Basic"
    static let subTitle = "Subtitle"
    static let rightDetail = "Right Detail"
    static let textField = "TextFieldCell"
}

struct SegueID {
    static let zoneShowDetail = "showDetail"
    static let mainAddNew = "addNew"
}

// The base class of the zone and main view controllers.
// Provide a spinner for subclasses.
//
class SpinnerViewController: UITableViewController {
    lazy var spinner: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .medium)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addSubview(spinner)
        tableView.bringSubviewToFront(spinner)
        spinner.hidesWhenStopped = true
        spinner.color = .systemBlue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let size = tableView.frame.size
        spinner.center = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    // Remove self from the notification center so subclasses don't need to do it.
    //
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
