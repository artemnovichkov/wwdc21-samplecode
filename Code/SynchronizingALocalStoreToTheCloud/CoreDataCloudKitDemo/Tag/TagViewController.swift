/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller class to show and edit tags.
*/

import UIKit
import CoreData

class TagViewController: UITableViewController {
    // The alert action for input validation.
    private var alertActionToEnable: UIAlertAction!
    
    private lazy var dataProvider: TagProvider = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let provider = TagProvider(with: appDelegate.coreDataStack.persistentContainer,
                                   fetchedResultsControllerDelegate: self)
        return provider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension TagViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as? TagCell else {
            fatalError("###\(#function): Failed to dequeue TagCell. Check the cell reusable identifier in Main.storyboard.")
        }
        let tag = dataProvider.fetchedResultsController.object(at: indexPath)
        cell.nameLabel.text = "\(tag.name!) (\(tag.postCount))"
        cell.nameLabel.textColor = tag.color
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        dataProvider.deleteTag(at: indexPath)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TagViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

// MARK: - Action handlers

extension TagViewController {
    @IBAction func add(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Tag.", message: "Create a new tag.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter a unique name."
            textField.addTarget(self, action: #selector(type(of: self).textChanged(_:)), for: .editingChanged)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        
        alertActionToEnable = UIAlertAction(title: "New Tag", style: .default) {_ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            self.dataProvider.addTag(name: name, context: self.dataProvider.persistentContainer.viewContext)
        }
        alertActionToEnable.isEnabled = false
        alert.addAction(alertActionToEnable!)
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    /**
     Validate the input and enable or disable the “New Tag” button accordingly.
     
     Tags should have a unique name to avoid triggering deduplication unnecessarily.
     */
    @objc
    func textChanged(_ sender: UITextField) {
        // Check that tagName.count > 1 to make sure the tag displays well (text width > height) with TagLabel.
        guard let tagName = sender.text, tagName.count > 1 else {
            alertActionToEnable.isEnabled = false
            return
        }
        let numberOfTags = dataProvider.numberOfTags(with: tagName)
        alertActionToEnable.isEnabled = (numberOfTags == 0)
    }
}
