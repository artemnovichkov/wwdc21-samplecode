/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A protocol for providing backend APIs to the backend dispatch.
*/

import Foundation
import Common

public protocol DispatchBackend {
    var displayName: String { get }
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
    var queue: DispatchQueue { get }
    func checkForDomainApproval(_ headers: [String: String], _ path: String) throws
    static func registerCalls(_ dispatch: BackendCallRegistration)
}

// A protocol for objects that support registering backend calls.
public protocol BackendCallRegistration {
    func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType, Data) throws -> (ReturnType))

    func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType) throws -> (ReturnType))

    func registerBackendCall<ParameterType: JSONParameter, ReturnType: Encodable, Backend: DispatchBackend>(
        _ backendCall: @escaping (Backend) -> (ParameterType) throws -> (ReturnType, Data))
}
