/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that asks the user to sign in.
*/

import Combine
import SwiftUI

/// A view that asks the user to sign in.
struct SignInView: View {
    @StateObject private var controller = AuthenticationController()

    /// A binding that stores an authenticated user.
    var user: Binding<User?>

    private var wantsManualPasswordAuthentication: Binding<Bool> {
        Binding(
            get: { controller.state.wantsManualPasswordAuthentication },
            set: { _ in controller.state.reset() }
        )
    }

    private var authenticationError: Binding<AuthenticationError?> {
        Binding(
            get: { controller.state.error },
            set: { _ in controller.state.reset() }
        )
    }

    var body: some View {
        SignInContentView()
            .sheet(isPresented: wantsManualPasswordAuthentication) {
                PasswordSignInView()
            }
            .alert(item: authenticationError) {
                Alert(
                    title: Text("Sign In Failed"),
                    message: Text($0.localizedDescription),
                    dismissButton: .cancel(Text("OK"))
                )
            }
            .onReceive(controller.userAuthenticatedPublisher) {
                user.wrappedValue = $0
            }
            .environmentObject(controller)
    }
}

private extension AuthenticationController {
    /// A publisher that sends an authenticated user when one exists then completes.
    var userAuthenticatedPublisher: AnyPublisher<User, Never> {
        $state.flatMap { state -> AnyPublisher<User, Never> in
            if let user = state.user {
                return Just(user).eraseToAnyPublisher()
            }
            return Empty<User, Never>(completeImmediately: false).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
