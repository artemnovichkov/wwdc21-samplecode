/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Struct representing each item in the data source array.
*/

import Foundation

class Item: NSObject, Codable {
    var identifier = ""
    var title = ""
    var notes = ""
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case identifier
        case title
        case notes
    }
    
    init(title: String, notes: String, identifier: String?) {
        self.title = title
        self.notes = notes
        self.identifier = identifier ?? UUID().uuidString
    }

    override var hash: Int {
        return identifier.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherItem = object as? Item else { return false }
        return identifier == otherItem.identifier
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(notes, forKey: .notes)
        try container.encode(identifier, forKey: .identifier)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        notes = try values.decode(String.self, forKey: .notes)
        identifier = try values.decode(String.self, forKey: .identifier)
    }

}
