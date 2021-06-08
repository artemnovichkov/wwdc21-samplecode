/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The principal class of the extension that returns the appropriate handler per intent.
*/

import Intents

class IntentHandler: INExtension {
    
    private let intentHandlers: [Handler] = [
        RequestRideIntentHandler(),
        ListRideOptionsHandler(),
        GetRideStatusHandler()
    ]
    
    override func handler(for intent: INIntent) -> Any? {
        // Returns correct handler for the triggered intent.
        return intentHandlers.first { $0.canHandle(intent) }
    }
}
