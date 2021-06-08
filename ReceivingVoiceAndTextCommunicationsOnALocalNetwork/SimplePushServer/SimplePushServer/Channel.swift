/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Channel` listens for new connections and passes them to the router for management after the user registration is received.
*/

import Foundation
import Combine
import Network
import SimplePushKit

class Channel {
    enum ChannelType: String {
        case notification
        case control
    }
    
    struct PendingSession: Hashable {
        let networkSession: NetworkSession
        var cancellables = Set<AnyCancellable>()
        private let uuid = UUID()
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }
        
        static func == (lhs: PendingSession, rhs: PendingSession) -> Bool {
            lhs.uuid == rhs.uuid
        }
    }
    
    let type: ChannelType
    let port: UInt16
    private let dispatchQueue = DispatchQueue(label: "Channel.dispatchQueue")
    private weak var router: Router?
    private var listener: NWListener?
    private var pendingSessions = Set<PendingSession>()
    private var cancellables = Set<AnyCancellable>()
    private let logger: Logger
    
    var parameters: NWParameters {
        var parameters: NWParameters
        
        let path = Bundle.main.path(forResource: "SimplePushServer", ofType: ".p12")!
        let url = URL(fileURLWithPath: path)
        parameters = NWParameters(tls: ConnectionOptions.TLS.Server(p12: url, passphrase: "apple").options, tcp: ConnectionOptions.TCP.options)
        parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolFramer.Options(definition: LengthPrefixedFramer.definition), at: 0)
        
        return parameters
    }
    
    init(port: UInt16, type: ChannelType, router: Router?) {
        self.port = port
        self.type = type
        self.router = router
        self.logger = Logger(prependString: "Channel \(type.rawValue.capitalized)", subsystem: .general)
    }
    
    public func start() {
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: UInt16(port))!)
            listener?.newConnectionHandler = { [self] connection in
                logger.log("Received new connection")
                setup(connection: connection)
            }
            listener?.start(queue: dispatchQueue)
            
            logger.log("Listening on port \(port)")
        } catch {
            logger.log("Error creating listener \(error)")
        }
    }
    
    public func stop() {
        listener?.cancel()
        listener = nil
    }
    
    private func setup(connection: NWConnection) {
        dispatchQueue.async { [self] in
            let networkSession = RequestResponseSession()
            
            if type == .notification {
                // By default, a RequestResponseSession disconnects when a request fails. This behavior is undesired when the connection
                // comes from within an AppPushProvider because the connection could succeed in the near future. For example, a failed
                // heartbeat in the HeartbeatCoordinator marks the `isSessionResponsive` flag as false rather than tearing down the connection.
                networkSession.disconnectOnFailure = false
            }
            
            var pendingSession = PendingSession(networkSession: networkSession)
            
            // Observe all messages on the connection, ignoring any that aren't a NetworkSession.RequestResponse.
            networkSession.messagePublisher
            .receive(on: dispatchQueue)
            .compactMap { message in
                message as? User
            }
            .sink { [self, weak networkSession] user in
                guard let networkSession = networkSession else {
                    return
                }
                
                logger.log("Received registration for user \(user.deviceName)")
                router?.register(user: user, session: networkSession, type: type)
                pendingSession.cancellables.removeAll()
                pendingSessions.remove(pendingSession)
            }.store(in: &pendingSession.cancellables)
            
            pendingSessions.insert(pendingSession)
            networkSession.connect(connection: connection)
        }
    }
}
