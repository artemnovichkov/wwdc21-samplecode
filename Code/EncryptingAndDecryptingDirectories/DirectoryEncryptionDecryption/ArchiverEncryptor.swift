/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The ArchiverEncryptor structure that's responsible for encrypting and decrypting directories.
*/


import Foundation
import System
import AppleArchive
import CryptoKit
import AppKit

extension SymmetricKey {
    // The `base64Encoded` computed property returns a string that contains
    // the Base64 encoded representation of the raw bytes of the key.
    var base64Encoded: String {
        return withUnsafeBytes { Data($0).base64EncodedString() }
    }
    
    // The `SymmetricKey.init(fromBase64EncodedString:)` initializer returns
    // a new symmetric cryptographic key from a Base64 encoded representation of
    // a key.
    init?(fromBase64EncodedString base64EncodedString: String) {
        guard let keyData = Data(base64Encoded: base64EncodedString) else {
            return nil
        }
        
        self = SymmetricKey(data: keyData)
    }
}

// The `ConsoleMessage` structure contains the information displayed to the
// user after an operation.
struct ConsoleMessage: Identifiable, Equatable {
    let id = UUID()
    let status: Status
    let message: String
    
    init(status: Status,
         message: String) {
        self.status = status
        self.message = message
    }
    
    var base64EncodedKeyData: String? {
        switch status {
            case .encryptionSuccess(let base64EncodedKeyData):
                return base64EncodedKeyData
            default:
                return nil
        }
    }
    
    static func == (lhs: ConsoleMessage, rhs: ConsoleMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum Status {
        case info
        case error
        case encryptionSuccess(base64EncodedKeyData: String)
        case decryptionSuccess
        
        var imageSystemName: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .error:
                return "xmark.octagon.fill"
            case .encryptionSuccess(_), .decryptionSuccess:
                return "checkmark.circle.fill"
            }
        }
    }
}

struct ArchiverEncryptor {

    // The app defines `directory` as the file system destination where it saves
    // encrypted archives and decrypted directories.
    static let directory = NSTemporaryDirectory()

    // The `static ArchiverEncryptor.encrypt(sourceURL:)` function encrypts and
    // archives the directory at the specified URL. The function writes the
    // result to `directory`. The archive shares the name of the directory at
    // `sourceURL` with an `aea` extension.
    static func encrypt(sourceURL: URL) -> ConsoleMessage {
        
        // Verify that the URL path represents a directory.
        guard sourceURL.hasDirectoryPath else {
            return ConsoleMessage(status: .error,
                                  message: "The specified URL doesn't point to a directory.")
        }

        guard let source = FilePath(sourceURL) else {
            return ConsoleMessage(status: .error,
                                  message: "Unable to create file path from source URL.")
        }

        // Create the destination `FilePath`.
        let destination = directory
            .appending(sourceURL.lastPathComponent)
            .appending(".aea")
        let archiveDestination = FilePath(destination)

        // Create the encryption context and setup credentials.
        let encryptionKey = SymmetricKey(size: .bits256)

        let context = ArchiveEncryptionContext(
            profile: .hkdf_sha256_aesctr_hmac__symmetric__none,
            compressionAlgorithm: .lzfse)
        do {
            try context.setSymmetricKey(encryptionKey)
        } catch {
            return ConsoleMessage(status: .error,
                                  message: "Error setting password (\(error)).")
        }

        // Create the file stream, encryption stream, archive encode stream.
        guard
            let archiveDestinationFileStream = ArchiveByteStream.fileStream(
                path: archiveDestination,
                mode: .writeOnly,
                options: [ .create, .truncate ],
                permissions: FilePermissions(rawValue: 0o644)),
            
                let encryptionStream = ArchiveByteStream.encryptionStream(
                    writingTo: archiveDestinationFileStream,
                    encryptionContext: context),
            
                let encoderStream = ArchiveStream.encodeStream(
                    writingTo: encryptionStream) else {
                    
                    return ConsoleMessage(status: .error,
                                          message: "Error creating streams.")
                }
        
        // Close the streams in the opposite order to which the function
        // created them.
        defer {
            try? encoderStream.close()
            try? encryptionStream.close()
            try? archiveDestinationFileStream.close()
        }

        // Encode all files in the target directory with the specifed fields.
        do {
            
            let fields = ArchiveHeader.FieldKeySet("TYP,PAT,DAT,UID,GID,MOD")!
            try encoderStream.writeDirectoryContents(archiveFrom: source,
                                                     keySet: fields)
        } catch {
            return ConsoleMessage(status: .error,
                                  message: "Error writing directory contents.")
        }
        
        if let url = URL(archiveDestination) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }

