/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adds the domain version and shared user defaults to the extension.
*/

import Common
import FileProvider

// Sets the domain version and user info based on shared user defaults.
extension Extension: NSFileProviderDomainState {
    public var domainVersion: NSFileProviderDomainVersion {
        UserDefaults.sharedContainerDefaults.domainVersion(for: self.domain.identifier)
    }
    public var userInfo: [AnyHashable: Any] {
        let shouldWarnOnImportingToFolder: Bool =
            UserDefaults.sharedContainerDefaults.featureFlag(for: self.domain.identifier, featureFlag: FeatureFlags.shouldWarnOnImportingToFolder)
        let pinnedFeatureEnabled: Bool =
            UserDefaults.sharedContainerDefaults.featureFlag(for: self.domain.identifier, featureFlag: FeatureFlags.pinnedFeatureFlag)

        return ["shouldWarnOnImportingToFolder": shouldWarnOnImportingToFolder, "pinnedFeatureEnabled": pinnedFeatureEnabled]
    }
}
