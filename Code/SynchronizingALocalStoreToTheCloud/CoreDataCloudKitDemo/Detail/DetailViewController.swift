/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller class to show and edit the details of a post.
*/

import UIKit
import CoreData
import CloudKit
import CoreLocation

class DetailViewController: SpinnerViewController, UICloudSharingControllerDelegate {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var tagsCell: TagCollectionCell!
    @IBOutlet weak var attachmentsCell: AttachmentCollectionCell!
    @IBOutlet weak var tagsCellAccessoryButton: UIButton!
    @IBOutlet weak var attachmentsCellAccessoryButton: UIButton!
    @IBOutlet weak var locationTextField: UITextField!
    private var geocoder: CLGeocoder?
    var shareButtonItem: UIBarButtonItem?
    var share: RenderableShare?
    var sharingProvider: SharingProvider = AppDelegate.sharedAppDelegate.coreDataStack

    // Table view section ID constants.
    private struct Section {
        static let location = 2
        static let tags = 3
        static let attachments = 4
        static let participants = 5
    }
    
    weak var delegate: PostInteractionDelegate?
    var post: Post? {
        didSet {
            DispatchQueue.main.async {
                self.refreshUI()
            }
        }
    }
    
    private lazy var attachmentProvider: AttachmentProvider = {
        let appDelegate = AppDelegate.sharedAppDelegate
        let provider = AttachmentProvider(with: appDelegate.coreDataStack.persistentContainer)
        return provider
    }()

    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareNoteAction(_:)))
        navigationItem.rightBarButtonItems = [shareButtonItem!, editButtonItem]
        
        if AppDelegate.sharedAppDelegate.locationAuthorized {
            geocoder = CLGeocoder()
        }
        
        titleTextField.text = post?.title ?? ""
        contentTextView.text = post?.content ?? ""
        attachmentsCell.delegate = self
        
        // Refresh the UI in the next run loop to reload the collection views after the view loading process.
        // This makes sure the collection view size is exactly the same as the layout content size.
        // Not in viewDidAppear because it is first needed after the collection views are loaded.
        DispatchQueue.main.async {
            self.refreshUI()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navController = splitViewController?.viewControllers[0] as? UINavigationController,
            let mainViewController = navController.viewControllers[0] as? MainViewController {
            mainViewController.willShowDetailViewController(self)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        // Before calling super.setEditing to recognize the switch to Done,
        // resign the first responder if needed and make sure the title is valid.
        if !editing {
            if titleTextField.isFirstResponder {
                titleTextField.resignFirstResponder()
            }
            if contentTextView.isFirstResponder {
                contentTextView.resignFirstResponder()
            }
            if let title = titleTextField.text, title.isEmpty {
                let alert = UIAlertController(title: "Warning",
                                              message: "The post title is now empty.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        }

        // Call super’s implementation to switch the status.
        super.setEditing(editing, animated: false)

        // Update the UI based on the editing state.
        titleTextField.isEnabled = editing
        contentTextView.isEditable = editing
        
        // If the UI is entering the editing state, simply return.
        guard !editing, let post = post else { return }
        
        // If exiting the editing state, save the changes and update the UI.
        // post should not be nil in this case.
        let context = post.managedObjectContext!
        context.performAndWait {
            post.title = titleTextField.text
            post.content = contentTextView.text
            context.save(with: .updatePost)
        }
        
        guard let attachments = post.attachments else { return }
        
        // Call RunLoop.run(until:) to show the spinner immediately.
        spinner.startAnimating()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))

        let taskContext = attachmentProvider.persistentContainer.backgroundContext()
        attachmentProvider.saveImageDataIfNeeded(for: attachments, taskContext: taskContext) {
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
            }
        }
        delegate?.didUpdatePost(post, shouldReloadRow: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "tagPicker",
            let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? TagPickerViewController else {
                return
        }
        prepareForPresentingPicker()
        controller.post = post
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension DetailViewController {
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, indentationLevelForRowAt indexPath: IndexPath) -> Int {
        return 0
    }
    
    /**
     Cap the row height to 44 points for tag cells, and 80 points for attachment cells.
     Add two points to make the collectionView slightly larger to avoid scrolling.
     */
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == Section.tags {
            let height = tagsCell.collectionView.collectionViewLayout.collectionViewContentSize.height + 2
            return height > 44 ? height : 44
            
        } else if indexPath.section == Section.attachments {
            let height = attachmentsCell.collectionView.collectionViewLayout.collectionViewContentSize.height + 2
            return height > 80 ? height : 80
        } else if indexPath.section == Section.participants {
            return 44
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == Section.participants {
            return share?.renderableParticipants.count ?? 0
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Section.participants {
            var cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ParticipantCell")
            }
            
            guard let participantCell = cell else {
                fatalError("Failed to generate a cell for participant at \(indexPath)")
            }
            
            guard let participant = share?.renderableParticipants[indexPath.row] else {
                fatalError("Failed to find participant at \(indexPath)")
            }
            
            if let firstName = participant.renderableUserIdentity.nameComponents?.givenName,
               let lastName = participant.renderableUserIdentity.nameComponents?.familyName {
                participantCell.textLabel?.text = "\(firstName) \(lastName)"
            } else {
                participantCell.textLabel?.text = participant.renderableUserIdentity.contactIdentifiers.first
            }
            
            let role = DetailViewController.string(for: participant.role)
            let permission = DetailViewController.string(for: participant.permission)
            let acceptanceStatus = DetailViewController.string(for: participant.acceptanceStatus)
            participantCell.detailTextLabel?.text = "\(role) - \(permission) - \(acceptanceStatus)"
            
            return participantCell
        } else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension DetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 1),
            let url = info[.imageURL] as? URL else {
                fatalError("###\(#function): Failed to get JPG data and URL of the picked image!")
        }
        attachmentProvider.addAttachment(imageData: data, imageURL: url, post: post,
                                         taskContext: attachmentProvider.persistentContainer.viewContext, shouldSave: false)
        dismiss(animated: true)
        refreshUI()
        spinner.stopAnimating()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
        spinner.stopAnimating()
    }
}

// MARK: - AttachmentCVCellDelegate

extension DetailViewController: AttachmentInteractionDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentCVCell else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let navController = storyboard.instantiateViewController(withIdentifier: "fullImageNC") as? UINavigationController,
            let fullImageViewController = navController.topViewController as? FullImageViewController else {
                return
        }

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let taskContext = appDelegate!.coreDataStack.persistentContainer.backgroundContext()
        
        spinner.startAnimating()
        
        fullImageViewController.fullImage = cell.attachment.getImage(with: taskContext)
        present(navController, animated: true) {
            self.spinner.stopAnimating()
        }
    }
    
    func delete(attachment: Attachment, at indexPath: IndexPath) {
        attachmentProvider.deleteAttachment(attachment, shouldSave: false)
        refreshUI()
    }
}

