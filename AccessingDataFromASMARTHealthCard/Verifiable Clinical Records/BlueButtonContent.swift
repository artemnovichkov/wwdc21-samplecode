/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The content of a button.
*/

import SwiftUI

struct BlueButtonContent: View {
    
    let text: String

    // A rounded, blue, button. For pushing.
    var body: some View {
        Text(text)
            .font(.headline)
            .bold()
            .foregroundColor(Color(uiColor: .secondarySystemGroupedBackground))
            .padding(10)
            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 44)
    }
}
