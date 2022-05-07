/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller for displaying options when removing a domain.
*/

import AppKit
import FileProvider
import Common
import Extension
import os.log

class RemoveDomainWindowController: NSWindowController {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "remove-domain")

    @objc class var keyPathsForValuesAffectingIdentifier: Set<String> {
        return ["displayName"]
    }

    @objc dynamic var displayName: String = ""
    @objc dynamic var identifier: String {
        "\(domain.identifier.rawValue)"
    }

    init(_ domain: NSFileProviderDomain, _ accountConnection: DomainConnection, spinner: NSProgressIndicator) {
        self.domain = domain
        self.accountConnection = accountConnection
        self.spinner = spinner
        super.init(window: nil)
        self.loadWindow()
    }

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("RemoveDomainWindow")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var delegate: AppDelegate?
    let domain: NSFileProviderDomain
    let accountConnection: DomainConnection
    var removeMode: NSFileProviderManager.DomainRemovalMode = .removeAll
    var spinner: NSProgressIndicator

    @IBOutlet weak var removeAllRadioButton: NSButton!
    @IBOutlet weak var preserveDownloadedRadioButton: NSButton!
    @IBOutlet weak var preserveDirtyRadioButton: NSButton!
    @IBAction func radioButtonClick(_ sender: NSButton) {
        if sender == self.removeAllRadioButton {
            self.removeMode = .removeAll
        }

        if sender == self.preserveDownloadedRadioButton {
            self.removeMode = .preserveDownloadedUserData
        }

        if sender == self.preserveDirtyRadioButton {
            self.removeMode = .preserveDirtyUserData
        }
    }

    @IBAction func removeButton(_ sender: Any) {
        guard let window = window else { fatalError() }
        let group = DispatchGroup()
        self.spinner.startAnimation(nil)
        group.enter()

        async {
            defer {
                group.leave()
            }
            let url: URL?
            do {
                url = try await NSFileProviderManager.remove(self.domain, mode: self.removeMode)
                let param = AccountService.RemoveAccountParameter(identifiers: [self.domain.identifier.rawValue], remoteOnly: true)
                _ = try await self.accountConnection.makeJSONCall(param)
                if let preservedURL = url {
                    let stop = preservedURL.startAccessingSecurityScopedResource()
                    defer {
                        if stop {
                            preservedURL.stopAccessingSecurityScopedResource()
                        }
                    }
                    self.logger.info("✅ domain was preserved to \(preservedURL)")
                    NSWorkspace().selectFile(nil, inFileViewerRootedAtPath: preservedURL.path)
                }
            } catch let error as NSError {
                self.logger.error("❌ failed to remove domain \(error)")
                DispatchQueue.main.async {
                    self.presentError(error)
                }
                return
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.spinner.stopAnimation(nil)
        }
        window.sheetParent?.endSheet(window)
    }

    @IBOutlet weak var button: NSButton!
    @IBAction func cancelButton(_ sender: Any) {
        guard let window = window else { fatalError() }
        window.sheetParent?.endSheet(window)
    }
}