// MARK: - Action handlers

extension DetailViewController {
    @IBAction func backFromTagPickerViewController(segue: UIStoryboardSegue) {
        refreshUI()
    }
        
    @IBAction func showAttachmentPicker(_ sender: UIButton) {
        spinner.startAnimating()
        prepareForPresentingPicker()
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    /**
     Refresh the whole table view with the post. This refresh is light enough to handle all sections at once.
     */
    func refreshUI() {
        if let actualPost = post {
            if sharingProvider.canEdit(object: actualPost) {
                editButtonItem.isEnabled = true
            } else {
                editButtonItem.isEnabled = false
            }
            shareButtonItem?.isEnabled = true
            titleTextField.text = actualPost.title ?? ""
            contentTextView.text = actualPost.content ?? ""
            attachmentsCell.post = actualPost
            tagsCell.post = actualPost
            
            if let location = actualPost.location {
                if let coder = geocoder {
                    let postID = actualPost.objectID
                    coder.reverseGeocodeLocation(location) { placemarks, error in
                        guard let realPlacemarks = placemarks else {
                            fatalError("Failed to reverse geocode location \(String(describing: error))")
                        }
                        
                        if let placemark = realPlacemarks.first {
                            self.updateLocationTextField(to: placemark, for: postID)
                        }
                    }
                }
            }
            
            do {
                share = try sharingProvider.shares(matching: [actualPost.objectID])[actualPost.objectID]
            } catch let error {
                fatalError("Fetching shares failed for \(actualPost) with error: \(error)")
            }
        } else {
            editButtonItem.isEnabled = false
            shareButtonItem?.isEnabled = false
            titleTextField.text = ""
            contentTextView.text = ""
            share = nil
        }
        
        attachmentsCell.collectionView.reloadData()
        tagsCell.collectionView.reloadData()
        let tagRow = IndexPath(row: 0, section: Section.tags)
        let attachmentsRow = IndexPath(row: 0, section: Section.attachments)
        tableView.beginUpdates()
        tableView.reloadRows(at: [tagRow, attachmentsRow], with: .none)
        tableView.reloadSections(IndexSet(integer: Section.participants),
                                 with: UITableView.RowAnimation.automatic)
        tableView.endUpdates()
    }
    
    func updateLocationTextField(to placemark: CLPlacemark, for postID: NSManagedObjectID) {
        guard let post = post else {
            return
        }
        
        if post.objectID == postID,
           let city = placemark.locality,
           let state = placemark.administrativeArea {
            locationTextField.text = "\(city), \(state)"
        }
    }
    
    /**
     Hide the keyboard if any and pick up the title and content fields.
     */
    private func prepareForPresentingPicker() {
        if titleTextField.isFirstResponder {
            titleTextField.resignFirstResponder()
        }
        if contentTextView.isFirstResponder {
            contentTextView.resignFirstResponder()
        }
        if let context = post?.managedObjectContext {
            let title = titleTextField.text
            let content = contentTextView.text
            context.perform {
                self.post?.title = title
                self.post?.content = content
            }
        }
    }
}
