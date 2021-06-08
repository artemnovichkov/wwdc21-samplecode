/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller class for showing a full image.
*/

import UIKit

class FullImageViewController: UIViewController {
    @IBOutlet weak var fullImageView: UIImageView!
    
    var fullImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fullImageView.translatesAutoresizingMaskIntoConstraints = false
        fullImageView.image = fullImage
    }
}

// MARK: - Action handlers

extension FullImageViewController {
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
