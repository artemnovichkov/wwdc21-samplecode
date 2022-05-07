/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A component used by the server to provide a local cloud files server.
*/

import Foundation
import Swifter
import os.log
import Common

public class BackendDispatch: BackendCallRegistration {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "dispatch")

    var server = HttpServer()
    public let port: in_port_t
    let accountBackend: AccountBackend

    public init(port: in_port_t? = nil, name: String, accountBackend: AccountBackend) throws {
        self.port = port ?? defaultPort
        self.accountBackend = accountBackend

        AccountBackend.registerCalls(self)
        DomainBackend.registerCalls(self)

        server.notFoundHandler = { [weak self] request in
            if let self = self {
                self.logger.error("⛔️ \(request.path): unimplemented")
            }
            return CommonError.notImplemented.asHTTPResponse(JSONEncoder())
        }
        do {
            try server.start(self.port, forceIPv4: false, priority: .default)
        } catch {
            server.stop()
            throw error
        }
        publishBonjour(name)
    }

    var netService: NetService? = nil
    func publishBonjour(_ name: String) {
        netService = NetService(domain: "local.", type: "_fruitbasket._tcp.", name: "\(name) on \(ProcessInfo().hostName)", port: Int32(port))
        netService?.publish()
    }

    public func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType, Data) throws -> (ReturnType)) {
        setDispatchForMethodRoute(ParameterType.method, ParameterType.endpoint, createBackendDispatch(backendCall))
    }

    public func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType) throws -> (ReturnType)) {
        setDispatchForMethodRoute(ParameterType.method, ParameterType.endpoint, createBackendDispatch(backendCall))
    }

    public func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType) throws -> (ReturnType, Data)) {
        setDispatchForMethodRoute(ParameterType.method, ParameterType.endpoint, createBackendDispatch(backendCall))
    }

    internal var alreadyRegistered = Set<String>()
    internal func setDispatchForMethodRoute(_ method: JSONMethod, _ endpoint: String, _ dispatch: @escaping ((HttpRequest) -> HttpResponse)) {
        assert(!alreadyRegistered.contains(endpoint), "endpoint '\(endpoint)' registered twice")
        switch method {
        case .POST:
            server.POST[endpoint] = dispatch
        case .DELETE:
            server.DELETE[endpoint] = dispatch
        case .GET:
            server.GET[endpoint] = dispatch
        }
        alreadyRegistered.insert(endpoint)
    }

    public func stop() {
        server.stop()
    }

    var backends = [String: DomainBackend]()

    public subscript(identifier: String) -> DomainBackend? {
        set {
            synchronized(self) {
                backends[identifier] = newValue
            }
        }
        get {
            synchronized(self) {
                return backends[identifier]
            }
        }
    }

    public func removeBackends(except identifiers: [String]) {
        synchronized(self) {
            let toRemove = backends.keys.filter { !identifiers.contains($0) }
            toRemove.forEach { ident in
                backends.removeValue(forKey: ident)
            }
        }
    }

    func getBackend<Backend: DispatchBackend>(_ identifier: String) -> Backend? {
        if Backend.self == AccountBackend.self {
            return accountBackend as? Backend
        }
        if Backend.self == DomainBackend.self {
            return backends[identifier] as? Backend
        }
        return nil
    }

    internal func parseArgumentsAndPayload(from request: HttpRequest,
                                           backend: DispatchBackend) throws -> (arguments: String, argumentData: Data, payload: Data) {
        let apiArgData: Data
        let apiArg: String
        let dataPayload: Data
        guard let param = request.queryParams.first else {
            logger.error("❌ \(backend.displayName)\(request.path): malformed arguments: no query string for GET request")
            throw CommonError.parameterError
        }
        guard param.0 == "arguments",
              let args = param.1.removingPercentEncoding else {
                  logger.error("❌ \(backend.displayName)\(request.path): malformed arguments: bad query string for get request \(String(describing: param))")
            throw CommonError.parameterError
        }
        apiArg = args
        apiArgData = args.utf8Data
        dataPayload = Data(request.body)
        return (apiArg, apiArgData, dataPayload)
    }

    internal func withRequest<ParameterType: Decodable, ReturnType: Encodable, Backend: DispatchBackend>(
        _ request: HttpRequest, _ block: (ParameterType, Backend, Data) throws -> (ReturnType, Data?)) -> HttpResponse {
        guard let domainIdentifier = request.headers["x-domain"] else {
            logger.error("⛔️ \(request.path): no domain specified")
            return CommonError.parameterError.asHTTPResponse(JSONEncoder())
        }
        guard let backend: Backend = synchronized(self, { getBackend(domainIdentifier) })  else {
            logger.error("⛔️ \(request.path): unknown domain specified: \(domainIdentifier)")
            return CommonError.domainNotFound.asHTTPResponse(JSONEncoder())
        }

        do {
            try backend.checkForDomainApproval(request.headers, request.path)
        } catch let error as CommonError {
            return error.asHTTPResponse(backend.encoder)
        } catch _ {
            fatalError()
        }

        let apiArgData: Data
        let apiArg: String
        let dataPayload: Data
        do {
            (apiArg, apiArgData, dataPayload) = try parseArgumentsAndPayload(from: request, backend: backend)
        } catch let error as CommonError {
            return error.asHTTPResponse(backend.encoder)
        } catch {
            fatalError()
        }

        let defaults = UserDefaults.sharedContainerDefaults
        let param: ParameterType
        do {
            param = try backend.decoder.decode(ParameterType.self, from: apiArgData)
        } catch let error as NSError {
            logger.error("❌ \(backend.displayName)\(request.path): malformed arguments \(error); arguments were \"\(apiArg)\"")
            return CommonError.parameterError.asHTTPResponse(backend.encoder)
        }
        if !defaults.ignoreLoggingForEndpoints.contains(request.path) {
            logger.debug("⭕️ \(backend.displayName)\(request.path): \(String(describing: param)) + \(dataPayload.count) bytes")
        }
        Thread.sleep(forTimeInterval: defaults.responseDelay)
        if Float.random(in: 0..<100) < defaults.errorRate {
            let serverError: Bool
            switch defaults.errorType {
            case .server:
                serverError = true
            case .plugin:
                serverError = false
            case .both:
                serverError = Bool.random()
            }

            if serverError {
                logger.error("🌀 \(backend.displayName)\(request.path): simulated error")
                return CommonError.internalError.asHTTPResponse(backend.encoder)
            } else {
                logger.error("🐒 \(backend.displayName)\(request.path): simulated error: requesting client crash")
                return CommonError.clientCrashingError.asHTTPResponse(backend.encoder)
            }
        }
        let ret: (ReturnType, Data?)
        do {
            ret = try backend.queue.sync {
                try block(param, backend, dataPayload)
            }
        } catch let error as CommonError {
            logger.error("❌ \(backend.displayName)\(request.path): \(String(describing: error.errorDescription))")
            return error.asHTTPResponse(backend.encoder)
        } catch let error as NSError {
            logger.error("❌ \(backend.displayName)\(request.path): unknown error \(error)")
            return .internalServerError
        }
        if !defaults.ignoreLoggingForEndpoints.contains(request.path) {
            if let data = ret.1 {
                logger.debug("✅ \(backend.displayName)\(request.path): \(String(describing: ret.0)) + \(data.count) bytes")
            } else {
                logger.debug("✅ \(backend.displayName)\(request.path): \(String(describing: ret.0))")
            }
        }
        guard let json = try? backend.encoder.encode(ret.0) else { return .internalServerError }

        // To avoid reusing connections, close the connection after every request.
        if let data = ret.1 {
            let jsonString = json.base64EncodedString()
            return .raw(200, "OK", ["API-Response": jsonString, "Content-Length": "\(data.count)", "Connection": "Close"], throttlingWriter(data))
        } else {
            return .raw(200, "OK", ["Connection": "Close"]) { responseWriter in
                try responseWriter.write(json)
            }
        }
    }

    internal func throttlingWriter(_ data: Data) -> (HttpResponseBodyWriter) throws -> Void {
        return { responseWriter in
            do {
                // If outgoingBandwidth is explicitly set to 0, stall the download until the value changes.
                while UserDefaults.sharedContainerDefaults.outgoingBandwidth == 0 {
                    Thread.sleep(forTimeInterval: 5)
                    self.logger.error("Throttling server response, outgoingBandwidth == 0")
                }

                let packetSize = 1024
                var amountWritten = 0
                var progressString = ""
                while amountWritten < data.count {
                    // Calculate the bandwidth every iteration, so that user modifications
                    // during the server response take effect.
                    let outgoingBandwidthOptional = UserDefaults.sharedContainerDefaults.outgoingBandwidth
                    // If outgoing bandwidth is not set, or it is 0, write the remainder of the file.
                    guard let outgoingBandwidth = outgoingBandwidthOptional,
                          outgoingBandwidth > 0 else {
                        let subdata = data.subdata(in: amountWritten..<data.count)
                        try responseWriter.write(subdata)
                        self.logger.debug("Sent remainder of data early, outgoing bandwidth was nil or <= 0")
                        return
                    }
                    let bandwidth = max(outgoingBandwidth, 1) * 1024
                    let timePerPacket: TimeInterval = TimeInterval(packetSize) / TimeInterval(bandwidth)

                    let startTime = Date.timeIntervalSinceReferenceDate
                    let endRange = min(amountWritten + packetSize, data.count)
                    let subdata = data.subdata(in: amountWritten..<endRange)
                    try responseWriter.write(subdata)
                    amountWritten = endRange
                    let endTime = Date.timeIntervalSinceReferenceDate
                    let newProgressString = "\(Int((Double(amountWritten) / Double(data.count)) * 10) * 10)% sent"
                    if progressString != newProgressString {
                        progressString = newProgressString
                        self.logger.debug("\(progressString)")
                    }
                    let sleepTime = timePerPacket - (endTime - startTime)
                    if sleepTime > 0 {
                        Thread.sleep(forTimeInterval: sleepTime)
                    }
                }
            } catch let error as NSError {
                self.logger.error("Error sending message with throttlingWriter, error = \(error)")
                throw error
            }
        }
    }

    internal func createBackendDispatch<ParameterType: Decodable, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backing: @escaping (Backend) -> (ParameterType, Data) throws -> (ReturnType)) -> ((HttpRequest) -> HttpResponse) {
        return { request -> HttpResponse in
            return self.withRequest(request) { (param: ParameterType, backend, partData) -> (ReturnType, Data?) in
                return (try backing(backend)(param, partData), nil)
            }
        }
    }

    internal func createBackendDispatch<ParameterType: Decodable, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backing: @escaping (Backend) -> (ParameterType) throws -> (ReturnType)) -> ((HttpRequest) -> HttpResponse) {
        return { request -> HttpResponse in
            self.withRequest(request) { param, backend, _ in
                (try backing(backend)(param), nil)
            }
        }
    }

    internal func createBackendDispatch<ParameterType: Decodable, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backing: @escaping (Backend) -> (ParameterType) throws -> (ReturnType, Data)) -> ((HttpRequest) -> HttpResponse) {
        return { request -> HttpResponse in
            self.withRequest(request) { param, backend, _ in
                try backing(backend)(param)
            }
        }
    }
}
