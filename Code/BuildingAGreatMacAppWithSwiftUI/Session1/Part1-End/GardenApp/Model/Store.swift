/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data store for this sample.
*/

import Foundation

class Store: ObservableObject {
    @Published var gardens: [Garden] = []
    @Published var selectedGarden: Garden.ID?
    @Published var mode: GardenDetail.ViewMode = .table

    private var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private var filename = "database.json"

    private var databaseFileUrl: URL {
        applicationSupportDirectory.appendingPathComponent(filename)
    }

    private func loadGardens(from storeFileData: Data) -> [Garden] {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Garden].self, from: storeFileData)
        } catch {
            print(error)
            return []
        }
    }

    init() {
        if let data = FileManager.default.contents(atPath: databaseFileUrl.path) {
            gardens = loadGardens(from: data)
        } else {
            if let bundledDatabaseUrl = Bundle.main.url(forResource: "database", withExtension: "json") {
                if let data = FileManager.default.contents(atPath: bundledDatabaseUrl.path) {
                    gardens = loadGardens(from: data)
                }
            } else {
                gardens = []
            }
        }
    }

    subscript(gardenID: Garden.ID?) -> Garden {
        get {
            if let id = gardenID {
                return gardens.first(where: { $0.id == id }) ?? .placeholder
            }
            return .placeholder
        }

        set(newValue) {
            if let id = gardenID {
                gardens[gardens.firstIndex(where: { $0.id == id })!] = newValue
            }
        }
    }

    func append(_ garden: Garden) {
        gardens.append(garden)
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(gardens)
            if FileManager.default.fileExists(atPath: databaseFileUrl.path) {
                try FileManager.default.removeItem(at: databaseFileUrl)
            }
            try data.write(to: databaseFileUrl)
        } catch {
            //..
        }
    }
}

extension Store {

    func gardens(in year: Int) -> [Garden] {
        gardens.filter({ $0.year == year })
    }

    var currentYear: Int { 2021 }

    var previousYears: ClosedRange<Int> { (2018...2020) }
}
