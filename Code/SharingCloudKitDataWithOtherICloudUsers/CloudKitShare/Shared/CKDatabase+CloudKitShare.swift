/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension of CKDatabase that implements some convenient methods.
*/

import UIKit
import CloudKit

extension CKDatabase {
    var name: String { // Provide a display name for the database.
        switch databaseScope {
        case .public: return "Public"
        case .private: return "Private"
        case .shared: return "Shared"
        @unknown default:
            fatalError("Unsupported database scope!")
        }
    }
    
    // Add an operation to the specified operation queue, or the database internal queue if
    // there isn’t a specified operation queue.
    //
    private func add(_ operation: CKDatabaseOperation, to queue: OperationQueue?) {
        if let operationQueue = queue {
            operation.database = self
            operationQueue.addOperation(operation)
            
        } else {
            add(operation)
        }
    }
        
    // Use subscriptionID to create a subscription.
    // An error occurs if a subscription with the same ID already exists.
    //
    func addDatabaseSubscription(
        subscriptionID: String, operationQueue: OperationQueue? = nil,
        completionHandler: @escaping (NSError?) -> Void) {
        
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldBadge = true
        notificationInfo.alertBody = "Database (\(subscriptionID)) was changed!"
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.modifySubscriptionsCompletionBlock = { _, _, error in
            completionHandler(error as NSError?)
        }
        
        add(operation, to: operationQueue)
    }
}