        let message = """
Encrypted with key '\(encryptionKey.base64Encoded)'.
Archived and encrypted to: \(archiveDestination.description).
"""
        
        return ConsoleMessage(status: .encryptionSuccess(base64EncodedKeyData: encryptionKey.base64Encoded),
                              message: message)
    }

    // The `static ArchiverEncryptor.decrypt(sourceURL:encryptionKey:)` function
    // decrypts and unarchives a directory archive at the specified URL. This
    // function writes the result to `directory`. The unarchived directory shares
    // the name of the supplied archive file with the `aea` extension removed.
    static func decrypt(sourceURL: URL,
                        encryptionKey: SymmetricKey) -> ConsoleMessage {

        guard let archiveSource = FilePath(sourceURL) else {
            return ConsoleMessage(status: .error,
                                  message: "Unable to create file path from source URL")
        }

        // Define the destination for the unarchived and decrypted directory.
        let destinationPath = directory.appending(sourceURL.deletingPathExtension().lastPathComponent)
        if !FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try FileManager.default.createDirectory(atPath: destinationPath,
                                                        withIntermediateDirectories: false)
            } catch {
                return ConsoleMessage(status: .error,
                                      message: "Unable to create destination directory.")
            }
        }
        let destinationDirectory = FilePath(destinationPath)

        // Create the encrypted source stream and encryption context.
        guard
            let sourceFileStream = ArchiveByteStream.fileStream(
              path: archiveSource,
              mode: .readOnly,
              options: [],
              permissions: []),
            
            let context = ArchiveEncryptionContext(from: sourceFileStream)
        else {
            return ConsoleMessage(status: .error,
                                  message: "Corrupted archive.")
        }

        // Set the symmetric key on the context.
        do {
            try context.setSymmetricKey(encryptionKey)
        } catch {
            return ConsoleMessage(status: .error,
                                  message: "Error setting password (\(error).)")
        }

        // Create the decryption and decoder streams.
        guard
            let decryptionStream = ArchiveByteStream.decryptionStream(
                readingFrom: sourceFileStream,
                encryptionContext: context),
            
            let decoderStream = ArchiveStream.decodeStream(
                readingFrom: decryptionStream) else {
                return ConsoleMessage(status: .error,
                                      message: "Error opening decryption stream.")
            }
        
        // Create the archive extraction stream.
        guard let extractStream = ArchiveStream.extractStream(extractingTo: destinationDirectory) else {
            return ConsoleMessage(status: .error,
                                  message: "Error opening extraction stream.")
        }

        // Close the streams.
        defer {
            try? sourceFileStream.close()
            try? decryptionStream.close()
            try? decoderStream.close()
            try? extractStream.close()
        }

        // Process all archive elements.
        var count = 0
        do {
            count = try ArchiveStream.process(readingFrom: decoderStream,
                                              writingTo: extractStream)
        } catch {
            return ConsoleMessage(status: .error,
                                  message: "Error processing archive elements.")
        }

        if let url = URL(destinationDirectory) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        
        let message = "Unarchived and decrypted \(count) elements to: \(destinationDirectory.description)"
        return ConsoleMessage(status: .decryptionSuccess,
                              message: message)
    }
    
}
