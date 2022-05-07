/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The side bar label view.
*/

import SwiftUI

struct SidebarLabel: View {
    var garden: Garden

    var body: some View {
        Label(garden.name, systemImage: "leaf")
    }
}
