/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller for displaying the product's full image.
*/

import UIKit

class ImageViewController: UIViewController {

    // The storyboard name that holds this view controller.
    // Other parts of the app use it to load this view controller.
    static let storyboardName = "ImageViewController"

    // MARK: - Properties
    
    @IBOutlet private weak var imageView: UIImageView!
    
    var product: Product? {
        didSet {
            if isViewLoaded {
                updateUIElements()
            }
        }
    }
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Photo",
                                      image: UIImage(systemName: "photo"),
                                      selectedImage: UIImage(systemName: "photo.fill"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            // Add a Close button to remove the scene.
            let closeButton =
                UIBarButtonItem(barButtonSystemItem: .close,
                                target: self,
                                action: #selector(closeAction(sender:)))
            navigationItem.rightBarButtonItem = closeButton
        }
    }
    
    func updateUIElements() {
        imageView.image = UIImage(named: product!.imageName)
        navigationItem.title = product!.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIElements()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // This view controller is going away, no more user activity to track.
        if #available(iOS 13.0, *) {
            view.window?.windowScene?.userActivity = nil
        } else {
            userActivity = nil
        }
    }
    
    @objc
    func closeAction(sender: Any) {
        if #available(iOS 13.0, *) {
            // The Close button removes the scene.
            let options = UIWindowSceneDestructionRequestOptions()
            options.windowDismissalAnimation = .standard
            let session = view.window!.windowScene!.session
            UIApplication.shared.requestSceneSessionDestruction(session,
                                                                options: options,
                                                                errorHandler: nil)
        }
    }

}

// MARK: - UIStateRestoring (iOS 12.x)

// The system calls these overrides for nonscene-based versions of this app in iOS 12.x.

extension ImageViewController {

    // Keys for restoring this view controller.
    private static let restoreProductKey = "restoreProduct"
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        coder.encode(product?.identifier.uuidString, forKey: ImageViewController.restoreProductKey)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)

        guard let decodedProductIdentifier =
            coder.decodeObject(forKey: ImageViewController.restoreProductKey) as? String else {
            fatalError("A product did not exist in the restore. In your app, handle this gracefully.")
        }
        product =
            DataModelManager.sharedInstance.product(fromIdentifier: decodedProductIdentifier)
    }
    
}
