/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The user's home view.
*/

import UIKit

class UserHomeViewController: UIViewController {
    @IBAction func signOut(_ sender: Any) {
        self.view.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "SignInViewController")
    }
}
