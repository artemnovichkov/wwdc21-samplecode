/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that displays the postcards.
*/

import UIKit

class ViewController: UIViewController,
    UIFontPickerViewControllerDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    UITextViewDelegate {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    var imageViewAspectRatioConstraint: NSLayoutConstraint?
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 8.0
        imageView.layer.cornerCurve = .continuous
    }
    
    // MARK: SettingsViewController
    
    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        guard presentedViewController == nil else {
            dismiss(animated: true, completion: {
                self.showSettings(sender)
            })
            return
        }
        
        if let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "settings") {
            settingsViewController.modalPresentationStyle = .popover
            if let popover = settingsViewController.popoverPresentationController {
                popover.barButtonItem = sender
                
                let sheet = popover.adaptiveSheetPresentationController
                sheet.detents = [.medium(), .large()]
                sheet.smallestUndimmedDetentIdentifier =
                PresentationHelper.sharedInstance.smallestUndimmedDetentIdentifier
                sheet.prefersScrollingExpandsWhenScrolledToEdge =
                PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
                sheet.prefersEdgeAttachedInCompactHeight =
                PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached =
                PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
            }
            
            textView.resignFirstResponder()
            present(settingsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: UIImagePickerViewController
    
    @IBAction func showImagePicker(_ sender: UIBarButtonItem) {
        
        guard presentedViewController == nil else {
            dismiss(animated: true, completion: {
                self.showImagePicker(sender)
            })
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .popover
        if let popover = imagePicker.popoverPresentationController {
            popover.barButtonItem = sender
            
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.smallestUndimmedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge =
            PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
            sheet.prefersEdgeAttachedInCompactHeight =
            PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached =
            PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
        }
        
        textView.resignFirstResponder()
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            
            if let constraint = imageViewAspectRatioConstraint {
                NSLayoutConstraint.deactivate([constraint])
            }
            let newConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: image.size.width / image.size.height)
            NSLayoutConstraint.activate([newConstraint])
            imageViewAspectRatioConstraint = newConstraint
            
            view.layoutIfNeeded()
        }
        
        if let sheet = picker.popoverPresentationController?.adaptiveSheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .medium
            }
        }
    }
    
    // MARK: UIFontPickerViewController
    
    @IBAction func showFontPicker(_ sender: UIBarButtonItem) {
        
        guard presentedViewController == nil else {
            dismiss(animated: true, completion: {
                self.showFontPicker(sender)
            })
            return
        }
        
        let fontPicker = UIFontPickerViewController()
        fontPicker.delegate = self
        fontPicker.modalPresentationStyle = .popover
        if let popover = fontPicker.popoverPresentationController {
            popover.barButtonItem = sender
            
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [.medium(), .large()]
            sheet.smallestUndimmedDetentIdentifier =
            PresentationHelper.sharedInstance.smallestUndimmedDetentIdentifier
            sheet.prefersScrollingExpandsWhenScrolledToEdge =
            PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
            sheet.prefersEdgeAttachedInCompactHeight =
            PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached =
            PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
        }
        
        textView.resignFirstResponder()
        present(fontPicker, animated: true, completion: nil)
        
        let inputView = UIInputView(frame: .zero, inputViewStyle: .default)
        inputView.isUserInteractionEnabled = false
        inputView.allowsSelfSizing = true
        textView.inputView = inputView
        textView.reloadInputViews()
    }
    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        
        if let descriptor = viewController.selectedFontDescriptor {
            let font = UIFont(descriptor: descriptor, size: 56.0)
            let selectedRange = textView.selectedRange
            
            if textView.isFirstResponder {
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
                attributedText.addAttribute(.font, value: font, range: selectedRange)
                textView.attributedText = attributedText
                textView.selectedRange = selectedRange
            } else {
                textView.font = font
            }
            
            view.layoutIfNeeded()
        }
        
        if let sheet = viewController.popoverPresentationController?.adaptiveSheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .medium
            }
        }
    }
    
    func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
        dismiss(animated: true)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        // Reset the inputView each time we dismiss a view controller.
        self.textView.inputView = nil
        self.textView.reloadInputViews()
    }
    
    // MARK: UITextView
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if presentedViewController != nil {
            dismiss(animated: true)
        }
    }
}
