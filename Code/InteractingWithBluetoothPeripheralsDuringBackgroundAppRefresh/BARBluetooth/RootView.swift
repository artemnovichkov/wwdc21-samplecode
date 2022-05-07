/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view of the iOS app.
*/

import SwiftUI

/// A view that displays the device's current characteristic value.
struct RootView: View {
    
    private var value: Int = getCurrentValue()
    
    var body: some View {
        Text("\(value)℃")
            .font(.title.bold())
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
