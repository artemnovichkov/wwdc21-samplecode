/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Common errors used throughout the project.
*/

import Foundation

public enum CommonError: Error, Codable, LocalizedError {
    public static let errorHeader = "X-API-Error"

    internal enum Values: String, Codable {
        case internalError
        case clientCrashingError
        case notImplemented
        case timedOut
        case parameterError
        case itemNotFound
        case domainNotFound
        case wrongRevision
        case itemExists
        case httpError
        case authRequired
        case accountExists
        case tokenExpired
        case simulatedError
        case insufficientQuota
        case deletionRejected
    }

    internal enum CodingKeys: String, CodingKey {
        case value
        case entry
        case identifier
        case errorDomain
        case errorCode
        case errorLocalizedDescription
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Values.self, forKey: .value) {
        case .internalError:
            self = .internalError
        case .clientCrashingError:
            self = .clientCrashingError
        case .notImplemented:
            self = .notImplemented
        case .timedOut:
            self = .timedOut
        case .parameterError:
            self = .parameterError
        case .itemNotFound:
            let identifier = try container.decode(DomainService.ItemIdentifier.self, forKey: .identifier)
            self = .itemNotFound(identifier)
        case .domainNotFound:
            self = .domainNotFound
        case .wrongRevision:
            let entry = try container.decode(DomainService.Entry.self, forKey: .entry)
            self = .wrongRevision(entry)
        case .itemExists:
            let entry = try container.decode(DomainService.Entry.self, forKey: .entry)
            self = .itemExists(entry)
        case .httpError:
            // Don't attempt to decode an HTTP error.
            fatalError()
        case .authRequired:
            self = .authRequired
        case .accountExists:
            self = .accountExists
        case .tokenExpired:
            self = .tokenExpired
        case .simulatedError:
            let code = try container.decode(Int.self, forKey: .errorCode)
            let domain = try container.decode(String.self, forKey: .errorDomain)
            let localizedDescription = try container.decodeIfPresent(String.self, forKey: .errorLocalizedDescription)
            self = .simulatedError(domain, code, localizedDescription)
        case .insufficientQuota:
            self = .insufficientQuota
        case .deletionRejected:
            let entry = try container.decode(DomainService.Entry.self, forKey: .entry)
            self = .deletionRejected(entry)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .internalError:
            try container.encode(Values.internalError, forKey: .value)
        case .clientCrashingError:
            try container.encode(Values.clientCrashingError, forKey: .value)
        case .notImplemented:
            try container.encode(Values.notImplemented, forKey: .value)
        case .timedOut:
            try container.encode(Values.timedOut, forKey: .value)
        case .parameterError:
            try container.encode(Values.parameterError, forKey: .value)
        case .itemNotFound(let identifier):
            try container.encode(identifier, forKey: .identifier)
            try container.encode(Values.itemNotFound, forKey: .value)
        case .domainNotFound:
            try container.encode(Values.domainNotFound, forKey: .value)
        case .wrongRevision(let entry):
            try container.encode(entry, forKey: .entry)
            try container.encode(Values.wrongRevision, forKey: .value)
        case .itemExists(let entry):
            try container.encode(Values.itemExists, forKey: .value)
            try container.encode(entry, forKey: .entry)
        case .httpError:
            fatalError()
        case .authRequired:
            try container.encode(Values.authRequired, forKey: .value)
        case .accountExists:
            try container.encode(Values.accountExists, forKey: .value)
        case .tokenExpired:
            try container.encode(Values.tokenExpired, forKey: .value)
        case .simulatedError(let domain, let code, let localizedDescription):
            try container.encode(domain, forKey: .errorDomain)
            try container.encode(code, forKey: .errorCode)
            try container.encode(localizedDescription, forKey: .errorLocalizedDescription)
            try container.encode(Values.simulatedError, forKey: .value)
        case .insufficientQuota:
            try container.encode(Values.insufficientQuota, forKey: .value)
        case .deletionRejected(let entry):
            try container.encode(entry, forKey: .entry)
            try container.encode(Values.deletionRejected, forKey: .value)
        }
    }

    case internalError
    case clientCrashingError
    case notImplemented
    case timedOut
    case parameterError
    case itemNotFound(DomainService.ItemIdentifier)
    case domainNotFound
    case wrongRevision(DomainService.Entry)
    case itemExists(DomainService.Entry)
    case httpError(URLResponse)
    case authRequired
    case accountExists
    case tokenExpired
    case simulatedError(String, Int, String?)
    case insufficientQuota
    case deletionRejected(DomainService.Entry)

    public var errorDescription: String? {
        return "\(self)"
    }
}

