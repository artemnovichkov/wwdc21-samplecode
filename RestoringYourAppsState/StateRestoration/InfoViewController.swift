/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller tab for displaying the product's data.
*/

import UIKit

class InfoViewController: UIViewController {
    
    // MARK: - Properties

    var product: Product? {
        didSet {
            if isViewLoaded {
                updateUIElements()
            }
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var yearLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    
    var priceFormatter: NumberFormatter!
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Detail",
                                      image: UIImage(systemName: "info.circle"),
                                      selectedImage: UIImage(systemName: "info.circle.fill"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        priceFormatter = NumberFormatter()
        priceFormatter.locale = Locale.current
        priceFormatter.numberStyle = .currency
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIElements()
    }
    
    func updateUIElements() {
        titleLabel.text = product?.name
        
        if let yearValue = product?.year {
            yearLabel.text = "\(yearValue)"
        }
    
        let formattedPrice = priceFormatter.string(from: NSNumber(value: product!.price))
        priceLabel.text = formattedPrice
        
        imageView.image = UIImage(named: product!.imageName)
    }

}

// MARK: - UIStateRestoring (iOS 12.x)

// The system calls these overrides for nonscene-based versions of this app in iOS 12.x.

extension InfoViewController {

    // Keys for restoring this view controller.
    private static let restoreProductKey = "restoreProduct"

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)

        coder.encode(product?.identifier.uuidString, forKey: InfoViewController.restoreProductKey)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        guard let decodedProductIdentifier =
            coder.decodeObject(forKey: InfoViewController.restoreProductKey) as? String else {
            fatalError("A product did not exist in the restore. In your app, handle this gracefully.")
        }
        product = DataModelManager.sharedInstance.product(fromIdentifier: decodedProductIdentifier)
    }
}
