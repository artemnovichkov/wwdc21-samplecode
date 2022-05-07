/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main application view controller.
*/

import UIKit
import PassKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var applePayView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    let paymentHandler = PaymentHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        let result = PaymentHandler.applePayStatus()
        var button: UIButton?

        if result.canMakePayments {
            button = PKPaymentButton(paymentButtonType: .book, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(ViewController.payPressed), for: .touchUpInside)
        } else if result.canSetupCards {
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(ViewController.setupPressed), for: .touchUpInside)
        }

        if let applePayButton = button {
            let constraints = [
                applePayButton.centerXAnchor.constraint(equalTo: applePayView.centerXAnchor),
                applePayButton.centerYAnchor.constraint(equalTo: applePayView.centerYAnchor)
            ]
            applePayButton.translatesAutoresizingMaskIntoConstraints = false
            applePayView.addSubview(applePayButton)
            NSLayoutConstraint.activate(constraints)
        }

        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(37.7839, -122.4012), latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: true)
    }

    @objc func payPressed(sender: AnyObject) {
        paymentHandler.startPayment() { (success) in
            if success {
                self.performSegue(withIdentifier: "Confirmation", sender: self)
            }
        }
    }

    @objc func setupPressed(sender: AnyObject) {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }
}
