/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An entry in the domain list that is displayed in the main window of the app.
*/

import Cocoa
import FileProvider
import Common

class DomainEntry: NSObject, Identifiable {
    var id: String {
        return domain.identifier.rawValue
    }
    let account: AccountService.Account?
    var domain: NSFileProviderDomain
    @objc dynamic var uploadProgress: Progress?
    @objc dynamic var downloadProgress: Progress?
    @objc dynamic let displayName: String
    @objc dynamic var backingRoot: String { "#\(account?.rootItem.id.id ?? 0)" }

    @objc class var keyPathsForValuesAffectingStatus: Set<String> {
        Set(["uploadProgress.fractionCompleted", "downloadProgress.fractionCompleted",
             "uploadProgress.fileTotalCount", "downloadProgress.fileTotalCount",
             "uploadProgress.fileCompletedCount", "downloadProgress.fileCompletedCount",
             "uploadProgress.totalUnitCount", "downloadProgress.totalUnitCount"])
    }
    @objc dynamic var status: NSAttributedString {
        let ret: NSMutableAttributedString
        if account == nil {
            return NSMutableAttributedString(string: "Belongs to other process", attributes: [.foregroundColor: NSColor.gray])
        }
        if !domain.userEnabled {
            ret = NSMutableAttributedString(string: "Disabled", attributes: [.foregroundColor: NSColor.red])
        } else {
            ret = NSMutableAttributedString(string: "Enabled", attributes: nil)
        }

        if domain.isDisconnected {
            ret.append(NSAttributedString(string: ", Disconnected", attributes: nil))
        }
        if domain.isHidden {
            ret.append(NSAttributedString(string: ", Hidden", attributes: nil))
        }
        if !UserDefaults.sharedContainerDefaults.ignoreAuthentication,
            self.authenticated {
            ret.append(NSAttributedString(string: ", Authenticated", attributes: nil))
        }
        if self.offline {
            ret.append(NSAttributedString(string: ", Offline", attributes: nil))
        }
        formatProgress(ret, self.uploadProgress, ("arrow.up.doc", "upload"))
        formatProgress(ret, self.downloadProgress, ("arrow.down.doc", "download"))
        return ret
    }
    @objc dynamic var connected: Bool {
        return !domain.isDisconnected
    }
    @objc dynamic var hidden: Bool {
        return domain.isHidden
    }
    @objc dynamic var authenticated: Bool {
        guard let secret = account?.secret else {
            return false
        }
        return UserDefaults.sharedContainerDefaults.secret(for: domain.identifier) == secret
    }
    @objc dynamic var shouldWarnOnImportingToFolder: Bool {
        return UserDefaults.sharedContainerDefaults.featureFlag(for: domain.identifier, featureFlag: FeatureFlags.shouldWarnOnImportingToFolder)
    }
    @objc dynamic var pinnedFeatureEnabled: Bool {
        return UserDefaults.sharedContainerDefaults.featureFlag(for: domain.identifier, featureFlag: FeatureFlags.pinnedFeatureFlag)
    }
    @objc dynamic var offline: Bool {
        guard let flags = account?.flags else {
            return false
        }
        return flags.contains(.Offline)
    }

    init(domain: NSFileProviderDomain, account: AccountService.Account?, uploadProgress: Progress?, downloadProgress: Progress?) {
        self.displayName = domain.displayName
        self.domain = domain
        self.account = account
        self.uploadProgress = uploadProgress
        self.downloadProgress = downloadProgress
    }

    // Only consider identifiers for equality.
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? DomainEntry else { return false }
        return other.id == id
    }

    private func formatProgress(_ ret: NSMutableAttributedString, _ progress: Progress?, _ direction: (name: String, desc: String)) {
        guard let progress = progress else { return }

        if !progress.isFinished {
            ret.append(NSAttributedString(string: " ", attributes: nil))
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = NSImage(systemSymbolName: direction.name, accessibilityDescription: direction.desc)
            ret.append(NSAttributedString(attachment: imageAttachment))

            let countFormat = ByteCountFormatter()
            countFormat.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            countFormat.countStyle = .file
            countFormat.allowsNonnumericFormatting = false
            let completed = countFormat.string(fromByteCount: progress.completedUnitCount)
            let total = countFormat.string(fromByteCount: progress.totalUnitCount)
            var completion = String(format: " %@ / %@ %.2f%%", completed, total, progress.fractionCompleted * 100)
            if let total = progress.fileTotalCount, let completed = progress.fileCompletedCount {
                completion.append("  (\(completed) / \(total) files)")
            }

            ret.append(NSAttributedString(string: completion, attributes: nil))
        }
    }
}
