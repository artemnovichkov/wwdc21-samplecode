/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension the provides a mapping from common errors to Objective-C errors.
*/

import Common
import FileProvider

extension Error {
    func toPresentableError() -> NSError {
        guard let commonError = self as? CommonError else {
            let error = self as NSError
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                return NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
            case (NSURLErrorDomain, _):
                return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.serverUnreachable.rawValue, userInfo: nil)
            case (NSCocoaErrorDomain, NSUserCancelledError):
                return error
            default:
                return NSError(domain: NSCocoaErrorDomain, code: NSXPCConnectionReplyInvalid, userInfo: nil)
            }
        }

        switch commonError {
        case .itemExists(let entry):
            return NSError.fileProviderErrorForCollision(with: Item(entry))
        case .itemNotFound(let identifier):
            return NSError.fileProviderErrorForNonExistentItem(withIdentifier: NSFileProviderItemIdentifier(identifier))
        case .deletionRejected(let entry):
            return NSError.fileProviderErrorForRejectedDeletion(of: Item(entry))
        case .tokenExpired:
            return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.syncAnchorExpired.rawValue, userInfo: nil)
        case .timedOut:
            return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.serverUnreachable.rawValue, userInfo: nil)
        case .notImplemented:
            return NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo: nil)
        case .clientCrashingError:
            exit(0) // The server requested a crash.
        case .simulatedError(let domain, let code, let localizedDescription):
            var userInfo: [String: Any]?
            if let localizedDescription = localizedDescription {
                userInfo = [NSLocalizedDescriptionKey: localizedDescription]
            }
            return NSError(domain: domain, code: code, userInfo: userInfo)
        case .authRequired:
            return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.notAuthenticated.rawValue, userInfo: nil)
        case .insufficientQuota:
            return NSError(domain: NSFileProviderErrorDomain, code: NSFileProviderError.insufficientQuota.rawValue, userInfo: nil)
        default:
            return NSError(domain: NSCocoaErrorDomain, code: NSXPCConnectionReplyInvalid, userInfo: [NSUnderlyingErrorKey: commonError])
        }
    }
}
