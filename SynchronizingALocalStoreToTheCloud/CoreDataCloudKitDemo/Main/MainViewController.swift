/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller class for the main view, showing a list of posts.
*/

import UIKit
import CoreData

class MainViewController: SpinnerViewController {
    @IBOutlet weak var composeItem: UIBarButtonItem!
    weak var detailViewController: DetailViewController?
    var sharingProvider: SharingProvider = AppDelegate.sharedAppDelegate.coreDataStack
    lazy var dataProvider: PostProvider = {
        let container = AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer
        let provider = PostProvider(with: container,
                                    fetchedResultsControllerDelegate: self)
        return provider
    }()

    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "PostsTableView"
        navigationItem.leftBarButtonItem = editButtonItem
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        
        // Observe .didFindRelevantTransactions to update the UI if needed.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).didFindRelevantTransactions(_:)),
            name: .didFindRelevantTransactions, object: nil)
        
        // Select the first row if any, and update the detail view.
        didUpdatePost(nil)
    }

    /**
     Clear the tableView selection when splitViewController is collapsed.
     */
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    /**
     setEditing clears the current selection which detailViewController relies on.
     
     Don’t bother to reserve the selection, just select the first item if any.
     
     Meanwhile, editButtonItem will break the tableView selection after deletions. Reloading tableView after works around the issue.
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if !editing {
            tableView.reloadData()
            didUpdatePost(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
            let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? DetailViewController else {
                return
        }
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
        
        if let indexPath = tableView.indexPathForSelectedRow {
            let post = dataProvider.fetchedResultsController.object(at: indexPath)
            controller.post = post
        }
        controller.delegate = self
        detailViewController = controller
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension MainViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            fatalError("###\(#function): Failed to dequeue a PostCell. Check the cell reusable identifier in Main.storyboard.")
        }
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        cell.title.text = post.title
        cell.post = post
        cell.collectionView.reloadData()
        cell.collectionView.invalidateIntrinsicContentSize()
        
        if let attachments = post.attachments, attachments.allObjects.isEmpty {
            cell.hasAttachmentLabel.isHidden = true
        } else {
            cell.hasAttachmentLabel.isHidden = false
        }
        
        if sharingProvider.isShared(object: post) {
            let attachment = NSTextAttachment(image: UIImage(systemName: "person.circle")!)
            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " " + (post.title ?? "")))
            cell.title.text = nil
            cell.title.attributedText = attributedString
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        dataProvider.delete(post: post) {
            self.didUpdatePost(nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        return sharingProvider.canDelete(object: post)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension MainViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

// MARK: - Handling didFindRelevantTransactions

extension MainViewController {
    /**
     Handle didFindRelevantTransactions notification.
     */
    @objc
    func didFindRelevantTransactions(_ notification: Notification) {
        guard let relevantTransactions = notification.userInfo?["transactions"] as? [NSPersistentHistoryTransaction] else { preconditionFailure() }

        guard let detailViewController = detailViewController, let post = detailViewController.post else {
            update(with: relevantTransactions, select: nil)
            return
        }

        // Check if the current selected post is deleted or updated.
        // If not, and the user isn’t editing it, merge the changes silently; otherwise, alert the user and go back to the main view.
        var isSelectedPostChanged = false
        var changeType: NSPersistentHistoryChangeType?
        
        loop0: for transaction in relevantTransactions {
            for change in transaction.changes! where change.changedObjectID == post.objectID {
                if change.changeType == .delete || change.changeType == .update {
                    isSelectedPostChanged = true
                    changeType = change.changeType
                    break loop0
                }
            }
        }
        
        // If the selection was not changed, or it was changed but the current peer isn’t editing, update the UI silently.
        // In the case where the user is viewing the full image and the post isn’t editing, alert the user as well.
        if !isSelectedPostChanged ||
            (!detailViewController.isEditing && detailViewController.presentedViewController == nil) {
            if let changeType = changeType, changeType == .delete {
                update(with: relevantTransactions, select: nil)
            } else {
                update(with: relevantTransactions, select: post)
            }
            return
        }
        
        // The selected post was changed and the user isn’t editing it.
        // Show an alert, and go back to the main view and reload everything after the user confirms.
        let alert = UIAlertController(title: "Core Data CloudKit Alert",
                                      message: "This post has been deleted by a peer!",
                                      preferredStyle: .alert)
        
        // popToRootViewController does nothing when the splitViewController is not collapsed.
        alert.addAction(UIAlertAction(title: "Reload the main view", style: .default) {_ in
            
            if detailViewController.presentedViewController != nil {
                detailViewController.dismiss(animated: true) {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
            self.resetAndReload(select: post)
        })

        // Present the alert controller.
        var presentingViewController: UIViewController = detailViewController
        if detailViewController.presentedViewController != nil {
            presentingViewController = detailViewController.presentedViewController!
        }
        presentingViewController.present(alert, animated: true)
    }
    
    // Reset and reload if the transaction count is high. When there are only a few transactions, merge the changes one by one.
    // Ten is an arbitrary choice. Adjust this number based on performance.
    private func update(with transactions: [NSPersistentHistoryTransaction], select post: Post?) {
        if transactions.count > 10 {
            print("###\(#function): Relevant transactions:\(transactions.count), reset and reload.")
            resetAndReload(select: post)
            return
        }
        
        transactions.forEach { transaction in
            guard let userInfo = transaction.objectIDNotification().userInfo else { return }
            let viewContext = dataProvider.persistentContainer.viewContext
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [viewContext])
        }
        didUpdatePost(post)
    }
    
    /**
     Reset the viewContext and reload the table view. Retain the selection and update detailViewController by calling didUpdatePost.
     */
    private func resetAndReload(select post: Post?) {
        dataProvider.persistentContainer.viewContext.reset()
        do {
            try dataProvider.fetchedResultsController.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        didUpdatePost(post)
    }
}

// MARK: - PostInteractionDelegate

extension MainViewController: PostInteractionDelegate {
    /**
     didUpdatePost is called as part of PostInteractionDelegate, or whenever a post update requires a UI update (including main-detail selections).
     
     Respond by updating the UI as follows.
     - add: make the new item visible and select it.
     - add 1000: preserve the current selection if any; otherwise select the first item.
     - delete: select the first item if possible.
     - delete all: clear the detail view.
     - update from detailViewController: reload the row, make it visible, and select it.
     - initial load: select the first item if needed.
     */
    func didUpdatePost(_ post: Post?, shouldReloadRow: Bool = false) {
        let rowCount = dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
        navigationItem.leftBarButtonItem?.isEnabled = (rowCount > 0) ? true : false

        // Get the indexPath for the post. Use the currently selected indexPath if any, or the first row otherwise.
        // indexPath will remain nil if the tableView has no data.
        var indexPath: IndexPath?
        if let post = post {
            indexPath = dataProvider.fetchedResultsController.indexPath(forObject: post)
        } else {
            indexPath = tableView.indexPathForSelectedRow
            if indexPath == nil && tableView.numberOfRows(inSection: 0) > 0 {
                indexPath = IndexPath(row: 0, section: 0)
            }
        }
        
        // Update the mainViewController: make sure the row is visible and the content is up to date.
        if let indexPath = indexPath {
            if shouldReloadRow {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
        
        // Update the detailViewController if needed.
        // shouldReloadRow is true when the change was made in the detailViewController, so no need to update.
        guard !shouldReloadRow else { return }
                
        // Reload the detailViewController if needed.
        guard let detailViewController = detailViewController else { return }
        
        if let indexPath = indexPath {
            detailViewController.post = dataProvider.fetchedResultsController.object(at: indexPath)
        } else {
            detailViewController.post = post
        }
        detailViewController.refreshUI()
    }
    
    /**
     UISplitViewController can load the detail view controller without notifying the main view controller, so manage the selection this way:
     
     - If the detailViewController is not initialized, initialize it by setting up the delegate and post.
     - If the detailViewController is initialized and has a valid post, make sure the main view controller has the right selection.
     
     The main tableView selection is cleared when splitViewController is collapsed, so rely on the controller hierarchy to do the initialization.
     */
    func willShowDetailViewController(_ controller: DetailViewController) {
        if controller.delegate == nil {
            detailViewController = controller
            controller.delegate = self
        }
        
        if let post = controller.post {
            if tableView.indexPathForSelectedRow == nil {
                if let selectedRow = dataProvider.fetchedResultsController.indexPath(forObject: post) {
                    tableView.selectRow(at: selectedRow, animated: true, scrollPosition: .none)
                }
            }
        } else {
            if tableView.numberOfRows(inSection: 0) > 0 {
                didUpdatePost(nil)
            }
        }
    }
}

// MARK: - Action handlers

extension MainViewController {
    // Create the new post on the main queue context, so there’s no need to dispatch a UI update to the main queue.
    @IBAction func add(_ sender: UIBarButtonItem) {
        dataProvider.addPost(in: dataProvider.persistentContainer.viewContext) { post in
            self.didUpdatePost(post)
        }
    }
        
    @IBAction func compose(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sender
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {_ in
            self.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Manage Tags", style: .default) {_ in
            self.dismiss(animated: true)
            self.performSegue(withIdentifier: "Tags", sender: self)
        })
        
        alert.addAction(UIAlertAction(title: "Generate 1000 Posts", style: .default) {_ in
            // Animate the spinner. Call Runloop.run(until:) to show the spinner immediately.
            self.spinner.startAnimating()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            
            // Preserve the selected post, if any, before reloading the data.
            var selectedPost: Post? = nil
            if let indexPath = self.tableView.indexPathForSelectedRow {
                selectedPost = self.dataProvider.fetchedResultsController.object(at: indexPath)
            }
            
            self.dataProvider.generateTemplatePosts(number: 1000) {
                DispatchQueue.main.async {
                    self.resetAndReload(select: selectedPost)
                    self.spinner.stopAnimating()
                }
            }
            self.dismiss(animated: true)
        })
        
        if tableView.numberOfRows(inSection: 0) > 0 {
            alert.addAction(UIAlertAction(title: "Delete All Posts", style: .destructive) {_ in
                // Animate the spinner. Call Runloop.run(until:) to show the spinner immediately.
                self.spinner.startAnimating()
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
                
                // Batch delete all posts, and refresh the UI afterward.
                self.dataProvider.batchDeleteAllPosts() {
                    DispatchQueue.main.async {
                        self.resetAndReload(select: nil)
                        self.spinner.stopAnimating()
                    }
                }
                self.dismiss(animated: true)
            })
        }
        
        present(alert, animated: true)
    }
}
