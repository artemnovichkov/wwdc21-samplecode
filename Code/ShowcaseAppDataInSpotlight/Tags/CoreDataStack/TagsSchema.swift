/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The names of relevant entities and attributes in the Core Data schema.
*/

enum TagsSchema {
    enum Photo: String {
        case uniqueName, userSpecifiedName
    }
    enum Tag: String {
        case name, photoCount
    }
}

