/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The garden display mode picker found in the toolbar.
*/

import SwiftUI

struct DisplayModePicker: View {
    @Binding var mode: GardenDetail.ViewMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(GardenDetail.ViewMode.allCases) { viewMode in
                viewMode.label
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

extension GardenDetail.ViewMode {

    var labelContent: (name: String, systemImage: String) {
        switch self {
        case .table:
            return ("Table", "tablecells")
        case .gallery:
            return ("Gallery", "photo")
        }
    }

    var label: some View {
        let content = labelContent
        return Label(content.name, systemImage: content.systemImage)
    }
}
