/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates the presentation of sheets on the root view.
*/

import SwiftUI
import Combine
import SimplePushKit

class RootViewCoordinator: ObservableObject {
    enum PresentedView: Identifiable {
        case settings
        case user(User, TextMessage?)
        
        var id: Int {
            var hasher = Hasher()
            switch self {
            case .settings:
                hasher.combine("settings")
            case .user(let user, _):
                hasher.combine("user")
                hasher.combine(user.id)
            }
            return hasher.finalize()
        }
    }
    
    @Published var presentedView: PresentedView?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        CallManager.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [self] state in
                switch state {
                case .connected(let user):
                    presentedView = .user(user, nil)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Present a user's messaging view when receiving a text message.
        MessagingManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [self] message in
                let user = message.routing.sender
                presentedView = PresentedView.user(user, message)
            }
            .store(in: &cancellables)
    }
}

extension RootViewCoordinator: Presenter {
    func dismiss() {
        presentedView = nil
    }
}
