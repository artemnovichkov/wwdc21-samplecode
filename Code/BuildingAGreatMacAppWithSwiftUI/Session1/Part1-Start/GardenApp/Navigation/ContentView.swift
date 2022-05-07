/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main content view for this sample.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello World!")
            .padding()
    }
}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Store())
    }
}
