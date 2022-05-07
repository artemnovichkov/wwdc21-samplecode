/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension for presenting errors from the app delegate.
*/

import AppKit
import FileProvider
import Swifter

extension NSError {
    // Merge values into the user info values from the error. If values to add
    // contains keys that already exist, this method will overwrite the existing values.
    convenience init(_ other: Error, adding valuesToAdd: [String: Any]) {
        let nsError = other as NSError
        var userInfo = nsError.userInfo
        userInfo.merge(valuesToAdd, uniquingKeysWith: { $1 })
        self.init(domain: nsError.domain, code: nsError.code, userInfo: userInfo)
    }
}

extension AppDelegate {
    private class RecoveryAttempter: NSObject {
        private var options = [(title: String, block: (Error) -> Bool)]()

        func option(with title: String, block: @escaping (Error) -> Bool) {
            options.append((title, block))
        }

        var localizedRecoveryOptions: [String] {
            return options.map(\.title)
        }

        override func attemptRecovery(fromError error: Error, optionIndex recoveryOptionIndex: Int) -> Bool {
            let option = options[recoveryOptionIndex]
            return option.block(error)
        }
    }

    @MainActor
    func presentError(_ error: Error) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            do {
                throw error
            } catch NSFileProviderError.providerTranslocated {
                self.window.presentError(NSError(nsError, adding: [
                    NSLocalizedDescriptionKey: "The application cannot be used from this location.",
                    NSLocalizedRecoverySuggestionErrorKey: "Move the application to a different location to use it."
                ]))
                NSApp.terminate(nil)
            } catch NSFileProviderError.olderExtensionVersionRunning {
                let attempter = RecoveryAttempter()
                attempter.option(with: "Show older version") { (error) -> Bool in
                    guard let location = (error as NSError).userInfo[NSFilePathErrorKey] as? String else {
                        return false
                    }
                    NSWorkspace.shared.selectFile(location, inFileViewerRootedAtPath: location)
                    NSApp.terminate(nil)
                    return true
                }
                self.window.presentError(NSError(nsError, adding: [
                    NSLocalizedDescriptionKey: "An older version of the application is currently in use.",
                    NSLocalizedRecoverySuggestionErrorKey: "Please move the older version to the trash before continuing.",
                    NSLocalizedRecoveryOptionsErrorKey: attempter.localizedRecoveryOptions,
                    NSRecoveryAttempterErrorKey: attempter
                ]))
            } catch NSFileProviderError.newerExtensionVersionFound {
                let attempter = RecoveryAttempter()
                attempter.option(with: "Show newer version") { (error) -> Bool in
                    guard let location = (error as NSError).userInfo[NSFilePathErrorKey] as? String else {
                        return false
                    }
                    NSWorkspace.shared.selectFile(location, inFileViewerRootedAtPath: location)
                    NSApp.terminate(nil)
                    return true
                }
                self.window.presentError(NSError(nsError, adding: [
                    NSLocalizedDescriptionKey: "A newer version of the application is already installed.",
                    NSLocalizedRecoverySuggestionErrorKey: "Please use the newer version instead.",
                    NSLocalizedRecoveryOptionsErrorKey: attempter.localizedRecoveryOptions,
                    NSRecoveryAttempterErrorKey: attempter
                ]))
            } catch NSFileProviderError.providerNotFound {
                self.window.presentError(NSError(domain: nsError.domain, code: nsError.code, userInfo: [
                    NSLocalizedDescriptionKey: "The application cannot be used.",
                    NSLocalizedRecoverySuggestionErrorKey: "The contained plugin could not be found."
                ]))
                NSApp.terminate(nil)
            } catch SocketError.bindFailed(let msg) {
                self.window.presentError(NSError(domain: nsError.domain, code: nsError.code, userInfo: [
                    NSLocalizedDescriptionKey: "\(msg)",
                    NSLocalizedRecoverySuggestionErrorKey: "Check that you do not already have an instance of the app running."
                ]))
                NSApp.terminate(nil)
            } catch let error {
                self.window.presentError(error)
            }
        }
    }
}
