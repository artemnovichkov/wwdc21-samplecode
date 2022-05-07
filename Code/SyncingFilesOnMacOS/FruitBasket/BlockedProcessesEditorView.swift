/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view for blocking or unblocking materialization by different processes.
*/

import Common
import SwiftUI

struct BlockedProcessesEditorView: View {
    @State private var newProcessName: String = ""
    @ObservedObject private var blockedProcesses = UserDefaults.sharedContainerDefaults.observableBlockedProcesses

    var body: some View {
        List {
            HStack {
                Button(action: add) {
                    Image(systemName: "plus.app.fill")
                }
                .buttonStyle(PlainButtonStyle())

                TextField("Process name", text: $newProcessName, onCommit: add)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            ForEach(blockedProcesses.value, id: \.self) { name in
                CellWithLabelAndDeleteAction(label: name) {
                    remove(name)
                }
            }
        }
    }

    private func add() {
        guard !newProcessName.isEmpty else { return }
        // If the blocked processes already contains the process name, there is nothing to do.
        guard !blockedProcesses.value.contains(newProcessName) else { return }
        blockedProcesses.value.insert(newProcessName, at: 0)
        newProcessName = ""
    }

    private func remove(_ name: String) {
        guard let idx = blockedProcesses.value.firstIndex(of: name) else { return }
        blockedProcesses.value.remove(at: idx)
    }
}
