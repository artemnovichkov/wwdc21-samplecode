/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A local store for incrementally fetching chunks of files.
*/

import Foundation
import os.log

public protocol ContentBasedChunkStore {
    func chunkExists(sha256OfChunk: Data) -> Bool
    func createChunk(sha256OfChunk: Data, chunkData: Data) throws
    func retrieveChunk(sha256OfChunk: Data) throws -> Data?

    func close()
}

public class LocalContentBasedChunkStore: ContentBasedChunkStore {
    private static let checksumComputer = ChecksumComputer()
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "LocalContentBasedChunkStore")

    private let chunkFileLocator: ChunkFileLocator

    public init() throws {
        self.chunkFileLocator = try ChunkFileLocator()
    }

    public func close() {
        self.chunkFileLocator.close()
    }

    public func chunkExists(sha256OfChunk: Data) -> Bool {
        logger.info("checking if chunk exists for sha: \(sha256OfChunk.hexEncodedString())")
        let chunkFile = self.chunkFileLocator.chunkSha256ToChunkUrl(sha256OfChunk: sha256OfChunk)
        return FileManager.default.fileExists(atPath: chunkFile.path)
    }

    public func createChunk(sha256OfChunk: Data, chunkData: Data) throws {
        if self.chunkExists(sha256OfChunk: sha256OfChunk) {
            logger.info("chunk already exists for sha: \(sha256OfChunk.hexEncodedString())")
            return
        }

        if chunkData.isEmpty {
            logger.error("tried creating an empty chunk. sha of chunk is \(sha256OfChunk)")
            throw CommonError.internalError
        }

        // Write the chunk data into a temporary file.
        let tempFile = self.chunkFileLocator.chunkSha256ToTemporaryChunkUrl(sha256OfChunk: sha256OfChunk)
        try chunkData.write(to: tempFile)

        // Move the temp file to chunkFile.
        let chunkFile = self.chunkFileLocator.chunkSha256ToChunkUrl(sha256OfChunk: sha256OfChunk)
        logger.info("creating chunk, file location is: \(chunkFile)")
        try FileManager.default.moveItem(at: tempFile, to: chunkFile)
    }

    public func retrieveChunk(sha256OfChunk: Data) throws -> Data? {
        logger.info("retrieving chunk for sha: \(sha256OfChunk.hexEncodedString())")
        let chunkFile = self.chunkFileLocator.chunkSha256ToChunkUrl(sha256OfChunk: sha256OfChunk)
        logger.info("chunk file location during retrieve: \(chunkFile)")
        return try Data(contentsOf: chunkFile, options: .alwaysMapped)
    }
}

public class ChunkFileLocator {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "ChunkFileLocator")

    private let chunkDirectory: URL
    private let temporaryChunkDirectory: URL

    public init() throws {
        self.chunkDirectory = try! FileManager().url(for: .documentDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true).appendingPathComponent("chunk_store")
        try! FileManager().createDirectory(at: chunkDirectory, withIntermediateDirectories: true, attributes: nil)
        self.temporaryChunkDirectory = try ChunkFileLocator.createTemporaryDirectory(appropriateFor: chunkDirectory)
    }

    public func close() {
        do {
            try FileManager().removeItem(at: self.temporaryChunkDirectory)
        } catch let error as NSError {
            self.logger.error("Error cleaning up the temporary chunk directory, directory=\(self.temporaryChunkDirectory.absoluteString), error=\(error)")
        }
    }

    public static func createTemporaryDirectory(appropriateFor: URL?) throws -> URL {
        return try FileManager.default.url(for: .itemReplacementDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: appropriateFor ?? URL(string: NSHomeDirectory()),
                                           create: true)
    }

    func chunkSha256ToChunkUrl(sha256OfChunk: Data) -> URL {
        let hexEncodedSha256 = sha256OfChunk.hexEncodedString(options: .upperCase)
        return self.chunkDirectory.appendingPathComponent(hexEncodedSha256)
    }

    func chunkSha256ToTemporaryChunkUrl(sha256OfChunk: Data) -> URL {
        let hexEncodedSha256 = sha256OfChunk.hexEncodedString(options: .upperCase)
        let uuidSuffix = UUID().uuidString
        let filename = "\(hexEncodedSha256)-\(uuidSuffix)"
        return self.temporaryChunkDirectory.appendingPathComponent(filename)
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
