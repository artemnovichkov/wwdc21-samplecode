/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Select entities and attributes from the Core Data model. Use these to check whether a persistent history change is relevant to the current view.
*/
import CoreData

/**
 Relevant entities and attributes in the Core Data schema.
 */
enum Schema {
    enum Post: String {
        case title
    }
    enum Tag: String {
        case uuid, name, postCount
    }
}
