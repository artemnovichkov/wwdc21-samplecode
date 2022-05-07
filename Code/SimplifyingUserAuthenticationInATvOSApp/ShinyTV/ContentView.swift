/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main content view for the application.
*/

import SwiftUI

/// The main content view for Shiny.
struct ContentView: View {
    @State private var user: User?

    var body: some View {
        if let user = user {
            HomeView()
                .environment(\.user, user)
                .environment(\.signOut, SignOutAction(user: $user))
                .transition(.opacity.animation(.linear))
        } else {
            SignInView(user: $user)
                .transition(.opacity.animation(.linear))
        }
    }
}
