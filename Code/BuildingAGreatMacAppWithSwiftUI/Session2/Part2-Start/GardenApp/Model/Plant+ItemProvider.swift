/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The extension to Plant to support drag and drop.
*/

import Foundation
import UniformTypeIdentifiers

extension Plant {
    static var draggableType = UTType(exportedAs: "com.example.apple-samplecode.GardenApp.plant")

    /// Extracts encoded plant data from the specified item providers.
    /// The specified closure will be called with the array of  resulting`Plant` values.
    ///
    /// Note: because this method uses `NSItemProvider.loadDataRepresentation(forTypeIdentifier:completionHandler:)`
    /// internally, it is currently not marked as `async`.
    static func fromItemProviders(_ itemProviders: [NSItemProvider], completion: @escaping ([Plant]) -> Void) {
        let typeIdentifier = Self.draggableType.identifier
        let filteredProviders = itemProviders.filter {
            $0.hasItemConformingToTypeIdentifier(typeIdentifier)
        }

        let group = DispatchGroup()
        var result = [Int: Plant]()

        for (index, provider) in filteredProviders.enumerated() {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { (data, error) in
                defer { group.leave() }
                guard let data = data else { return }
                let decoder = JSONDecoder()
                guard let plant = try? decoder.decode(Plant.self, from: data)
                else { return }
                result[index] = plant
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            let plants = result.keys.sorted().compactMap { result[$0] }
            DispatchQueue.main.async {
                completion(plants)
            }
        }
    }

    var itemProvider: NSItemProvider {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: Self.draggableType.identifier, visibility: .all) {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self)
                $0(data, nil)
            } catch {
                $0(nil, error)
            }
            return nil
        }
        return provider
    }
}
