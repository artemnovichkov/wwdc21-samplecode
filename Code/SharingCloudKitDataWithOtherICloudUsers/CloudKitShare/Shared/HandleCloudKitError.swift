/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The functions that handle CloudKit errors.
*/

import UIKit
import CloudKit

// Operation types that identify what the CloudKit operation is doing,
// which provides more context for the error handling.
//
enum CloudKitOperationType: String {
    case accountStatus = "AccountStatus"// Checking account status with CKContainer.accountStatus.
    case fetchRecords = "FetchRecords"  // Fetching data from the CloudKit server.
    case modifyRecords = "ModifyRecords"// Modifying records (handling .serverRecordChanged).
    case deleteRecords = "DeleteRecords"// Deleting records.
    case modifyZones = "ModifyZones"    // Modifying zones (handling .serverRecordChanged).
    case deleteZones = "DeleteZones"    // Deleting zones.
    case fetchZones = "FetchZones"      // Fetching zones.
    case modifySubscriptions = "ModifySubscriptions"    // Modifying subscriptions.
    case deleteSubscriptions = "DeleteSubscriptions"    // Deleting subscriptions.
    case fetchChanges = "FetchChanges"  // Fetching changes (handling .changeTokenExpired).
    case acceptShare = "AcceptShare"    // Accepting a share with CKAcceptSharesOperation.
    case fetchUserID = "FetchUserID"    // Fetching user record IDs with fetchUserRecordID(completionHandler:).
}

// Return nil: No error or the error is ignorable.
// Return a CKError: There's an error. The caller needs to determine how to handle it.
//
func handleCloudKitError(_ error: Error?, operation: CloudKitOperationType,
                         affectedObjects: [Any]? = nil, alert: Bool = false) -> CKError? {
    // nsError == nil: Everything goes well and the caller can continue.
    //
    guard let nsError = error as NSError? else {
        return nil
    }
    
    // Partial errors can happen when fetching or changing the database.
    //
    // When modifying zones, records, and subscriptions, .serverRecordChanged may happen if
    // the other peer changes the item at the same time. In that case, retrieve the first
    // CKError object and return to the caller.
    //
    // In the case of .fetchRecords and fetchChanges, the other peer might delete the specified
    // items or zones, so they might not exist in the database (.unknownItem or .zoneNotFound).
    //
    if let partialError = nsError.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
        // If the error doesn't affect the affectedObjects, ignore it.
        // If it does, only handle the first error.
        //
        let errors = affectedObjects?.map({ partialError[$0] }).filter({ $0 != nil })
        guard let ckError = errors?.first as? CKError else {
            return nil
        }
        return handlePartialError(ckError, operation: operation, alert: alert)
    }
    
    // In the case of fetching changes:
    // .changeTokenExpired: Return for callers to refetch with a nil server token.
    // .zoneNotFound: Return for callers to switch zones because the current zone doesn't exist.
    // .partialFailure: zoneNotFound triggers a partial error as well.
    //
    if operation == .fetchChanges {
        if let ckError = error as? CKError {
            if ckError.code == .changeTokenExpired || ckError.code == .zoneNotFound {
                return ckError
            }
        }
    }
    
    // If the client requires an alert, alert the error, or append the error message to an existing alert.
    //
    if alert {
        alertError(code: nsError.code, domain: nsError.domain,
                   message: nsError.localizedDescription, operation: operation)
    }
    print("\(operation.rawValue) operation error: \(nsError)")
    return error as? CKError
}

private func handlePartialError(_ error: CKError, operation: CloudKitOperationType,
                                alert: Bool = false) -> CKError? {
    // Items don't exist. Silently ignore the error for the .delete... operation.
    //
    if operation == .deleteZones || operation == .deleteRecords || operation == .deleteSubscriptions {
        if error.code == .unknownItem {
            return nil
        }
    }

    if error.code == .serverRecordChanged {
        print("Server record changed. Consider using serverRecord and ignore this error!")
    } else if error.code == .zoneNotFound {
        print("Zone not found. May have been deleted. Probably ignore!")
    } else if error.code == .unknownItem {
        print("Unknown item. May have been deleted. Probably ignore!")
    } else if error.code == .batchRequestFailed {
        print("Atomic failure!")
    } else {
        if alert {
            alertError(code: error.errorCode, domain: CKError.errorDomain,
                       message: error.localizedDescription, operation: operation)
        }
        print("\(operation.rawValue) operation error: \(error)")
    }
    return error
}

private func alertError(code: Int, domain: String, message: String, operation: CloudKitOperationType) {
    DispatchQueue.main.async {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDeleate = scene.delegate as? SceneDelegate,
              let viewController = sceneDeleate.window?.rootViewController else {
            return
        }
        
        let message = "\(operation.rawValue) operation hit error.\n" +
                        "Error code: \(code)\n" + "Domain: \(domain)\n" + message

        if let existingAlert = viewController.presentedViewController as? UIAlertController {
            existingAlert.message = (existingAlert.message ?? "") + "\n\n\(message)"
            return
        }
        
        let newAlert = UIAlertController(title: "CloudKit Operation Error!",
                                      message: message, preferredStyle: .alert)
        newAlert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(newAlert, animated: true)
    }
}
