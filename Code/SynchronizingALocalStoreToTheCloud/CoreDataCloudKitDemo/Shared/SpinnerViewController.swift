/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Base class for the view controllers that need a spinner.
*/

import UIKit

class SpinnerViewController: UITableViewController {
    
    lazy var spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard spinner.superview == nil, let superView = tableView.superview else { return }
        
        superView.addSubview(spinner)
        superView.bringSubviewToFront(spinner)
        spinner.center = CGPoint(x: superView.frame.size.width / 2, y: superView.frame.size.height / 2)
    }
}
