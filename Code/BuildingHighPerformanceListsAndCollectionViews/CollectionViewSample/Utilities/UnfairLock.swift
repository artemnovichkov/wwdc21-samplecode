/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A custom unfair lock implementation.
*/

import Foundation
import UIKit
import Combine

final class UnfairLock {
    @usableFromInline let lock: UnsafeMutablePointer<os_unfair_lock>
    
    public init() {
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }

    deinit {
        lock.deallocate()
    }
    
    @inlinable
    @inline(__always)
    func withLock<Result>(body: () throws -> Result) rethrows -> Result {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return try body()
    }
    
    @inlinable
    @inline(__always)
    func withLock(body: () -> Void) {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        body()
    }
    
    // Assert that the current thread owns the lock.
    @inlinable
    @inline(__always)
    public func assertOwner() {
        os_unfair_lock_assert_owner(lock)
    }

    // Assert that the current thread does not own the lock.
    @inlinable
    @inline(__always)
    public func assertNotOwner() {
        os_unfair_lock_assert_not_owner(lock)
    }

    private final class LockAssertion: Cancellable {
        private var _owner: UnfairLock

        init(owner: UnfairLock) {
            _owner = owner
            os_unfair_lock_lock(owner.lock)
        }

        __consuming func cancel() {
            os_unfair_lock_unlock(_owner.lock)
        }
    }

    func acquire() -> Cancellable {
        return LockAssertion(owner: self)
    }
}
