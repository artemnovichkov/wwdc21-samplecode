/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension that provides HTTP responses for common errors.
*/

import Foundation
import Common
import Swifter

extension CommonError {
    func asHTTPResponse(_ enc: JSONEncoder) -> HttpResponse {
        enc.keyEncodingStrategy = .convertToSnakeCase
        let json = String(data: try! enc.encode(self), encoding: .utf8)!

        let headers = [CommonError.errorHeader: json]

        switch self {
        case .internalError:
            return .raw(500, "Internal server error", headers, nil)
        case .clientCrashingError:
            return .raw(500, "Requesting client crash", headers, nil)
        case .notImplemented:
            return .raw(500, "Not implemented", headers, nil)
        case .parameterError:
            return .raw(400, "Invalid parameters", headers, nil)
        case .itemNotFound:
            return .raw(404, "Not found", headers, nil)
        case .domainNotFound:
            return .raw(404, "Not found", headers, nil)
        case .itemExists:
            return .raw(409, "Item exists", headers, nil)
        case .wrongRevision:
            return .raw(409, "Wrong revision", headers, nil)
        case .timedOut:
            return .raw(408, "Timed out", headers, nil)
        case .httpError:
            fatalError()
        case .accountExists:
            return .raw(409, "Account exists", headers, nil)
        case .authRequired:
            return .raw(401, "Authentication required", headers, nil)
        case .tokenExpired:
            return .raw(409, "Sync token expired", headers, nil)
        case .simulatedError(let domain, let code, let localizedDescription):
            // Map a simulated error to a 500 and include the original code in the message.
            return .raw(500, "Error \(code) in domain \(domain)\(localizedDescription.map { " (\($0))" } ?? "")", headers, nil)
        case .insufficientQuota:
            return .raw(401, "Insufficient quota", headers, nil)
        case .deletionRejected:
            return .raw(409, "Deletion rejected", headers, nil)
        }
    }
}
