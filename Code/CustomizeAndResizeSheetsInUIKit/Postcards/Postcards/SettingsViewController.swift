/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that displays options for presenting sheets.
*/

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var smallestUndimmedDetentIdentifierControl: UISegmentedControl!
    @IBOutlet weak var prefersScrollingExpandsWhenScrolledToEdgeSwitch: UISwitch!
    @IBOutlet weak var prefersEdgeAttachedInCompactHeightSwitch: UISwitch!
    @IBOutlet weak var widthFollowsPreferredContentSizeWhenEdgeAttachedSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        smallestUndimmedDetentIdentifierControl.selectedSegmentIndex =
        PresentationHelper.sharedInstance.smallestUndimmedDetentIdentifier == .medium ?
        0 : 1
        
        prefersScrollingExpandsWhenScrolledToEdgeSwitch.isOn =
        PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
        
        prefersEdgeAttachedInCompactHeightSwitch.isOn =
        PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
        
        widthFollowsPreferredContentSizeWhenEdgeAttachedSwitch.isOn =
        PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
    }
    
    @IBAction func smallestUndimmedDetentChanged(_ sender: UISegmentedControl) {
        PresentationHelper.sharedInstance.smallestUndimmedDetentIdentifier = sender.selectedSegmentIndex == 0 ?
            .medium : .large
    }
    
    @IBAction func prefersScrollingExpandsWhenScrolledToEdgeSwitchChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge = sender.isOn
    }
    
    @IBAction func prefersEdgeAttachedInCompactHeightSwitchChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight = sender.isOn
    }
    
    @IBAction func widthFollowsPreferredContentSizeWhenEdgeAttachedChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached = sender.isOn
    }
    
}
