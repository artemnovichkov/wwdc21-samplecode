/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The HTTP client for making requests to the (local) cloud file server.
*/

import Foundation
import CFNetwork
import Common
import os.log
import FileProvider

public struct DomainConnection {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "domain-connection")
    let domainIdentifier: String
    let port: in_port_t
    let responseQueue = DispatchQueue(label: "connection response queue")
    let session: URLSession
    let secret: String
    let displayName: String
    let hostname: String

    public static func accountConnection(hostname: String, port: in_port_t) -> DomainConnection {
        return DomainConnection(domainIdentifier: "accounts", secret: nil, hostname: UserDefaults.sharedContainerDefaults.hostname, port: port)
    }

    init(_ domain: NSFileProviderDomain, secret: String?, hostname: String, port: in_port_t) {
        self.init(domainIdentifier: domain.identifier.rawValue, displayName: domain.displayName, secret: secret, hostname: hostname, port: port)
    }

    public init(domainIdentifier: String, displayName: String? = nil, secret: String?, hostname: String, port: in_port_t) {
        self.domainIdentifier = domainIdentifier
        self.port = port
        self.secret = secret ?? "no secret"
        self.displayName = displayName ?? domainIdentifier
        self.hostname = hostname
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["x-domain": self.domainIdentifier, "x-authorization": self.secret]
        session = URLSession(configuration: config)
    }

    public typealias CallResult<T> = Swift.Result<T, Error>

    @discardableResult
    public func makeJSONCall<ParameterType: JSONParameter>(_ parameter: ParameterType, _ data: Data? = nil, shouldRetry: Bool = true,
                                                           _ block: @escaping (CallResult<ParameterType.ReturnType>) async -> Void)
                                                            -> Progress {
        makeJSONCallGeneric(parameter, data, shouldRetry: shouldRetry) { result in
            async {
                await block(result.map { tuple in return tuple.0 })
            }
        }
    }

    public func makeJSONCall<ParameterType: JSONParameter>(_ parameter: ParameterType,
                                                           _ data: Data? = nil,
                                                           shouldRetry: Bool = true) async throws -> ParameterType.ReturnType {
        try await withCheckedThrowingContinuation { continuation in
            makeJSONCallGeneric(parameter, data, shouldRetry: shouldRetry) { result in
                let response = result.map { tuple in return tuple.0 }
                continuation.resume(with: response)
            }
        }
    }

    @discardableResult
    public func makeJSONCallWithReturn<ParameterType: JSONParameter>(
        _ parameter: ParameterType, _ data: Data? = nil, shouldRetry: Bool = true,
        _ block: @escaping (Swift.Result<(response: ParameterType.ReturnType, data: Data), Error>) -> Void) -> Progress {
        makeJSONCallGeneric(parameter, data, shouldRetry: shouldRetry, block)
    }

    // Identify the domain's root item by this identifier on the extension side.
    public static let rootItemIdentifier: DomainService.ItemIdentifier = 0
    public static let trashItemIdentifier: DomainService.ItemIdentifier = 1

    @discardableResult
    private func makeJSONCallGeneric<ParameterType: JSONParameter>(
        _ parameter: ParameterType, _ data: Data? = nil, shouldRetry: Bool = true,
        _ block: @escaping (Swift.Result<(response: ParameterType.ReturnType, data: Data), Error>) -> Void) -> Progress {
        let enc = JSONEncoder()
        let dec = JSONDecoder()
        enc.userInfo[DomainService.rootItemCodingInfoKey] = DomainConnection.rootItemIdentifier
        dec.userInfo[DomainService.rootItemCodingInfoKey] = DomainConnection.rootItemIdentifier
        enc.userInfo[DomainService.trashItemCodingInfoKey] = DomainConnection.trashItemIdentifier
        dec.userInfo[DomainService.trashItemCodingInfoKey] = DomainConnection.trashItemIdentifier
        enc.keyEncodingStrategy = .convertToSnakeCase
        dec.keyDecodingStrategy = .convertFromSnakeCase

        let args: String = String(data: try! enc.encode(parameter), encoding: .utf8)!

        let queryItem = URLQueryItem(name: "arguments", value: args)

        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = hostname
        urlComponents.port = Int(port)
        urlComponents.path = "/\(ParameterType.endpoint)"
        urlComponents.queryItems = [queryItem]

        let url = urlComponents.url!

        var request = URLRequest(url: url)

        request.httpBody = data
        request.httpMethod = ParameterType.method.rawValue

        if let data = data {
            logger.debug("🌐 \(displayName)/\(ParameterType.endpoint): \(String(describing: parameter)) + \(data.count) bytes")
        } else {
            logger.debug("🌐 \(displayName)/\(ParameterType.endpoint): \(String(describing: parameter))")
        }

        let handler = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain &&
                    nsError.code == NSURLErrorNetworkConnectionLost &&
                    shouldRetry {
                    self.logger.debug("❌ \(self.displayName)/\(ParameterType.endpoint): connection lost; retrying")
                    self.makeJSONCallGeneric(parameter, data, shouldRetry: false, block)
                } else {
                    self.logger.debug("❌ \(self.displayName)/\(ParameterType.endpoint): connection error: \(nsError)")
                    block(.failure(error))
                }
                return
            }
            do {
                guard let response = response as? HTTPURLResponse else { return block(.failure(CommonError.internalError)) }
                guard response.statusCode == 200 else {
                    guard let data = response.value(forHTTPHeaderField: CommonError.errorHeader) else {
                        return block(.failure(CommonError.httpError(response)))
                    }
                    let ret = try dec.decode(CommonError.self, from: Data(data.utf8))
                    self.logger.debug("❌ \(self.displayName)/\(ParameterType.endpoint): server error: \(String(describing: ret))")
                    return block(.failure(ret))
                }
                guard let data = data else { return block(.failure(CommonError.internalError)) }
                func finish(_ ret: ParameterType.ReturnType, _ data: Data?) {
                    if let data = data {
                        self.logger.debug("💟 \(self.displayName)/\(ParameterType.endpoint): \(String(describing: ret)) + \(data.count) bytes")
                    } else {
                        self.logger.debug("💟 \(self.displayName)/\(ParameterType.endpoint): \(String(describing: ret))")
                    }
                    block(.success((ret, data ?? Data())))
                }
                let ret: ParameterType.ReturnType
                if let apiResponse = response.value(forHTTPHeaderField: "API-Response"),
                   let responseData = Data(base64Encoded: apiResponse) {
                    ret = try dec.decode(ParameterType.ReturnType.self, from: responseData)
                    finish(ret, data)
                } else {
                    ret = try dec.decode(ParameterType.ReturnType.self, from: data)
                    finish(ret, nil)
                }
            } catch let error as NSError {
                self.logger.debug("❌ \(self.displayName)/\(ParameterType.endpoint): error: \(error)")
                return block(.failure(error))
            }
        }

        let task = session.dataTask(with: request, completionHandler: handler)
        task.resume()
        let progress = task.progress
        let existing = progress.cancellationHandler
        progress.cancellationHandler = {
            self.logger.debug("❌ \(self.displayName)/\(ParameterType.endpoint): request was cancelled")
            existing?()
        }
        return progress
    }

    public func makeSynchronousJSONCall<ParameterType: JSONParameter>(
        _ parameter: ParameterType,
        _ data: Data? = nil,
        timeout: DispatchTimeInterval
    ) throws -> ParameterType.ReturnType {
        let sema = DispatchSemaphore(value: 0)

        var result: Swift.Result<ParameterType.ReturnType, Error>? = nil
        makeJSONCall(parameter, data) { innerResult in
            result = innerResult
            sema.signal()
        }
        if sema.wait(timeout: DispatchTime.now().advanced(by: timeout)) == .timedOut {
            throw CommonError.timedOut
        } else {
            return try result!.get()
        }
    }

    public func makeSynchronousJSONCallWithReturn<ParameterType: JSONParameter>(
        _ parameter: ParameterType,
        _ data: Data? = nil,
        timeout: DispatchTimeInterval
    ) throws -> (response: ParameterType.ReturnType, data: Data) {
        let sema = DispatchSemaphore(value: 0)

        var result: Swift.Result<(response: ParameterType.ReturnType, data: Data), Error>? = nil
        makeJSONCallWithReturn(parameter, data) { innerResult in
            result = innerResult
            sema.signal()
        }
        if sema.wait(timeout: DispatchTime.now().advanced(by: timeout)) == .timedOut {
            throw CommonError.timedOut
        } else {
            return try result!.get()
        }
    }
}
