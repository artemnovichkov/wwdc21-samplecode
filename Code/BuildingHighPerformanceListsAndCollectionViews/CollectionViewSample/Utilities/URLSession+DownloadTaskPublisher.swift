/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A URL session data task publisher.
*/

import Foundation
import Combine

extension URLSession {
    public func downloadTaskPublisher(for request: URLRequest) -> DownloadTaskPublisher {
        return DownloadTaskPublisher(request: request, session: self)
    }
    
    public func downloadTaskPublisher(for url: URL) -> DownloadTaskPublisher {
        self.downloadTaskPublisher(for: URLRequest(url: url))
    }
}

public struct DownloadTaskPublisher: Publisher {
    
    public typealias Output = (url: URL, response: URLResponse)
    public typealias Failure = URLError
    
    public let request: URLRequest
    public let session: URLSession
    
    public init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber,
                                                DownloadTaskPublisher.Failure == S.Failure,
                                                DownloadTaskPublisher.Output == S.Input {
        let subscription = DownloadTaskSubscription(parent: self, downstream: subscriber)
        subscriber.receive(subscription: subscription)
    }
    
    private typealias Parent = DownloadTaskPublisher
    private final class DownloadTaskSubscription<Downstream: Subscriber>: Subscription
        where
            Downstream.Input == Parent.Output,
            Downstream.Failure == Parent.Failure {
        
        private let lock: UnfairLock
        private var parent: Parent?
        private var downstream: Downstream?
        private var demand: Subscribers.Demand
        private var task: URLSessionDownloadTask!
        
        init(parent: Parent, downstream: Downstream) {
            self.lock = UnfairLock()
            self.parent = parent
            self.downstream = downstream
            self.demand = .max(0)
            self.task = parent.session.downloadTask(with: parent.request, completionHandler: handleResponse(url:response:error:))
            
        }
        
        func request(_ demandingSubscribers: Subscribers.Demand) {
            precondition(demandingSubscribers > 0, "Invalid request of zero demand")
            
            let lockAssertion = lock.acquire()
            guard parent != nil else {
                // The lock has already been canceled so bail.
                lockAssertion.cancel()
                return
            }
            
            self.demand += demandingSubscribers
            guard let task = self.task else {
                lockAssertion.cancel()
                return
            }
            lockAssertion.cancel()
            
            task.resume()
        }
        
        private func handleResponse(url: URL?, response: URLResponse?, error: Error?) {
            let lockAssertion = lock.acquire()
            guard demand > 0,
                  parent != nil,
                  let downstreamResponse = downstream
            else {
                lockAssertion.cancel()
                return
            }
            
            parent = nil
            downstream = nil
            
            // Clear demand since this is a single shot shape.
            demand = .max(0)
            task = nil
            lockAssertion.cancel()
            
            if let url = url, let response = response, error == nil {
                _ = downstreamResponse.receive((url, response))
                downstreamResponse.receive(completion: .finished)
            } else {
                let urlError = error as? URLError ?? URLError(.unknown)
                downstreamResponse.receive(completion: .failure(urlError))
            }
        }
        
        func cancel() {
            let lockAssertion = lock.acquire()
            guard parent != nil else {
                lockAssertion.cancel()
                return
            }
            parent = nil
            downstream = nil
            demand = .max(0)
            let task = self.task
            self.task = nil
            lockAssertion.cancel()
            task?.cancel()
        }
    }
    
}
