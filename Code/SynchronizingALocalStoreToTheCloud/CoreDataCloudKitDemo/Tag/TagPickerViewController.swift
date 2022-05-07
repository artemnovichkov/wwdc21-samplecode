/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller class for picking tags for a post.
*/

import UIKit
import CoreData

class TagPickerViewController: UITableViewController {
    var post: Post!
    private lazy var dataProvider: TagProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = TagProvider(with: appDelegate!.coreDataStack.persistentContainer,
                                   fetchedResultsControllerDelegate: self)
        return provider
    }()
}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension TagPickerViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as? TagCell else {
            fatalError("###\(#function): Failed to dequeue TagCell. Check the cell reusable identifier in Main.storyboard.")
        }
        
        let tag = dataProvider.fetchedResultsController.object(at: indexPath)
        if let tags = post.tags, tags.contains(tag) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.nameLabel.text = tag.name
        cell.nameLabel.textColor = tag.color
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        cell.accessoryType = cell.accessoryType == .none ? .checkmark : .none
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TagPickerViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

// MARK: - Action handlers

extension TagPickerViewController {
    @IBAction func done(_ sender: UIBarButtonItem) {
        // Clear post.tags before updating it.
        if let tags = post.tags {
            post.removeFromTags(tags)
        }
        
        // Add the checked tags. The number is expected to be small.
        let totalRows = tableView.numberOfRows(inSection: 0)
        for row in 0..<totalRows {
            let indexPath = IndexPath(row: row, section: 0)
            if let cell = tableView.cellForRow(at: indexPath), cell.accessoryType == .checkmark {
                let object = dataProvider.fetchedResultsController.object(at: indexPath)
                post.addToTags(object)
            }
        }
        dismiss(animated: true)
        // Perform the unwind segue so that the DetailViewController can update its view.
        performSegue(withIdentifier: "updateDetail", sender: self)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
