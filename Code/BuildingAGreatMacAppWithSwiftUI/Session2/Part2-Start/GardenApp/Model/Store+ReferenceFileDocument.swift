/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The various extensions to support file export.
*/

import SwiftUI
import UniformTypeIdentifiers

extension Store: ReferenceFileDocument {
    typealias Snapshot = [Garden]

    static var readableContentTypes = [UTType.commaSeparatedText]

    convenience init(configuration: ReadConfiguration) throws {
        self.init()
    }

    func snapshot(contentType: UTType) throws -> Snapshot {
        gardens
    }

    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        var exportedData = Data()
        if let header = Bundle.main.localizedString(forKey: "CSV Header", value: nil, table: nil).data(using: .utf8) {
            exportedData.append(header)
            exportedData.append(newline)
        }
        for garden in snapshot {
            for plant in garden.plants {
                garden.append(to: &exportedData)
                plant.append(to: &exportedData)
                exportedData.append(newline)
            }
        }
        return FileWrapper(regularFileWithContents: exportedData)
    }
}

extension Garden {
    fileprivate func append(to csvData: inout Data) {
        if let data = name.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = numberFormatter.string(from: year as NSNumber)?.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
    }
}

extension Plant {
    fileprivate func append(to csvData: inout Data) {
        if let data = variety.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = numberFormatter.string(from: (plantingDepth ?? 0) as NSNumber)?.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = numberFormatter.string(from: daysToMaturity as NSNumber)?.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = dateFormatter.string(from: datePlanted).data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = favorite.description.data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = dateFormatter.string(from: lastWateredOn).data(using: .utf8) {
            csvData.append(data)
            csvData.append(comma)
        } else {
            csvData.append(comma)
        }
        if let data = numberFormatter.string(from: (wateringFrequency ?? 0) as NSNumber)?.data(using: .utf8) {
            csvData.append(data)
        }
    }
}

private let newline = "\n".data(using: .utf8)!
private let comma = ",".data(using: .utf8)!

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .none
    formatter.hasThousandSeparators = false
    formatter.usesSignificantDigits = true
    return formatter
}()

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()
