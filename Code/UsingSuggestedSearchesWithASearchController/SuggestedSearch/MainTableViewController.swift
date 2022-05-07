/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The application's primary table view controller showing a list of products.
*/

import UIKit

class MainTableViewController: UITableViewController {
    
    // MARK: - Constants

    // The suffix portion of the user activity type for this view controller.
    static let activitySuffix = "mainRestored"
    
    /// State restoration values.
    private enum RestorationKeys: String {
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
        case searchBarToken
    }
    
    // MARK: - Properties
    
    /// Search controller to help us with filtering.
    var searchController: UISearchController!
    
    /// The search results table view.
    var resultsTableController: ResultsTableController!
    
    /// Data model for the table view.
    var products = [Product]()
    
    /** Returns the NSUserActivity string for this view controller.
        The activity string comes from the Info.plist that ends with the "activitySuffix" string for this view controller.
    */
    class func viewControllerActivityType() -> String {
        var returnActivityType = ""
        if let definedAppUserActivities = UIApplication.userActivitiyTypes {
            for activityType in definedAppUserActivities {
                if activityType.hasSuffix(activitySuffix) {
                    returnActivityType = activityType
                    break
                }
            }
        }
        return returnActivityType
    }
    
    // MARK: - Data Model
    
    struct ProductKind {
        static let Ginger = "Ginger"
        static let Gladiolus = "Gladiolus"
        static let Orchid = "Orchid"
        static let Poinsettia = "Poinsettia"
        static let RedRose = "Rose"
        static let GreenRose = "Rose"
        static let Tulip = "Tulip"
        static let RedCarnation = "Carnation"
        static let GreenCarnation = "Carnation"
        static let BlueCarnation = "Carnation"
        static let Sunflower = "Sunflower"
        static let Gardenia = "Gardenia"
        static let RedGardenia = "Gardenia"
        static let BlueGardenia = "Gardenia"
    }
    
    private func setupDataModel() {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        
        products = [
            Product(title: ProductKind.Ginger, yearIntroduced: dateFormatter.date(from: "2007")!, introPrice: 49.98, color: .undedefined),
            Product(title: ProductKind.Gladiolus, yearIntroduced: dateFormatter.date(from: "2001")!, introPrice: 51.99, color: .undedefined),
            Product(title: ProductKind.Orchid, yearIntroduced: dateFormatter.date(from: "2007")!, introPrice: 16.99, color: .undedefined),
            Product(title: ProductKind.Poinsettia, yearIntroduced: dateFormatter.date(from: "2010")!, introPrice: 31.99, color: .undedefined),
            Product(title: ProductKind.RedRose, yearIntroduced: dateFormatter.date(from: "2010")!, introPrice: 24.99, color: .red),
            Product(title: ProductKind.GreenRose, yearIntroduced: dateFormatter.date(from: "2013")!, introPrice: 24.99, color: .green),
            Product(title: ProductKind.Tulip, yearIntroduced: dateFormatter.date(from: "1997")!, introPrice: 39.99, color: .undedefined),
            Product(title: ProductKind.RedCarnation, yearIntroduced: dateFormatter.date(from: "2006")!, introPrice: 23.99, color: .red),
            Product(title: ProductKind.GreenCarnation, yearIntroduced: dateFormatter.date(from: "2009")!, introPrice: 23.99, color: .green),
            Product(title: ProductKind.BlueCarnation, yearIntroduced: dateFormatter.date(from: "2009")!, introPrice: 24.99, color: .blue),
            Product(title: ProductKind.Sunflower, yearIntroduced: dateFormatter.date(from: "2008")!, introPrice: 25.00, color: .undedefined),
            Product(title: ProductKind.Gardenia, yearIntroduced: dateFormatter.date(from: "2006")!, introPrice: 25.00, color: .undedefined),
            Product(title: ProductKind.RedGardenia, yearIntroduced: dateFormatter.date(from: "2008")!, introPrice: 25.00, color: .red),
            Product(title: ProductKind.BlueGardenia, yearIntroduced: dateFormatter.date(from: "2006")!, introPrice: 25.00, color: .blue)
        ]
    }
    
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupDataModel()
        
        resultsTableController = ResultsTableController()
        resultsTableController.suggestedSearchDelegate = self // So we can be notified when a suggested search token is selected.
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = NSLocalizedString("Enter a search term", comment: "")
        searchController.searchBar.returnKeyType = .done

        // Place the search bar in the navigation bar.
        navigationItem.searchController = searchController
            
        // Make the search bar always visible.
        navigationItem.hidesSearchBarWhenScrolling = false
     
        // Monitor when the search controller is presented and dismissed.
        searchController.delegate = self

        // Monitor when the search button is tapped, and start/end editing.
        searchController.searchBar.delegate = self
        
