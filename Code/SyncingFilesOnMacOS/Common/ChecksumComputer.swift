/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Computes checksums for use with incremental fetching.
*/

import Foundation
import CryptoKit
import os.log

public struct RangeAndSha256: Equatable {
    public let range: Range<Int>
    public let sha256: String

    public init(range: Range<Int>,
                sha256: String) {
        self.range = range
        self.sha256 = sha256
    }
}

// Computes checksums for use with incremental fetching.
public class ChecksumComputer {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "ChecksumComputer")

    public init() { }

    public static func memoryMapFile(file: URL) throws -> Data {
        return try Data(contentsOf: file, options: .dataReadingMapped)
    }

    public func convertHexSha256ToData(hexSha256: String,
                                       description: String) throws -> Data {
        guard let sha256OfChunk = Data(hexString: hexSha256) else {
            logger.error("\(description): Could not convert sha256 to Data from hex string, hex string: \(hexSha256)")
            throw CommonError.internalError
        }
        return sha256OfChunk
    }

    public static func computeSha256OfFileChunks(file: URL, chunks: [Range<Int>]) throws -> [RangeAndSha256] {
        let memoryMappedFile: Data = try ChecksumComputer.memoryMapFile(file: file)

        return ChecksumComputer.computeSha256OfDataChunks(data: memoryMappedFile, chunks: chunks)
    }

    public func computeSha256OfDataChunk(data: Data) throws -> String {
        let chunk = Range(uncheckedBounds: (0, data.count))
        let checksums = ChecksumComputer.computeSha256OfDataChunks(data: data, chunks: [chunk])
        guard checksums.count == 1 else {
            logger.error("Received != 1 checksums when computing checksum of single data chunk, this many: \(checksums.count)")
            throw CommonError.internalError
        }
        return checksums[0].sha256
    }

    public static func computeSha256OfDataChunks(data: Data, chunks: [Range<Int>]) -> [RangeAndSha256] {
        return chunks.map { (chunkRange) -> RangeAndSha256 in
            return RangeAndSha256(range: chunkRange, sha256: SHA256.hash(data: data.subdata(in: chunkRange)).hexDigest())
        }
    }
}

extension SHA256.Digest {
    func hexDigest() -> String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}
