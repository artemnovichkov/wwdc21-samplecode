/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller class that manages tags.
*/

import UIKit
import CoreData

class TagViewController: UITableViewController {
    @IBOutlet weak var tagNameTextField: UITextField!
    @IBOutlet weak var addTagButton: UIButton!
    @IBOutlet var titleTextField: UITextField!
    
    var selectedPhoto: Photo!

    private lazy var dataProvider: TagProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let provider = TagProvider(with: appDelegate!.coreDataStack.persistentContainer,
                                   fetchedResultsControllerDelegate: self)
        return provider
    }()
    
    // The diffable tag data source for the table view.
    private lazy var diffableTagSource: DiffableTagSource! = {
        return DiffableTagSource(tableView: tableView) { (tableView, indexPath, tag) -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath) as? TagCell else {
                fatalError("\(#function): Failed to dequeue TagCell. Check the cell reusable identifier in Main.storyboard.")
            }
            let tag = self.dataProvider.fetchedResultsController.object(at: indexPath)
            if let tags = self.selectedPhoto.tags, tags.contains(tag) {
                cell.nameLabel.textColor = .systemOrange
                cell.accessoryType = .checkmark
            } else {
                cell.nameLabel.textColor = .darkText
                cell.accessoryType = .none
            }
            cell.nameLabel.text = tag.name
            return cell
        }
    }()
    
    // Reload the table view by applying a new snapshot. The table view has only one section in this sample.
    private func reloadTableView() {
        let tags: [Tag] = dataProvider.fetchedResultsController.fetchedObjects ?? []
        
        var snapshot = DiffableTagSourceSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(tags)
        diffableTagSource.apply(snapshot)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
        
        navigationItem.prompt = "Tap the title to edit the photo name."
        titleTextField.text = selectedPhoto.userSpecifiedName
        navigationItem.titleView = titleTextField

        diffableTagSource.defaultRowAnimation = .fade
        reloadTableView()
    }
}

// MARK: - UITableViewDelegate
//
extension TagViewController {
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { (_, _, completionHandler) in
            self.dataProvider.deleteTag(at: indexPath)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let views = Bundle.main.loadNibNamed("TagSectionTitleView", owner: self, options: nil)
        guard let sectionTitleView = views?.first as? UIView else {
            return nil
        }
        return sectionTitleView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TagCell else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tag = dataProvider.fetchedResultsController.object(at: indexPath)
        if cell.accessoryType == .none {
            cell.accessoryType = .checkmark
            cell.nameLabel.textColor = .systemOrange
            tag.addToPhotos(selectedPhoto)
        } else {
            cell.accessoryType = .none
            cell.nameLabel.textColor = .darkText
            selectedPhoto.removeFromTags(tag)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
//
extension TagViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        reloadTableView()
    }
}

// MARK: - Action handlers
//
extension TagViewController {
    
    @IBAction func addTag(_ sender: Any) {
        dataProvider.addTag(name: tagNameTextField.text!, context: self.dataProvider.persistentContainer.viewContext)
    }

    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true) {
            do {
                try self.dataProvider.persistentContainer.viewContext.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    /**
      Validate the input and enable or disable the Add button (+) accordingly.
      Tags must have a unique name.
     */
    @IBAction func tagNameChanged(_ sender: UITextField) {
        let predicate: NSPredicate
        if let userInput = sender.text, !userInput.isEmpty {
            let numberOfTags = dataProvider.numberOfTags(with: userInput)
            addTagButton.isEnabled = (numberOfTags == 0)
            predicate = NSPredicate(format: "name CONTAINS[cd] %@", userInput)

        } else {
            addTagButton.isEnabled = false
            predicate = NSPredicate(value: true)
        }
        
        dataProvider.fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try dataProvider.fetchedResultsController.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        
        reloadTableView()
    }
    
    @IBAction func photoUserSpecifiedNameChanged(_ sender: UITextField) {
        selectedPhoto.userSpecifiedName = sender.text
    }
}

// MARK: - UITextFieldDelegate
//
extension TagViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
//
extension TagViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        do {
            try dataProvider.persistentContainer.viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
}
