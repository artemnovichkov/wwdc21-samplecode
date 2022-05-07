/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension for sharing values used through the app group suite.
*/

import Foundation
import FileProvider

internal let defaultValues: [String: Any] = ["responseDelay": 0.0,
                                             "errorRate": 0.0,
                                             "batchSize": 200,
                                             "accountQuota": 0,
                                             "ignoreAuthentication": true,
                                             "skipThumbnailUpload": false,
                                             "contentStoredInline": false,
                                             "ignoreContentVersionOnDeletion": false,
                                             "trashDisabled": false,
                                             "syncChildrenBeforeParentMove": true,
                                             "uploadNewFilesInChunks": true]

public struct FeatureFlag {
    public let name: String
    public let defaultIfNotPresent: Bool

    public init(name: String, defaultIfNotPresent: Bool) {
        self.name = name
        self.defaultIfNotPresent = defaultIfNotPresent
    }
}

public enum FeatureFlags {
    public static let pinnedFeatureFlag = FeatureFlag(name: "pinnedFeatureEnabled", defaultIfNotPresent: true)
    public static let shouldWarnOnImportingToFolder = FeatureFlag(name: "shouldWarnOnImportingToFolder", defaultIfNotPresent: true)
}

public extension UserDefaults {
    static var sharedContainerDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.FruitBasket") else {
            fatalError("could not access shared user defaults")
        }
        defaults.register(defaults: defaultValues)
        return defaults
    }

    var ignoreLoggingForEndpoints: [String] {
        stringArray(forKey: "ignoreLoggingForEndpoints") ?? [String]()
    }

    var responseDelay: TimeInterval {
        let responseDelay = float(forKey: "responseDelay")

        return TimeInterval(responseDelay / 1000.0)
    }

    var errorRate: Float {
        return float(forKey: "errorRate")
    }

    var ignoreAuthentication: Bool {
        return bool(forKey: "ignoreAuthentication")
    }

    var trashDisabled: Bool {
        return bool(forKey: "trashDisabled")
    }

    var ignoreContentVersionOnDeletion: Bool {
        return bool(forKey: "ignoreContentVersionOnDeletion")
    }

    var contentStoredInline: Bool {
        return bool(forKey: "contentStoredInline")
    }

    var syncChildrenBeforeParentMove: Bool {
        return bool(forKey: "syncChildrenBeforeParentMove")
    }

    var uploadNewFilesInChunks: Bool {
        return bool(forKey: "uploadNewFilesInChunks")
    }

    // Map of domainIdentifier -> array of suppressed identifiers.
    @objc dynamic var userInteractionSuppressedIdentifiers: [String: [String]] {
        get {
            dictionary(forKey: "userInteractionSuppressedIdentifiers") as? [String: [String]] ?? [:]
        }
        set {
            setValue(newValue, forKey: "userInteractionSuppressedIdentifiers")
        }
    }

    var observableUserInteractionSuppressedIdentifiers: ObservableProperty<[String: [String]]> {
        .init(.sharedContainerDefaults, keyPath: \.userInteractionSuppressedIdentifiers, defaultValue: [:])
    }

    @objc dynamic var blockedProcesses: [String] {
        get { stringArray(forKey: "blockedProcesses") ?? [] }
        set { setValue(newValue, forKey: "blockedProcesses") }
    }

    var observableBlockedProcesses: ObservableProperty<[String]> {
        .init(.sharedContainerDefaults, keyPath: \.blockedProcesses, defaultValue: [])
    }

    enum ErrorType: Int {
        case server
        case plugin
        case both
    }

    var errorType: ErrorType {
        return ErrorType(rawValue: integer(forKey: "errorType")) ?? .server
    }

    var outgoingBandwidth: Int? {
        let key = "outgoingBandwidth"
        if object(forKey: key) == nil {
            return nil
        }
        return integer(forKey: key)
    }

    var batchSize: Int {
        let size = integer(forKey: "batchSize")
        if size == 0 {
            return 200
        }
        return max(size, 1)
    }

    var hostname: String {
        guard let hostname = string(forKey: "hostname") else {
            return "localhost"
        }
        return hostname
    }

    struct Holder {
        public static var quotaOverride: Int64? = nil
    }

    var accountQuota: Int64? {
        get {
            let override = Holder.quotaOverride
            if let override = override {
                return override
            }

            let quota = Int64(integer(forKey: "accountQuota")) * 1_048_576 // Convert in bytes.
            if quota > 0 {
                return quota
            }
            return nil
        }
        set(newValue) {
            Holder.quotaOverride = newValue
        }
    }

    func secret(for domainIdentifier: NSFileProviderDomainIdentifier) -> String? {
        guard let allSecrets = dictionary(forKey: "secrets") else { return nil }
        return allSecrets[domainIdentifier.rawValue] as? String
    }

    func set(secret: String?, for domainIdentifier: NSFileProviderDomainIdentifier) {
        var allSecrets = dictionary(forKey: "secrets") ?? [String: Any]()
        allSecrets[domainIdentifier.rawValue] = secret
        set(allSecrets, forKey: "secrets")
    }

    private func _domainVersion(for domainIdentifier: NSFileProviderDomainIdentifier) -> Data? {
        guard let allDomainVersions = dictionary(forKey: "domainVersions") else { return nil }
        guard let version = allDomainVersions[domainIdentifier.rawValue] as? Data else { return nil }

        return version
    }

    func domainVersion(for domainIdentifier: NSFileProviderDomainIdentifier) -> NSFileProviderDomainVersion {
        if let data = self._domainVersion(for: domainIdentifier) {
            if let version = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSFileProviderDomainVersion.self, from: data) {
                return version
            }
        }

        return NSFileProviderDomainVersion()
    }

    func bumpDomainVersion(for domainIdentifier: NSFileProviderDomainIdentifier) {
        let version = self.domainVersion(for: domainIdentifier)

        var allDomainVersion = dictionary(forKey: "domainVersions") ?? [String: Data]()
        allDomainVersion[domainIdentifier.rawValue] = try? NSKeyedArchiver.archivedData(withRootObject: version.next(), requiringSecureCoding: true)
        set(allDomainVersion, forKey: "domainVersions")
    }

    func featureFlag(for domainIdentifier: NSFileProviderDomainIdentifier,
                     featureFlag: FeatureFlag) -> Bool {
        guard let allFeatureFlags = dictionary(forKey: "featureFlag") else {
            return featureFlag.defaultIfNotPresent
        }
        guard let domainFeatureFlags = allFeatureFlags[domainIdentifier.rawValue] as? [String: Bool] else {
            return featureFlag.defaultIfNotPresent
        }
        return domainFeatureFlags[featureFlag.name] ?? featureFlag.defaultIfNotPresent
    }

    func setFeatureFlag(for domainIdentifier: NSFileProviderDomainIdentifier,
                        featureFlag: FeatureFlag,
                        value: Bool) {
        var featureFlagDictionary: [String: [String: Bool]] =
            dictionary(forKey: "featureFlag") as? [String: [String: Bool]] ?? [String: [String: Bool]]()
        if featureFlagDictionary[domainIdentifier.rawValue] == nil {
            featureFlagDictionary[domainIdentifier.rawValue] = [:]
        }
        guard var featureFlagsForDomain = featureFlagDictionary[domainIdentifier.rawValue] else {
            fatalError("Unexpected state, featureFlagsForDomain should be populated")
        }
        featureFlagsForDomain[featureFlag.name] = value
        featureFlagDictionary[domainIdentifier.rawValue] = featureFlagsForDomain
        set(featureFlagDictionary, forKey: "featureFlag")
        self.bumpDomainVersion(for: domainIdentifier)
    }

    func toggleFeatureFlag(for domainIdentifier: NSFileProviderDomainIdentifier,
                           featureFlag: FeatureFlag) {
        let existingFeatureFlag = self.featureFlag(for: domainIdentifier, featureFlag: featureFlag)
        self.setFeatureFlag(for: domainIdentifier, featureFlag: featureFlag, value: !existingFeatureFlag)
    }
}
