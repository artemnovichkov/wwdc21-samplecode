/*
See LICENSE folder for this sample’s licensing information.

Abstract:
MainTableViewController SuggestedSearch protocol.
*/

import UIKit

extension MainTableViewController: SuggestedSearch {
    
    // ResultsTableController selected a suggested search, so we need to apply the search token.
    func didSelectSuggestedSearch(token: UISearchToken) {
        if let searchField = navigationItem.searchController?.searchBar.searchTextField {
            searchField.insertToken(token, at: 0)
            
            // Hide the suggested searches now that we have a token.
            resultsTableController.showSuggestedSearches = false
            
            // Update the search query with the newly inserted token.
            updateSearchResults(for: searchController)
        }
    }
    
    // ResultsTableController selected a product, so navigate to that product.
    func didSelectProduct(product: Product) {
        // Set up the detail view controller to show.
        let detailViewController = DetailViewController.detailViewControllerForProduct(product)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    
}