        /** Specify that this view controller determines how the search controller is presented.
            The search controller should be presented modally and match the physical size of this view controller.
        */
        definesPresentationContext = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      
        userActivity = self.view.window?.windowScene?.userActivity
        if userActivity != nil {
            // Restore the active state.
            searchController.isActive = userActivity!.userInfo?[RestorationKeys.searchControllerIsActive.rawValue] as? Bool ?? false
         
            // Restore the first responder status.
            if let wasFirstResponder = userActivity!.userInfo?[RestorationKeys.searchBarIsFirstResponder.rawValue] as? Bool {
                if wasFirstResponder {
                    searchController.searchBar.becomeFirstResponder()
                }
            }

            // Restore the text in the search field.
            if let searchBarText = userActivity!.userInfo?[RestorationKeys.searchBarText.rawValue] as? String {
                searchController.searchBar.text = searchBarText
            }
        
            if let token = userActivity!.userInfo?[RestorationKeys.searchBarToken.rawValue] as? NSNumber {
                searchController.searchBar.searchTextField.tokens = [ResultsTableController.searchToken(tokenValue: token.intValue)]
            }
            
            resultsTableController.showSuggestedSearches = false
        } else {
            // No current acivity, so create one.
            userActivity = NSUserActivity(activityType: MainTableViewController.viewControllerActivityType())
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // No longer interested in the current activity.
        view.window?.windowScene?.userActivity = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? DetailViewController {
            if tableView.indexPathForSelectedRow != nil {
                destinationViewController.product = products[tableView.indexPathForSelectedRow!.row]
            }
        }
    }

}

// MARK: - UITableViewDataSource

extension MainTableViewController {
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return products.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewController.productCellIdentifier, for: indexPath)
		let product = products[indexPath.row]
		configureCell(cell, forProduct: product)
		return cell
	}
	
    func setToSuggestedSearches() {
        // Show suggested searches only if we don't have a search token in the search field.
        if searchController.searchBar.searchTextField.tokens.isEmpty {
            resultsTableController.showSuggestedSearches = true
            
            // We are no longer interested in cell navigating, since we are now showing the suggested searches.
            resultsTableController.tableView.delegate = resultsTableController
        }
    }
    
}

// MARK: - UISearchBarDelegate

extension MainTableViewController: UISearchBarDelegate {
	
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
            // Text is empty, show suggested searches again.
            setToSuggestedSearches()
        } else {
            resultsTableController.showSuggestedSearches = false
        }
    }
    
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // User tapped the Done button in the keyboard.
        searchController.dismiss(animated: true, completion: nil)
        searchBar.text = ""
	}

}

// MARK: - UISearchControllerDelegate

// Use these delegate functions for additional control over the search controller.

extension MainTableViewController: UISearchControllerDelegate {
	
	// We are being asked to present the search controller, so from the start - show suggested searches.
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
        setToSuggestedSearches()
	}
}

// MARK: - State Restoration

extension MainTableViewController {
    
    /** Returns the activity object you can use to restore the previous contents of your scene's interface.
        Before disconnecting a scene, the system asks your delegate for an NSUserActivity object containing state information for that scene.
        If you provide that object, the system puts a copy of it in this property.
        Use the information in the user activity object to restore the scene to its previous state.
    */
    override func updateUserActivityState(_ activity: NSUserActivity) {

        super.updateUserActivityState(activity)

        // Update the user activity with the state of the search controller.
        activity.userInfo = [RestorationKeys.searchControllerIsActive.rawValue: searchController.isActive,
                             RestorationKeys.searchBarIsFirstResponder.rawValue: searchController.searchBar.isFirstResponder,
                             RestorationKeys.searchBarText.rawValue: searchController.searchBar.text!]
        
        // Add the search token if it exists in the search field.
        if !searchController.searchBar.searchTextField.tokens.isEmpty {
            let searchToken = searchController.searchBar.searchTextField.tokens[0]
            if let searchTokenRep = searchToken.representedObject as? NSNumber {
                activity.addUserInfoEntries(from: [RestorationKeys.searchBarToken.rawValue: searchTokenRep])
            }
        }
    }

    /** Restores the state needed to continue the given user activity.
        Subclasses override this method to restore the responder’s state with the given user activity.
        The override should use the state data contained in the userInfo dictionary of the given user activity to restore the object.
     */
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        super.restoreUserActivityState(activity)
    }

}

// MARK: - Table View

extension UITableViewController {
    
    static let productCellIdentifier = "cellID"
    
    // Used by both MainTableViewController and ResultsTableController to define its table cells.
    func configureCell(_ cell: UITableViewCell, forProduct product: Product) {
        let textTitle = NSMutableAttributedString(string: product.title)
        let textColor = ResultsTableController.suggestedColor(fromIndex: product.color)
        
        textTitle.addAttribute(NSAttributedString.Key.foregroundColor,
                               value: textColor,
                               range: NSRange(location: 0, length: textTitle.length))
        cell.textLabel?.attributedText = textTitle
        
        // Build the price and year as the detail right string.
        let priceString = product.formattedPrice()
        let yearString = product.formattedDate()
        cell.detailTextLabel?.text = "\(priceString!) | \(yearString!)"
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.image = nil
    }
    
}
