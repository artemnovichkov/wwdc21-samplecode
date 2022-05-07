/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The message action handler.
*/
import MailKit

class MessageActionHandler: NSObject, MEMessageActionHandler {

    static let shared = MessageActionHandler()
    
    func decideActionForMessage(for message: MEMessage) async -> MEMessageActionDecision? {
        
        // Check if the subject of the message contains a mention of one of the X-Special-Projects.
        // If it does, specify an action to set the color to yellow.
        if SpecialProjectHandler.SpecialProject.allCases.first(where: { message.subject.contains($0.rawValue) }) != nil {
            return MEMessageActionDecision.action(.setColorActionWith(.yellow))
        }
        
        // If there is no message data, return `.invokeAgainWithBody`.
        if message.rawData == nil {
            return MEMessageActionDecision.invokeAgainWithBody
        }
        
        // Check if there is an additional header for one of the X-Special-Projects.
        // If there is, specify an action to set the color based on the project.
        if let projects = message.headers?[SpecialProjectHandler.specialProjectsHeader] {
            if projects.contains(SpecialProjectHandler.SpecialProject.marsRemoteOffice.rawValue) {
                return MEMessageActionDecision.action(.setColorActionWith(.red))
            } else if projects.contains(SpecialProjectHandler.SpecialProject.apSpaceShuttle.rawValue) {
                return MEMessageActionDecision.action(.setColorActionWith(.green))
            }
        }
        
        // Check if the message contains a mention of one of the X-Special-Projects.
        // If it does, specify an action to set the color to purple.
        if let rawData = message.rawData,
           let text = String(data: rawData, encoding: .utf8),
           SpecialProjectHandler.SpecialProject.allCases.first(where: { text.contains($0.rawValue) }) != nil {
            return MEMessageActionDecision.action(.setColorActionWith(.purple))
        }
        
        // Always call the completion handler, passing the action
        // to take, or nil if there's no action.
        return nil
    }
    
}
