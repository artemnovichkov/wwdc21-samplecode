/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility class for chunking up a file for incremental fetching.
*/

import Foundation
import Common
import os.log

public class FileChunker {
    private let logger = Logger(subsystem: "com.example.apple-samplecode.FruitBasket", category: "FileChunker")

    public func chunkFile(file: URL,
                          minChunkSize: Int,
                          maxChunkSize: Int) throws -> [Range<Int>] {
        let memoryMappedFile = try ChecksumComputer.memoryMapFile(file: file)
        let chunks = self.chunk(memoryMappedFile, minChunkSize: minChunkSize, maxChunkSize: maxChunkSize)
        logger.info("completed chunking file into \(chunks.count) chunks at URL \(file), chunk details: \(chunks)")
        return chunks
    }

    public func chunkFile(file: URL) throws -> [Range<Int>] {
        let minChunkSize = FileChunker.minChunkSize()
        let maxChunkSize = FileChunker.maxChunkSize()
        return try self.chunkFile(file: file, minChunkSize: minChunkSize, maxChunkSize: maxChunkSize)
    }

    public func chunkData(data: Data) throws -> [Range<Int>] {
        let minChunkSize = FileChunker.minChunkSize()
        let maxChunkSize = FileChunker.maxChunkSize()
        return self.chunk(data, minChunkSize: minChunkSize, maxChunkSize: maxChunkSize)
    }

    private static func minChunkSize() -> Int {
        // A 16 MB minimum chunk size.
        return 16 * 1024 * 1024
    }

    private static func maxChunkSize() -> Int {
        // A 64 MB maximum chunk size.
        return 64 * 1024 * 1024
    }

    private func chunk(_ data: Data, minChunkSize: Int, maxChunkSize: Int) -> [Range<Int>] {
        var checksum = Checksum()

        guard !data.isEmpty else {
            // Guard against uploading 0 byte chunks and use an empty range.
            return []
        }

        var chunks = [Range<Int>]()

        // Reserve space for the maximum amount of possible chunks.
        let expectedNumChunks = data.count / minChunkSize
        chunks.reserveCapacity(expectedNumChunks)

        let sumLengthBits = Int(log2(Double(minChunkSize)))

        let length = 1 << (sumLengthBits + 1)
        var previousChunk = 0

        data.withUnsafeBytes { (buffer) -> Void in
            for idx in 0..<buffer.count {
                checksum.rollIn(buffer[idx])
                if idx > length {
                    checksum.rollOut(buffer[idx - length])
                }

                let currentChunkSize = idx - previousChunk
                let chunkBigEnough = currentChunkSize > minChunkSize
                let digest = checksum.digest
                let foundChunkBoundary = chunkBigEnough && (digest % (1 << sumLengthBits)) == 0
                let chunkTooBig = currentChunkSize > maxChunkSize

                if foundChunkBoundary || chunkTooBig {
                    logger.info("found file chunk, digest = \(digest), foundChunkBoundary = \(foundChunkBoundary), chunkTooBig = \(chunkTooBig)")
                    chunks.append(Range(uncheckedBounds: (previousChunk, idx)))
                    previousChunk = idx
                }
            }
        }
        chunks.append(Range(uncheckedBounds: (previousChunk, data.count)))

        return chunks
    }
}

private struct Checksum {
    private var sum: Int = 0

    @inline(__always)
    mutating func rollIn(_ val: UInt8) {
        sum += Int(val)
    }
    
    @inline(__always)
    mutating func rollOut(_ val: UInt8) {
        sum -= Int(val)
    }

    @inline(__always)
    var digest: Int {
        return sum
    }
}
