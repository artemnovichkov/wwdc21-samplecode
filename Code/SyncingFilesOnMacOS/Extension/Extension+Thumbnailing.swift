/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adds thumbnails to the extension.
*/

import os.log
import Common
import FileProvider

extension Extension: NSFileProviderThumbnailing {
    public func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize,
                                perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void,
                                completionHandler: @escaping (Error?) -> Void) -> Progress {
        logger.debug("🧩 fetchThumbnails(for \(itemIdentifiers.map({ $0.rawValue })))")
        let group = DispatchGroup()

        for identifier in itemIdentifiers {
            group.enter()
            let param = DomainService.FetchThumbnailParameter(identifier: DomainService.ItemIdentifier(identifier), requestedRevision: nil)
            connection.makeJSONCallWithReturn(param) { result in
                switch result {
                case .failure(let error):
                    perThumbnailCompletionHandler(identifier, nil, error.toPresentableError())
                    group.leave()
                case .success(let resp):
                    perThumbnailCompletionHandler(identifier, resp.data, nil)
                    group.leave()
                }
            }
        }

        // Thumbnails for all items have been fetched; call the completion handler.
        group.notify(queue: queue) {
            completionHandler(nil)
        }

        let progress = Progress()
        progress.cancellationHandler = { completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)) }
        return progress
    }
}
