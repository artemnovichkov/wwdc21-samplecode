/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cache that saves things in local files.
*/

import Foundation
import UIKit
import os
import UniformTypeIdentifiers

extension Logger {
    static let disabled = Logger(.disabled)
    static let `default` = Logger(.default)
}

class FileBasedCache: Cache {
    var fileManager: FileManager
    let imageFormat: UTType
    let directory: URL
    var logger: Logger
    var signposter: OSSignposter
    
    var isPlaceholderStore: Bool = false
    
    init(directory: URL,
         imageFormat: UTType = .jpeg,
         logger: Logger = .default,
         fileManager: FileManager = .default) {
        self.directory = directory
        self.logger = logger
        self.signposter = OSSignposter(logger: logger)
        self.imageFormat = imageFormat
        self.fileManager = fileManager
    }
    
    func createDirectoryIfNeeded() throws {
        try fileManager.createDirectory(at: self.directory,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
    }
    
    func fetchByID(_ id: Asset.ID) -> Asset? {
        guard let image = UIImage(contentsOfFile: url(forID: id).path) else {
            return nil
        }
        return Asset(id: id, isPlaceholder: isPlaceholderStore, image: image)
    }

    func addByMovingFromURL(_ url: URL, forAsset id: Asset.ID) {
        precondition(isMatchingImageType(url), "Asset at \(url) does not conform to \(imageFormat)")
        try? fileManager.moveItem(at: url, to: self.url(forID: id))
    }
    
    func clear() throws {
        try fileManager.removeItem(at: self.directory)
        try createDirectoryIfNeeded()
    }
    
    func isMatchingImageType(_ url: URL) -> Bool {
        return UTType(
            filenameExtension: url.pathExtension,
            conformingTo: imageFormat
        ) != nil
    }
    
    func url(forID id: Asset.ID) -> URL {
        return directory.appendingPathComponent(id).appendingPathExtension(for: imageFormat)
    }
}
