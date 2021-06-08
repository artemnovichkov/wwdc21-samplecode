/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Adds a custom service source to the extension.
*/

import FileProvider
import Common

extension Extension: NSFileProviderServicing {
    public func supportedServiceSources(for itemIdentifier: NSFileProviderItemIdentifier,
                                        completionHandler: @escaping ([NSFileProviderServiceSource]?, Error?) -> Void) -> Progress {
        completionHandler([FruitBasketServiceSource(self)], nil)
        let progress = Progress()
        progress.cancellationHandler = { completionHandler(nil, NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)) }
        return progress
    }
}

public let fruitBasketServiceName = NSFileProviderServiceName("com.example.FruitService")
public let fruitBasketServiceInterface: NSXPCInterface = {
    let interface = NSXPCInterface(with: FruitBasketServiceV1.self)
    // Specify the classes that Set may contain in the XPC interface.
    interface.setClasses(NSSet(array: [NSURL.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.versions(for:)), argumentIndex: 0, ofReply: false)

    interface.setClasses(NSSet(array: [NSArray.self, NSData.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.versions(for:)), argumentIndex: 0, ofReply: true)

    interface.setClasses(NSSet(array: [NSData.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.versions(for:)), argumentIndex: 1, ofReply: true)

    interface.setClasses(NSSet(array: [NSArray.self, NSNumber.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.keep(versions:baseVersion:for:)), argumentIndex: 0, ofReply: false)

    interface.setClasses(NSSet(array: [NSData.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.keep(versions:baseVersion:for:)), argumentIndex: 1, ofReply: false)

    interface.setClasses(NSSet(array: [NSURL.self]) as! Set<AnyHashable>,
                         for: #selector(FruitBasketServiceV1.keep(versions:baseVersion:for:)), argumentIndex: 2, ofReply: false)
    return interface
}()

@objc public protocol FruitBasketServiceV1 {
    func versions(for url: URL) async throws -> ([NSData], NSData)
    func keep(versions: [NSNumber], baseVersion: NSData, for url: URL) async throws
}

extension Extension {
    class FruitBasketServiceSource: NSObject, NSFileProviderServiceSource, NSXPCListenerDelegate, FruitBasketServiceV1 {
        var serviceName: NSFileProviderServiceName {
            fruitBasketServiceName
        }

        func makeListenerEndpoint() throws -> NSXPCListenerEndpoint {
            let listener = NSXPCListener.anonymous()
            listener.delegate = self
            synchronized(self) {
                listeners.add(listener)
            }
            listener.resume()
            return listener.endpoint
        }

        func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
            newConnection.exportedInterface = fruitBasketServiceInterface
            newConnection.exportedObject = self

            synchronized(self) {
                listeners.remove(listener)
            }

            newConnection.resume()
            return true
        }

        weak var ext: Extension?
        let listeners = NSHashTable<NSXPCListener>()

        init(_ ext: Extension) {
            self.ext = ext
        }

        func versions(for url: URL) async throws -> ([NSData], NSData) {
            guard let ext = ext else {
                throw CommonError.internalError.toPresentableError()
            }
            return try await withCheckedThrowingContinuation { continuation in
                NSFileProviderManager.getIdentifierForUserVisibleFile(at: url) { identifier, domainIdentifier, error in
                    guard let identifier = identifier,
                        let domainIdentifier = domainIdentifier,
                        ext.domain.identifier == domainIdentifier else {
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(throwing: NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil))
                            }
                            return
                    }

                    let param = DomainService.ConflictVersionsParameter(identifier: DomainService.ItemIdentifier(identifier))
                    ext.connection.makeJSONCall(param) { result in
                        switch result {
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        case .success(let resp):
                            let dataArray: [NSData] = resp.versions.map { try! JSONEncoder().encode($0) as NSData }
                            let dataOptional: NSData = try! JSONEncoder().encode(resp.currentVersion) as NSData
                            continuation.resume(returning: (dataArray, dataOptional))
                        }
                    }
                }
            }

        }

        func keep(versions: [NSNumber], baseVersion: NSData, for url: URL) async throws {
            let conflicts = versions.map({ $0.int64Value })
            guard let ext = ext else {
                throw CommonError.internalError.toPresentableError()
            }
            guard let baseVersion = try? JSONDecoder().decode(DomainService.Version.self, from: baseVersion as Data) else {
                throw CommonError.parameterError.toPresentableError()
            }

            return try await withCheckedThrowingContinuation { continuation in
                NSFileProviderManager.getIdentifierForUserVisibleFile(at: url) { identifier, domainIdentifier, error in
                    guard let identifier = identifier,
                        let domainIdentifier = domainIdentifier,
                        ext.domain.identifier == domainIdentifier else {
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(throwing: NSError(domain: NSCocoaErrorDomain, code: -1, userInfo: nil))
                            }
                            return
                    }

                    let param = DomainService.ResolveConflictVersionsParameter(identifier: DomainService.ItemIdentifier(identifier),
                                                                               versionsToKeep: conflicts, baseVersion: baseVersion)
                    ext.connection.makeJSONCall(param) { result in
                        switch result {
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        case .success:
                            continuation.resume(returning: ())
                        }
                    }

                }
            }
        }

    }
}

extension DomainService.ConflictVersion {
    init(_ data: Data) throws {
        self = try JSONDecoder().decode(DomainService.ConflictVersion.self, from: data)
    }
}
