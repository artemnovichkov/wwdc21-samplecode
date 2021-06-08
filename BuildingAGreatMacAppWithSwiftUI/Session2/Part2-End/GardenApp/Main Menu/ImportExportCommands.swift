/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The import and export command group.
*/

import SwiftUI

struct ImportExportCommands: Commands {
    var store: Store
    @State private var isShowingExportDialog = false

    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Section {
                Button("Export…") {
                    isShowingExportDialog = true
                }
                .fileExporter(
                    isPresented: $isShowingExportDialog, document: store,
                    contentType: Store.readableContentTypes.first!) { result in
                }
            }
        }
    }
}
