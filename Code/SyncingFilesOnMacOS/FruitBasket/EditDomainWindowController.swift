/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller for editing a domain's details.
*/

import AppKit
import FileProvider
import Common
import Extension
import os.log

class EditDomainWindowController: NSWindowController {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "edit-domain")

    @objc class var keyPathsForValuesAffectingIdentifier: Set<String> {
        return ["displayName"]
    }

    @objc dynamic var displayName: String = ""
    @objc dynamic var identifier: String {
        "\(domain.identifier.rawValue)"
    }
    @IBOutlet weak var backingItem: NSPopUpButton!

    init(_ domain: NSFileProviderDomain, _ accountConnection: DomainConnection, _ allDomains: [NSFileProviderDomain],
         _ allAccounts: [AccountService.Account]) {
        self.domain = domain
        self.accountConnection = accountConnection
        self.allDomains = allDomains
        self.allAccounts = allAccounts
        super.init(window: nil)
        self.loadWindow()
        updateValues()
    }

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EditDomainWindow")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var delegate: AppDelegate?
    let domain: NSFileProviderDomain
    let accountConnection: DomainConnection
    let allDomains: [NSFileProviderDomain]
    let allAccounts: [AccountService.Account]

    var allRoots: [DomainService.Entry]? = nil
    func updateValues() {
        allRoots = allAccounts.map({ $0.rootItem })
        displayName = domain.displayName

        func title(for root: DomainService.Entry) -> String {
            let identifiers = allAccounts.filter { $0.rootItem.id == root.id }.map { NSFileProviderDomainIdentifier(rawValue: $0.identifier) }
            let titles = allDomains.filter { identifiers.contains($0.identifier) }.map({ $0.displayName })
            if !titles.isEmpty {
                return "\(root.id) (\(titles.joined(separator: ", ")))"
            } else {
                return "\(root.id)"
            }

        }

        // Remove all items from the popover. Add <New Root> item and items for all roots.
        backingItem.removeAllItems()
        backingItem.addItem(withTitle: "<New Root>")
        let selectedRoot = allAccounts.first(where: { $0.identifier == domain.identifier.rawValue })?.rootItem
        if let roots = allRoots {
            for root in roots {
                backingItem.addItem(withTitle: title(for: root))
                backingItem.lastItem!.representedObject = root
                // If the most recently added item corresponds to the domain's current root, select it.
                if root.id == selectedRoot?.id {
                    backingItem.select(backingItem.itemArray.last)
                }
            }
        }
        // If no root is selected, prefer reusing an existing root over creating a new one.
        if selectedRoot == nil {
            backingItem.select(backingItem.itemArray.last)
        }
    }

    @IBAction func saveButton(_ sender: Any) {
        async {
            guard let window = window, allRoots != nil else { fatalError() }

            guard !displayName.isEmpty else { return }
            let displayName = self.displayName

            let newDomain = NSFileProviderDomain(identifier: domain.identifier, displayName: displayName)

            let oldRoot = allAccounts.first(where: { $0.identifier == domain.identifier.rawValue })?.rootItem
            let newRoot: DomainService.Entry

            if backingItem.indexOfSelectedItem == 0 {
                do {
                    let param = AccountService.CreateAccountParameter(displayName: displayName, identifier: domain.identifier.rawValue,
                                                                      mirroringAccount: nil, remoteOnly: true)
                    newRoot = try accountConnection.makeSynchronousJSONCall(param, nil, timeout: .seconds(3)).account.rootItem
                } catch let error as NSError {
                    self.logger.error("❌ failed to create new account \(error)")
                    self.delegate?.presentError(error)
                    return
                }
            } else {

                guard let mirroredRoot = backingItem.selectedItem!.representedObject as? DomainService.Entry,
                let mirroredAccount = allAccounts.first(where: { $0.rootItem.id == mirroredRoot.id }) else {
                    self.logger.error("❌ failed to setup mirroring account")
                    return
                }
                do {
                    let param = AccountService.CreateAccountParameter(displayName: displayName, identifier: domain.identifier.rawValue,
                                                                      mirroringAccount: mirroredAccount.identifier, remoteOnly: true)
                    newRoot = try accountConnection.makeSynchronousJSONCall(param, nil, timeout: .seconds(3)).account.rootItem
                } catch let error as NSError {
                    self.logger.error("❌ failed to create new account \(error)")
                    self.delegate?.presentError(error)
                    return
                }
            }

            if let existing = oldRoot,
                newRoot.id != existing.id {
                let mirroredAccount = allAccounts.first(where: { $0.rootItem.id == newRoot.id })

                do {
                    try await NSFileProviderManager.remove(newDomain)
                } catch let error as NSError {
                    self.logger.error("❌ failed to remove existing domain \(error)")
                    self.delegate?.presentError(error)
                    return
                }
                let param = AccountService.CreateAccountParameter(displayName: displayName, identifier: newDomain.identifier.rawValue,
                                                                  mirroringAccount: mirroredAccount?.identifier, remoteOnly: true)
                do {
                    _ = try await self.accountConnection.makeJSONCall(param)
                } catch let error as NSError {
                    self.logger.error("❌ failed to create new account \(error)")
                    self.delegate?.presentError(error)
                    return
                }
                do {
                    try await NSFileProviderManager.add(newDomain)
                } catch let error as NSError {
                    self.logger.error("❌ failed to re-add domain \(error)")
                    self.delegate?.presentError(error)
                    return
                }

                DispatchQueue.main.async {
                    window.sheetParent?.endSheet(window)
                }
            } else {
                do {
                    try await NSFileProviderManager.add(newDomain)
                } catch let error as NSError {
                    self.logger.error("❌ failed to add domain \(error)")
                    self.delegate?.presentError(error)
                    return
                }
                DispatchQueue.main.async {
                    window.sheetParent?.endSheet(window)
                }
            }
        }
    }

    @IBOutlet weak var button: NSButton!
    @IBAction func cancelButton(_ sender: Any) {
        guard let window = window else { fatalError() }
        window.sheetParent?.endSheet(window)
    }
}
