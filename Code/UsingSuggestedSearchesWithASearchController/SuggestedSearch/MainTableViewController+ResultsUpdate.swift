/*
See LICENSE folder for this sample’s licensing information.

Abstract:
MainTableViewController adoption of UISearchResultsUpdating.
*/

import UIKit

extension MainTableViewController: UISearchResultsUpdating {
    
    // Called when the search bar's text has changed or when the search bar becomes first responder.
    func updateSearchResults(for searchController: UISearchController) {
        // Update the resultsController's filtered items based on the search terms and suggested search token.
        let searchResults = products

        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet).lowercased()
        let searchItems = strippedString.components(separatedBy: " ") as [String]
        
        // Filter results down by title, yearIntroduced and introPrice.
        var filtered = searchResults
        var curTerm = searchItems[0]
        var idx = 0
        while curTerm != "" {
            filtered = filtered.filter {
                $0.title.lowercased().contains(curTerm) ||
                $0.yearIntroduced.description.lowercased().contains(curTerm) ||
                $0.introPrice.description.lowercased().contains(curTerm)
            }
            idx += 1
            curTerm = (idx < searchItems.count) ? searchItems[idx] : ""
        }
        
        // Filter further down for the right colored flowers.
        if !searchController.searchBar.searchTextField.tokens.isEmpty {
            // We only support one search token.
            let searchToken = searchController.searchBar.searchTextField.tokens[0]
            if let searchTokenValue = searchToken.representedObject as? NSNumber {
                filtered = filtered.filter { $0.color == searchTokenValue.intValue }
            }
        }
        
        // Apply the filtered results to the search results table.
        if let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.filteredProducts = filtered
            resultsController.tableView.reloadData()
        }
    }
    
}
