/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View and notifications for viewing pending and materialized items.
*/

import SwiftUI
import FileProvider
import UniformTypeIdentifiers
import os.log

public extension NSNotification.Name {
    static let pendingItemsDidChange: NSNotification.Name = NSNotification.Name(rawValue: Bundle(for:
        EnumerationView.EnumeratorObservableObject.self).bundleIdentifier!.appending(".pendingItemsDidChange"))
    static let materializedItemsDidChange: NSNotification.Name = NSNotification.Name(rawValue: Bundle(for:
        EnumerationView.EnumeratorObservableObject.self).bundleIdentifier!.appending(".materializedItemsDidChange"))

}

public struct EnumerationView: View {
    public enum EnumerationType {
        case pending
        case materialized
    }
    
    // An observable object for the pending set.
    class EnumeratorObservableObject: NSObject, NSFileProviderChangeObserver, NSFileProviderEnumerationObserver, ObservableObject {
        private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "pending")

        @Published var items = [Entry]()
        @Published var error: Error?
        
        var state = State.idle {
            didSet {
                logger.debug("\(String(describing: self.enumerationType)) enumeration moved to \(String(describing: self.state))")
            }
        }

        internal let enumerator: NSFileProviderEnumerator
        internal var anchor: NSFileProviderSyncAnchor!
        internal let enumerationType: EnumerationType
        
        // State is used primarily for logging.
        enum State {
            case fetchingAnchor
            case enumeratingItems
            case enumeratingChanges
            case idle
            case error
        }
        
        init(_ domain: NSFileProviderDomain, _ which: EnumerationType) {
            enumerationType = which
            switch which {
            case .materialized:
                enumerator = NSFileProviderManager(for: domain)!.enumeratorForMaterializedItems()
            case .pending:
                enumerator = NSFileProviderManager(for: domain)!.enumeratorForPendingItems()
            }
            super.init()
            enumerateFromScratch()
            
            switch which {
            case .pending:
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(enumeratedSetDidChange(_:)),
                                                                    name: .pendingItemsDidChange, object: nil,
                                                                    suspensionBehavior: .deliverImmediately)
            case .materialized:
                DistributedNotificationCenter.default().addObserver(self, selector: #selector(enumeratedSetDidChange(_:)),
                                                                    name: .materializedItemsDidChange, object: nil,
                                                                    suspensionBehavior: .deliverImmediately)
            }
        }
        
        deinit {
            DistributedNotificationCenter.default().removeObserver(self)
        }
        
        @objc
        func enumeratedSetDidChange(_ notification: NSNotification) {
            signal()
        }
        
        func signal() {
            guard state == .idle || state == .error else {
                return
            }
            if state == .error {
                enumerateFromScratch()
            } else {
                enumerator.enumerateChanges?(for: self, from: anchor)
            }
        }
        
        func enumerateFromScratch() {
            guard state == .idle || state == .error else {
                fatalError("unexpected state \(state)")
            }
            state = .fetchingAnchor
            guard let cur = enumerator.currentSyncAnchor else {
                fatalError("\(enumerationType) set enumerator doesn't support currentSyncAnchor. This is unexpected.")
            }
            cur({ anchor in
                self.anchor = anchor
                self.state = .enumeratingItems
                self.enumerator.enumerateItems(for: self, startingAt: NSFileProviderPage.initialPageSortedByDate as NSFileProviderPage)
            })
        }
        
        func enumerateFromAnchor() {
            state = .enumeratingChanges
            enumerator.enumerateChanges?(for: self, from: anchor)
        }
        
        func finishEnumeratingWithError(_ error: Error) {
            state = .error
            self.error = error
        }

        func finishEnumerating(upTo nextPage: NSFileProviderPage?) {
            guard let nextPage = nextPage else {
                enumerateFromAnchor()
                return
            }
            enumerator.enumerateItems(for: self, startingAt: nextPage)
        }
        
        func finishEnumeratingChanges(upTo anchor: NSFileProviderSyncAnchor, moreComing: Bool) {
            self.anchor = anchor
            
            if moreComing {
                enumerateFromAnchor()
            } else {
                state = .idle
            }
        }

        internal func addOrUpdateEntries(_ updatedItems: [Entry]) {
            dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
            updatedItems.forEach { item in
                if let idx = items.firstIndex(where: { $0 == item }) {
                    items[idx] = item
                } else {
                    items.append(item)
                }
            }
        }
        
        func didUpdate(_ updatedItems: [NSFileProviderItemProtocol]) {
            let newEntries = updatedItems.map({ Entry(item: $0) })
            DispatchQueue.main.async {
                self.addOrUpdateEntries(newEntries)
            }
        }
        
        func didDeleteItems(withIdentifiers deletedItemIdentifiers: [NSFileProviderItemIdentifier]) {
            DispatchQueue.main.async {
                self.items = self.items.filter({ !deletedItemIdentifiers.contains($0.item.itemIdentifier) })
            }
        }
        
        func didEnumerate(_ updatedItems: [NSFileProviderItemProtocol]) {
            let newEntries = updatedItems.map({ Entry(item: $0) })
            DispatchQueue.main.async {
                self.addOrUpdateEntries(newEntries)
            }
        }
        
        // The entry is a wrapper for easier access to the properties
        // displayed in the table.
        struct Entry: Identifiable, Hashable {
            var id: String { item.itemIdentifier.rawValue }
            
            static func == (lhs: Entry, rhs: Entry) -> Bool {
                rhs.item.itemIdentifier == lhs.item.itemIdentifier
            }
            
            func hash(into hasher: inout Hasher) {
                item.itemIdentifier.hash(into: &hasher)
            }
            
            internal let item: NSFileProviderItem
            
            var filename: String { item.filename }
            var itemID: String { "#\(item.itemIdentifier.rawValue)" }
            var itemType: ItemType { item.contentType! == UTType.folder ? .folder : .file }
            var error: String? {
                guard let error = item.uploadingError! else {
                    return nil
                }
                return error.localizedDescription
            }
            enum ItemType {
                case file
                case folder
            }
        }
    }
    public init(_ domain: NSFileProviderDomain, _ which: EnumerationType) {
        enumerated = EnumeratorObservableObject(domain, which)
    }
    
    @ObservedObject var enumerated: EnumeratorObservableObject
    public var body: some View {
        if let error = enumerated.error {
            HStack {
                Text(error.localizedDescription)
                Button("Retry") {
                    enumerated.signal()
                }
            }
            .padding()
        } else if enumerated.items.isEmpty {
            Text("No items")
                .padding()
        } else {
            Form {
                List {
                    ForEach(enumerated.items) { entry in
                        ItemRow(entry: entry)
                    }
                }
            }.padding()
        }
    }
}

struct ItemRow: View {
    let entry: EnumerationView.EnumeratorObservableObject.Entry
    
    var body: some View {
        HStack {
            switch entry.itemType {
            case .file:
                Image(systemName: "doc")
            case .folder:
                Image(systemName: "folder")
            }
            VStack(alignment: .leading) {
                Text(entry.filename) + Text(" \(entry.itemID)").foregroundColor(Color.gray)
                if let error = entry.error {
                    Text(error)
                        .foregroundColor(Color.gray)
                } else {
                    Text("No error")
                        .foregroundColor(Color.gray)
                }
            }
        }
    }
}
