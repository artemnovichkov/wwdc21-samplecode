/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main entry point of the app.
*/

import SwiftUI
import SimplePushKit

@main
struct SimplePushApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject private var rootViewCoordinator = RootViewCoordinator()
    @State private var userViewModels = [UUID: UserViewModel]()
    
    var body: some Scene {
        WindowGroup {
            DirectoryView()
            .sheet(item: $rootViewCoordinator.presentedView) { presentedView in
                 view(for: presentedView)
            }
            .environmentObject(rootViewCoordinator)
        }
    }
    
    @ViewBuilder func view(for presentedView: RootViewCoordinator.PresentedView) -> some View {
        switch presentedView {
        case .settings:
            SettingsView(presenter: rootViewCoordinator)
        case .user(let user, let message):
            userView(user: user, message: message)
        }
    }
    
    private func userView(user: User, message: TextMessage?) -> UserView {
        let userViewModel = userViewModels.get(user.id, insert: UserViewModel(user: user))
        
        if let message = message {
            userViewModel.presentedView = .messaging(user, message)
        }
        
        return UserView(viewModel: userViewModel, presenter: rootViewCoordinator)
    }
}
