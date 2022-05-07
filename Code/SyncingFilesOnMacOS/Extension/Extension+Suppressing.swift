/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adds interaction suppression to the extension.
*/

import os.log
import FileProvider

extension Extension: NSFileProviderUserInteractionSuppressing {
    public func setInteractionSuppressed(_ suppression: Bool, forIdentifier suppressionIdentifier: String) {
        self.logger.info("Received call to set suppression \(suppression) for identifier \(suppressionIdentifier) in domain \(String(describing: self.domain.identifier))")
        // Update user defaults to either add or remove the specified suppression identifier.
        var current = UserDefaults.sharedContainerDefaults.userInteractionSuppressedIdentifiers
        var currentDomain = current[domain.identifier.rawValue] ?? []
        if suppression {
            currentDomain.append(suppressionIdentifier)
        } else {
            currentDomain.removeAll { $0 == suppressionIdentifier }
        }
        current[domain.identifier.rawValue] = currentDomain
        UserDefaults.sharedContainerDefaults.userInteractionSuppressedIdentifiers = current
    }

    public func isInteractionSuppressed(forIdentifier suppressionIdentifier: String) -> Bool {
        self.logger.info("Received call to query suppression for identifier \(suppressionIdentifier) in domain \(String(describing: self.domain.identifier))")
        let current = UserDefaults.sharedContainerDefaults.userInteractionSuppressedIdentifiers
        let currentDomain = current[domain.identifier.rawValue]
        return currentDomain?.contains(suppressionIdentifier) ?? false
    }
}
