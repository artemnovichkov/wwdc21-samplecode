/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that manages signing in to the application.
*/

import AuthenticationServices
import os.log

/// An object that manages signing in to Shiny.
final class AuthenticationController: NSObject, ASAuthorizationControllerDelegate, ObservableObject {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.example.Shiny", category: "Authentication")

    /// The state of the authentication controller.
    @Published var state = AuthenticationState.ready

    // MARK: - Public

    /// Starts an authentication session using AuthenticationServices.
    func start() {
        state = .authenticating

        let requests = [ASAuthorizationPasswordProvider().createRequest()]

        let controller = ASAuthorizationController(authorizationRequests: requests)
        controller.delegate = self
        controller.customAuthorizationMethods = [.other]

        controller.performRequests()
    }

    /// Signs in using the given email and password.
    func signIn(email: String, password: String) {
        // This project does not use the password value when signing in. Your project
        // should exchange the email and password values with an authentication token
        // that can be stored in the keychain and used for future communication with
        // your back end services.
        let user = User(email: email)
        state = .authenticated(user)
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        logger.log("Completed with authorization: \(authorization)")

        if let credential = authorization.credential as? ASPasswordCredential {
            // Use the `user` and `password` properties to sign in.
            signIn(email: credential.user, password: credential.password)
        }
    }

    func authorizationController(_ controller: ASAuthorizationController, didCompleteWithCustomMethod method: ASAuthorizationCustomMethod) {
        logger.log("Completed with custom method: \(method.rawValue)")

        if method == .other {
            // Show the manual sign-in UI.
            state = .wantsManualPasswordAuthentication
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        logger.error("Failed with error: \(error as NSError)")

        let wrapped = AuthenticationError(error)

        if wrapped.isCancelledError {
            // Allow the app to return to the main sign-in UI.
            state.reset()
            return
        }

        // Show an alert with the error.
        state = .failed(wrapped)
    }
}

/// A value that represents the state of an authentication controller.
enum AuthenticationState {
    /// The authentication controller is ready to begin authentication.
    case ready

    /// The authentication controller is currently performing an authentication operation.
    case authenticating

    /// The user has requested manual password authentication.
    ///
    /// The application should display the manual sign-in UI.
    case wantsManualPasswordAuthentication

    /// Authentication failed and produced an error.
    case failed(AuthenticationError)

    /// Authentication succeeded and produced a user.
    case authenticated(User)

    var wantsManualPasswordAuthentication: Bool {
        switch self {
        case .wantsManualPasswordAuthentication: return true
        default: return false
        }
    }

    var error: AuthenticationError? {
        switch self {
        case .failed(let error): return error
        default: return nil
        }
    }

    var user: User? {
        switch self {
        case .authenticated(let user): return user
        default: return nil
        }
    }

    /// Reset to the `.ready` state.
    mutating func reset() {
        self = .ready
    }
}

/// A value that represents an authentication error.
enum AuthenticationError: LocalizedError, Identifiable {
    struct Identifier: Hashable {
        let domain: String
        let code: Int
    }

    /// The user cancelled authentication.
    case cancelled

    /// Some other error occurred.
    case unknown(Error)

    private var undelying: Error {
        switch self {
            case .cancelled: return ASAuthorizationError(.canceled)
            case let .unknown(error): return error
        }
    }

    var id: Identifier {
        let bridged = undelying as NSError
        return Identifier(domain: bridged.domain, code: bridged.code)
    }

    var errorDescription: String? {
        undelying.localizedDescription
    }

    /// A value that indicates whether this error represents a user cancellation.
    var isCancelledError: Bool {
        switch self {
            case .cancelled: return true
            default: return false
        }
    }

    init(_ error: Error) {
        switch error {
            case ASAuthorizationError.canceled: self = .cancelled
            default: self = .unknown(error)
        }
    }
}
