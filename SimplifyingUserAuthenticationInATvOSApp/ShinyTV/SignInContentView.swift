/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that displays the main sign-in content.
*/

import SwiftUI

/// A view that displays the main sign-in content.
struct SignInContentView: View {
    @EnvironmentObject private var controller: AuthenticationController

    var body: some View {
        VStack(spacing: 48) {
            Text("Shiny TV")
                .font(.system(.largeTitle))
                .bold()

            Button("Sign In") {
                controller.start()
            }
        }
        .font(.system(.headline))
    }
}

struct SignInContentView_Previews: PreviewProvider {
    static var previews: some View {
        SignInContentView().environmentObject(AuthenticationController())
    }
}
