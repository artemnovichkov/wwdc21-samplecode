/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell view that displays a label and has a delete action.
*/

import SwiftUI

// This cell is configurable so that it can be used in multiple contexts.
struct CellWithLabelAndDeleteAction: View {
    let label: String
    let deleteAction: () -> Void

    var body: some View {
        HStack {
            Button(action: deleteAction) {
                Image(systemName: "x.circle.fill")
            }
            .buttonStyle(PlainButtonStyle())

            Text(label)
        }
    }
}
