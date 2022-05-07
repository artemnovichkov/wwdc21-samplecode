/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adds custom actions to the extension.
*/

import os.log
import Common
import FileProvider

extension NSFileProviderExtensionActionIdentifier {
    static let heart = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.Heart")
    static let unheart = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.Unheart")
    static let forceLock = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.ForceLock")
    static let pin = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.Pin")
    static let unpin = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.Unpin")
    static let evictFolder = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.EvictFolder")
    static let startSharing = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.StartSharing")
    static let stopSharing = NSFileProviderExtensionActionIdentifier("com.example.apple-samplecode.FruitBasket.Action.StopSharing")
}

extension Extension: NSFileProviderCustomAction {
    public func performAction(identifier actionIdentifier: NSFileProviderExtensionActionIdentifier,
                              onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
                              completionHandler: @escaping (Error?) -> Void) -> Progress {
        logger.debug("🧩 performAction(with \(actionIdentifier.rawValue), onItemsWithIdentifiers: \(itemIdentifiers.map({ $0.rawValue })))")

        let progress: Progress
        let identifiers = itemIdentifiers.compactMap(DomainService.ItemIdentifier.init)
        switch actionIdentifier {
        case .heart, .unheart:
            let mark = DomainService.MarkParameter(identifiers: identifiers, heart: actionIdentifier == .heart)
            progress = performMarkAction(mark, completionHandler: completionHandler)
        case .startSharing, .stopSharing:
            let mark = DomainService.MarkParameter(identifiers: identifiers, isShared: actionIdentifier == .startSharing)
            progress = performMarkAction(mark, completionHandler: completionHandler)
        case .forceLock:
            progress = performForceLockAction(onItemsWithIdentifiers: itemIdentifiers, completionHandler: completionHandler)
        case .pin, .unpin:
            progress = performPinAction(withValue: actionIdentifier == .pin, onItemsWithIdentifiers: itemIdentifiers,
                                        completionHandler: completionHandler)
        case .evictFolder:
            progress = performEvictFolderAction(onItemsWithIdentifiers: itemIdentifiers, completionHandler: completionHandler)
        default:
            completionHandler(CommonError.notImplemented.toPresentableError())
            progress = Progress()
        }

        progress.cancellationHandler = { completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)) }
        return progress
    }

    private func performMarkAction(_ mark: DomainService.MarkParameter, completionHandler: @escaping (Error?) -> Void) -> Progress {
        guard !mark.identifiers.isEmpty else {
            completionHandler(CommonError.notImplemented.toPresentableError())
            return Progress()
        }
        return connection.makeJSONCall(mark) {
            switch $0 {
            case .failure(let error):
                completionHandler(error.toPresentableError())
            case .success:
                completionHandler(nil)
            }
        }
    }

    private func performForceLockAction(onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
                                        completionHandler: @escaping (Error?) -> Void) -> Progress {
        let items = itemIdentifiers.compactMap(DomainService.ItemIdentifier.init)
        // Since forcing the lock is such an aggressive measure, we only allow it
        // to happen for one item at a time. This is enforced here and also in the
        // predicate in NSExtensionFileProviderActions.
        guard items.count == 1,
            let item = items.first else {
            completionHandler(CommonError.notImplemented.toPresentableError())
            return Progress()
        }
        return connection.makeJSONCall(DomainService.ForceLockParameter(identifier: item)) { result in
            switch result {
            case .failure(let error):
                completionHandler(error.toPresentableError())
            case .success:
                completionHandler(nil)
            }
        }
    }

    private func performPinAction(withValue value: Bool, onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
                                  completionHandler: @escaping (Error?) -> Void) -> Progress {
        let items = itemIdentifiers.compactMap(DomainService.ItemIdentifier.init)
        guard !items.isEmpty else {
            completionHandler(CommonError.notImplemented.toPresentableError())
            return Progress()
        }

        let mark = {
            self.connection.makeJSONCall(DomainService.MarkParameter(identifiers: items, pinned: value)) { result in
                switch result {
                case .failure(let error):
                    completionHandler(error.toPresentableError())
                case .success:
                    completionHandler(nil)
                }
            }
        }

        if value {
            let group = DispatchGroup()
            // Grab a coordination intent for each file.
            var intents = [NSFileAccessIntent]()
            itemIdentifiers.forEach { ident in
                group.enter()
                manager.getUserVisibleURL(for: ident) { url, error in
                    defer {
                        group.leave()
                    }
                    if let error = error as NSError? {
                        self.logger.error("couldn't get url for item:\(error)")
                        return
                    }
                    guard let url = url else {
                        self.logger.error("couldn't get url for item, no error")
                        return
                    }
                    synchronized(group) {
                        intents.append(NSFileAccessIntent.readingIntent(with: url, options: []))
                    }
                }
            }
            group.wait()
            // Wait until all intents have been gathered.
            var coordinationError: Error? = nil

            let progress = Progress(totalUnitCount: Int64(intents.count + 1))
            group.enter()
            progress.performAsCurrent(withPendingUnitCount: Int64(intents.count)) { () -> Void in
                // Coordinate in the background and notify when done.
                NSFileCoordinator().coordinate(with: intents, queue: OperationQueue()) { innerError in
                    synchronized(group) {
                        coordinationError = innerError
                    }
                    group.leave()
                }
            }
            group.notify(queue: queue, execute: {
                if let error = coordinationError {
                    completionHandler(error.toPresentableError())
                    return
                }
                progress.performAsCurrent(withPendingUnitCount: 1) { () -> Void in
                    _ = mark()
                }
            })

            return progress
        } else {
            return mark()
        }
    }

    private func performEvictFolderAction(onItemsWithIdentifiers itemIdentifiers: [NSFileProviderItemIdentifier],
                                          completionHandler: @escaping (Error?) -> Void) -> Progress {
        guard let item = itemIdentifiers.first else {
            completionHandler(CommonError.parameterError.toPresentableError())
            return Progress()
        }
        // Demonstrate explicit eviction via a menu item. Note that the explicit call
        // differs in behavior from "Remove Download" in Finder:
        // - Finder will attempt to free up as much space as possible
        // - this call will return an error as when it encounters nonevictable items,
        //   with no guarantee about the state of the remaining items
        manager.evictItem(identifier: item, completionHandler: completionHandler)
        return Progress()
    }
}
