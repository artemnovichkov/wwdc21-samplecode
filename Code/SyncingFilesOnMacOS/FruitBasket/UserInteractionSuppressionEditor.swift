/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view for adding and removing suppression identifiers.
*/

import Common
import SwiftUI
import FileProvider

struct UserInteractionSuppressionEditor: View {
    @State private var newSuppressionIdentifier: String = ""
    @ObservedObject private var suppressedIdentifiers =
        UserDefaults.sharedContainerDefaults.observableUserInteractionSuppressedIdentifiers

    let domainIdentifier: NSFileProviderDomainIdentifier
    let domainDisplayName: String

    init(domainIdentifier: NSFileProviderDomainIdentifier,
         domainDisplayName: String) {
        self.domainIdentifier = domainIdentifier
        self.domainDisplayName = domainDisplayName
    }

    var body: some View {
        List {
            HStack {
                Button(action: add) {
                    Image(systemName: "plus.app.fill")
                }
                .buttonStyle(PlainButtonStyle())

                TextField("SuppressionIdentifier", text: $newSuppressionIdentifier, onCommit: add)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            ForEach(suppressedIdentifiers.value[domainIdentifier.rawValue] ?? [], id: \.self) { name in
                CellWithLabelAndDeleteAction(label: name) {
                    remove(name)
                }
            }
        }
    }

    private func add() {
        suppressedIdentifiers.value[domainIdentifier.rawValue]?.insert(newSuppressionIdentifier, at: 0)
        // Clear the new suppression identifier to update the UI.
        newSuppressionIdentifier = ""
    }

    private func remove(_ name: String) {
        suppressedIdentifiers.value[domainIdentifier.rawValue]?.removeAll { $0 == name }
    }
}
