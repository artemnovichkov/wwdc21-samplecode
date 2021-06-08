/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An action view controller for viewing and resolving file conflicts.
*/

import Cocoa
import Common
import Extension
import FileProviderUI
import os.log

private func valueOrNil<T>(_ value: T?) -> String {
    if let value = value {
        return "\(value)"
    }
    return "nil"
}

public class ConflictViewController: NSViewController, ConcreteActionViewController {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "conflict")

    let itemIdentifiers: [NSFileProviderItemIdentifier]

    init(_ itemIdentifiers: [NSFileProviderItemIdentifier]) {
        self.itemIdentifiers = itemIdentifiers
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var nibName: NSNib.Name? {
        return NSNib.Name("ConflictViewController")
    }

    var actionViewController: ActionViewController! {
        return parent as? ActionViewController
    }
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var explanatoryText: NSTextField!
    @IBOutlet weak var conflictTable: NSScrollView!
    @IBOutlet weak var closeButton: NSButton!
    class ConflictDescriptor: NSObject {
        convenience init(_ data: Data) {
            self.init(try! JSONDecoder().decode(DomainService.ConflictVersion.self, from: data))
        }

        init(_ conflict: DomainService.ConflictVersion) {
            keepVersion = false
            originatorName = conflict.originatorName
            creationDate = conflict.creationDate
            conflictVersion = conflict
        }

        @objc dynamic var keepVersion: Bool
        @objc dynamic var originatorName: String
        @objc dynamic var creationDate: Date
        let conflictVersion: DomainService.ConflictVersion
    }

    var selectedVersions: [DomainService.ConflictVersion] {
        conflicts.filter(\.keepVersion).map(\.conflictVersion)
    }

    @IBAction func keepChanged(_ sender: Any) {
        let selected = selectedVersions.count
        if selected == 1 {
            closeButton.isEnabled = true
            closeButton.title = "Keep selected version"
        } else if selected > 1 {
            closeButton.isEnabled = true
            closeButton.title = "Keep \(selected) versions"
        } else {
            // No versions are selected; disable the close button.
            closeButton.isEnabled = false
            closeButton.title = "Keep selected versions"
        }
    }

    @objc dynamic var conflicts = [ConflictDescriptor]()
    var baseVersion: Data?

    internal func close(with error: Error? = nil) {
        actionViewController.extensionContext.cancelRequest(withError: error ?? CommonError.internalError)
    }

    internal func withServiceConnection() async throws -> FruitBasketServiceV1 {
        let url = try await self.manager.getUserVisibleURL(for: self.itemIdentifier)
        self.itemURL = url

        let services = try await FileManager().fileProviderServicesForItem(at: url)
        guard let service = services[fruitBasketServiceName] else {
            self.logger.error("couldn't get service, fruitBasketServiceName not present")
            throw NSFileProviderError(.providerNotFound)
        }
        let connection: NSXPCConnection
        connection = try await service.fileProviderConnection()
        connection.remoteObjectInterface = fruitBasketServiceInterface
        connection.interruptionHandler = {
            self.logger.error("service connection interrupted")
        }
        connection.resume()
        guard let proxy = connection.remoteObjectProxy as? FruitBasketServiceV1 else {
            throw NSFileProviderError(.serverUnreachable)
         }
        return proxy
     }

    var itemIdentifier: NSFileProviderItemIdentifier!
    var itemURL: URL!
    var manager: NSFileProviderManager!

    public func prepareForDisplay() {
        keepChanged(self)
        explanatoryText.stringValue = "Updating versions..."
        spinner.startAnimation(nil)
        guard let firstItem = itemIdentifiers.first else {
            logger.error("called without items")
            close()
            return
        }
        guard let manager = NSFileProviderManager(for: actionViewController.domain) else {
            fatalError("NSFileProviderManager isn't expected to fail")
        }
        self.manager = manager
        itemIdentifier = firstItem

        self.logger.debug("⭐️ fetching versions")
        async {
            do {
                let proxy = try await self.withServiceConnection()
                let (versions, baseVersion) = try await proxy.versions(for: self.itemURL)
                self.logger.debug("✅ versions:")
                let entries = versions.map({ ConflictDescriptor($0 as Data) })
                await MainActor.run {
                    self.explanatoryText.stringValue = "Select which versions of the document to keep:"
                    self.spinner.stopAnimation(nil)
                    self.conflicts = entries
                    self.baseVersion = baseVersion as Data
                }
            } catch {
                self.logger.error("failed to fetch versions")
                self.close(with: error)
                return
            }
        }
    }

    @IBAction func cancel(_ sender: Any) {
        actionViewController.extensionContext.completeRequest()
    }

    @IBAction func close(_ sender: Any) {
        spinner.startAnimation(nil)
        let selected = selectedVersions
        guard !selected.isEmpty else {
            actionViewController.extensionContext.completeRequest()
            return
        }
        guard let baseVersion = baseVersion else {
            actionViewController.extensionContext.cancelRequest(withError: CommonError.parameterError)
            return
        }
        closeButton.isEnabled = false
        async {
            do {
                let proxy = try await self.withServiceConnection()
                try await proxy.keep(versions: selected.map({ $0.contentVersion as NSNumber }), baseVersion: baseVersion as NSData, for: self.itemURL)
                self.actionViewController.extensionContext.completeRequest()
            } catch let error as NSError {
                self.logger.error("failed to select versions \(error)")
            }
        }
    }
}

class EditDateValueTransformer: ValueTransformer {
    open override func transformedValue(_ value: Any?) -> Any? {
        guard let val = value as? Date else { return "unknown" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter.string(from: val)
    }
}
