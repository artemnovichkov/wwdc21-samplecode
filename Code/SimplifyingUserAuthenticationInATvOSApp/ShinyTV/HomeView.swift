/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main content view when a user is signed in.
*/

import SwiftUI

/// The main content view when a user is signed in.
struct HomeView: View {
    @Environment(\.user) private var user
    @Environment(\.signOut) private var signOut

    var body: some View {
        NavigationView {
            Image("ShinyImage")
                .resizable()
                .shadow(radius: 12, y: 12)
                .border(Color.white, width: 24)
                .padding()
                .navigationBarItems(trailing: signOutButton)
                .navigationTitle("Welcome, \(user.email)!")
        }
    }

    private var signOutButton: some View {
        Button("Sign Out") { signOut() }
            .font(.system(.headline))
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
