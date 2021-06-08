/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A protocol that the other intent-handling classes conform to.
*/

import Intents

protocol Handler: AnyObject {
    
    func canHandle(_ intent: INIntent) -> Bool
    
}

