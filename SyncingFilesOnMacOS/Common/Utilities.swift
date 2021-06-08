/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Various utility values, functions, and extensions for use throughout the project.
*/

import Foundation

public var defaultPort: in_port_t = 24_680

@discardableResult
public func throwErrno<T: SignedInteger>(_ block: () throws -> T) throws -> T {
  return try throwErrnoOrError { _ in return try block() }
}

@discardableResult
func throwErrnoOrError<T: SignedInteger>(_ block: (/* errorOrNil */ inout Error?) throws -> T) throws -> T {
  var errorOrNil: Error?
  let ret = try block(&errorOrNil)
  if let error = errorOrNil {
    throw error
  }
  if ret < 0 {
    if errno != 0 {
      let errorCode = POSIXErrorCode(rawValue: errno)
      if let errorCode = errorCode {
        throw POSIXError(errorCode)
      } else {
        throw POSIXError(.EINVAL)
      }
    } else {
      preconditionFailure("call to block failed with \(ret) but errno is not set")
    }
  }
  return ret
}

extension URL {
    // Gets the specified extended attribute value for the file at the URL.
    public func xattr(_ xattrName: String) throws -> Data? {
        let valueLen: ssize_t
        do {
            valueLen = try throwErrno { getxattr(self.path, xattrName, nil, 0, 0, 0) }
        } catch POSIXError.ENOATTR {
            return nil
        }
        var value = Data(capacity: valueLen)

        value.count = valueLen
        _ = try value.withUnsafeMutableBytes { valuePtr in
            try throwErrno { getxattr(self.path, xattrName, valuePtr.bindMemory(to: Int8.self).baseAddress, valuePtr.count, 0, 0) }
        }
        return value
    }

    public func set(xattr value: Data, for xattrName: String) throws {
        _ = try value.withUnsafeBytes { valuePtr in
            try throwErrno { setxattr(self.path, xattrName, valuePtr.bindMemory(to: Int8.self).baseAddress, valuePtr.count, 0, 0) }
        }
    }
}

public func synchronized<T>(_ lock: AnyObject, _ closure: () throws -> T) rethrows -> T {
  objc_sync_enter(lock)
  defer { objc_sync_exit(lock) }
  return try closure()
}

extension String {
    public var utf8Data: Data {
        guard let ret = data(using: .utf8) else {
            fatalError("string \(self) couldn't be transformed to utf8")
        }
        return ret
    }
}
