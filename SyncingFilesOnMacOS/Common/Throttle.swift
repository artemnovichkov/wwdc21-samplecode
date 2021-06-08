/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An object that throttles responses from the local HTTP server.
*/

import Foundation

public class Throttle {
    internal let queue: DispatchQueue
    internal let timeout: DispatchTimeInterval
    internal let timerSource: DispatchSourceTimer
    internal var scheduled = false
    public typealias Block = () -> Void

    public init(timeout: DispatchTimeInterval, _ label: String) {
        queue = DispatchQueue(label: label)
        timerSource = DispatchSource.makeTimerSource(flags: [], queue: queue)
        self.timeout = timeout
    }

    public func signal() {
        queue.async {
            guard !self.scheduled else { return }
            self.timerSource.schedule(deadline: DispatchTime.now().advanced(by: self.timeout))
            self.scheduled = true
        }
    }

    public var handler: Block? {
        willSet {
            assert(handler == nil, "handler set twice")
        }
        didSet {
            timerSource.setEventHandler { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.scheduled = false
                strongSelf.handler?()
            }
        }
    }

    // The handler must be set before calling resume.
    public func resume() {
        assert(handler != nil, "handler not set")
        timerSource.resume()
    }
}
