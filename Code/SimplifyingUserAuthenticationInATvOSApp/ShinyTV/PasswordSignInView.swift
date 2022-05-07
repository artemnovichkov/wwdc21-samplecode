/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that asks the user to sign in using an email and a password.
*/

import SwiftUI

/// A view that asks the user to sign in using an email and a password.
struct PasswordSignInView: View {
    @EnvironmentObject private var controller: AuthenticationController
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 48) {
            Text("Shiny TV")
                .font(.system(.largeTitle))
                .bold()

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .frame(width: 800)

                SecureField("Password", text: $password)
                    .frame(width: 800)
            }

            Button("Sign In") {
                controller.signIn(email: email, password: password)
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
        .font(.system(.headline))
    }
}

struct PasswordSignInView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordSignInView().environmentObject(AuthenticationController())
    }
}
