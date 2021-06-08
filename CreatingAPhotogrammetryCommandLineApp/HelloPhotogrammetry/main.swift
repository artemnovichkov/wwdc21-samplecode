/*
See LICENSE folder for this sample’s licensing information.

Abstract:
RealityKit Object Creation command line tools.
*/

import ArgumentParser  // Available from Apple: https://github.com/apple/swift-argument-parser
import Combine
import Foundation
import os
import RealityKit

private typealias Configuration = PhotogrammetrySession.Configuration
private typealias Request = PhotogrammetrySession.Request

/// Implements the main command structure, defines the command-line arguments,
/// and specifies the main run loop.
struct HelloPhotogrammetry: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Reconstructs 3D USDZ model from a folder of images.")

    @Argument(help: "The local input file folder of images.")
    private var inputFolder: String

    @Argument(help: "Full path to the USDZ output file.")
    private var outputFilename: String

    @Option(name: .shortAndLong,
            parsing: .next,
            help: "detail {preview, reduced, medium, full, raw}  Detail of output model in terms of mesh size and texture size .",
            transform: Request.Detail.init)
    private var detail: Request.Detail? = nil

    @Option(name: [.customShort("l"), .long],
            parsing: .next,
            help: "sampleOverlap {normal, low}  It should be set to `low` if there is low overlap between images captured nearby in space.",
            transform: Configuration.SampleOverlap.init)
    private var sampleOverlap: Configuration.SampleOverlap?

    @Option(name: [.customShort("o"), .long],
            parsing: .next,
            help: "sampleOrdering {unordered, sequential}  Setting to sequential may speed up computation if images are captured in a spatially sequential pattern.",
            transform: Configuration.SampleOrdering.init)
    private var sampleOrdering: Configuration.SampleOrdering?

    @Option(name: .shortAndLong,
            parsing: .next,
            help: "featureSensitivity {normal, high}  Set to high if the scanned object does not contain a lot of discernible structures, edges or textures.",
            transform: Configuration.FeatureSensitivity.init)
    private var featureSensitivity: Configuration.FeatureSensitivity?
    
    /// The main run loop entered at the end of the file.
    func run() {
        let inputFolderUrl = URL(fileURLWithPath: inputFolder, isDirectory: true)
        let configuration = makeConfigurationFromArguments()
        print("Using configuration: \(String(describing: configuration))")

        // Try to create the session, or else exit.
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: inputFolderUrl,
                                                     configuration: configuration)
            print("Successfully created session.")
        } catch {
            print("Error creating session: \(String(describing: error))")
            Foundation.exit(1)
        }
        guard let session = maybeSession else {
            Foundation.exit(1)
        }

        // Connect the main Combine pipeline to process messages published to output.
        var subscriptions = Set<AnyCancellable>()
        session.output
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                var maybeError: Error? = nil
                if case .failure(let error) = completion {
                    print("Output: ERROR = \(String(describing: error))")
                    maybeError = error
                    Foundation.exit(maybeError != nil ? 0 : 1)
                }
            }, receiveValue: { output in
                switch output {
                case .processingComplete:
                    // All requests are done so you can safely exit.
                    print("Processing is complete!")
                    Foundation.exit(0)
                case .requestError(let request, let error):
                    print("Request \(String(describing: request)) had an error: \(String(describing: error))")
                case .requestComplete(let request, let result):
                    handleRequestComplete(request: request, result: result)
                case .requestProgress(let request, let fractionComplete):
                    handleRequestProgress(request: request, fractionComplete: fractionComplete)
                case .inputComplete:  // Data ingestion has finished.
                    print("Data ingestion is complete.  Beginning processing...")
                case .invalidSample(let id, let reason):
                    print("Invalid Sample! id=\(id)  reason=\"\(reason)\"")
                case .skippedSample(let id):
                    print("Sample id=\(id) was skipped by processing.")
                case .automaticDownsampling:
                    print("Automatic downsampling was applied!")
                default:
                    print("Output: unhandled message: \(output.localizedDescription)")
                }
            })
            .store(in: &subscriptions)
        
        // Compiler may deinitialize these objects since they may appear to be
        // unused. This keeps them from being deallocated until they exit.
        withExtendedLifetime((session, subscriptions)) {
            // Run the main process call on the request, then enter the main run
            // loop until you get the published completion event or error.
            do {
                let request = makeRequestFromArguments()
                print("Using request: \(String(describing: request))")
                try session.process(requests: [ request ])
                // Enter the infinite loop dispatcher used to process asynchronous
                // blocks on the main queue. You explicitly exit above to stop the loop.
                RunLoop.main.run()
            } catch {
                print("Process got error: \(String(describing: error))")
                Foundation.exit(1)
            }
        }
    }

    /// Creates the session configuration by overriding any defaults with arguments specified.
    private func makeConfigurationFromArguments() -> PhotogrammetrySession.Configuration {
        var configuration = PhotogrammetrySession.Configuration()
        sampleOverlap.map { configuration.sampleOverlap = $0 }
        sampleOrdering.map { configuration.sampleOrdering = $0 }
        featureSensitivity.map { configuration.featureSensitivity = $0 }
        return configuration
    }

    /// Creates a request to use based on the command-line arguments.
    private func makeRequestFromArguments() -> PhotogrammetrySession.Request {
        let outputUrl = URL(fileURLWithPath: outputFilename)
        if let detailSetting = detail {
            return PhotogrammetrySession.Request.modelFile(url: outputUrl, detail: detailSetting)
        } else {
            return PhotogrammetrySession.Request.modelFile(url: outputUrl)
        }
    }
}

// MARK: - Helper Functions / Extensions

/// Called when the the session sends a request completed message.
private func handleRequestComplete(request: PhotogrammetrySession.Request,
                                   result: PhotogrammetrySession.Result) {
    print("Request complete: \(String(describing: request)) with result...")
    switch result {
    case .modelFile(let url):
        print("\tmodelFile available at url=\(url)")
    default:
        print("\tUnexpected result: \(String(describing: result))")
    }
}

/// Called when the sessions sends a progress update message.
private func handleRequestProgress(request: PhotogrammetrySession.Request,
                                   fractionComplete: Double) {
    print("Progress(request = \(String(describing: request)) = \(fractionComplete)")
}

/// Error thrown when an illegal option is specified.
private enum IllegalOption: Swift.Error {
    case invalidDetail(String)
    case invalidSampleOverlap(String)
    case invalidSampleOrdering(String)
    case invalidFeatureSensitivity(String)
}

/// Extension to add a throwing initializer used as an option transform to verify the user-supplied arguments.
extension PhotogrammetrySession.Request.Detail {
    init(_ detail: String) throws {
        switch detail {
        case "preview": self = .preview
        case "reduced": self = .reduced
        case "medium": self = .medium
        case "full": self = .full
        case "raw": self = .raw
        default: throw IllegalOption.invalidDetail(detail)
        }
    }
}

extension PhotogrammetrySession.Configuration.SampleOverlap {
    init(sampleOverlap: String) throws {
        if sampleOverlap == "normal" {
            self = .normal
        } else if sampleOverlap == "low" {
            self = .low
        } else {
            throw IllegalOption.invalidSampleOrdering(sampleOverlap)
        }
    }
}

extension PhotogrammetrySession.Configuration.SampleOrdering {
    init(sampleOrdering: String) throws {
        if sampleOrdering == "unordered" {
            self = .unordered
        } else if sampleOrdering == "sequential" {
            self = .sequential
        } else {
            throw IllegalOption.invalidSampleOrdering(sampleOrdering)
        }
    }

}

extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    init(featureSensitivity: String) throws {
        if featureSensitivity == "normal" {
            self = .normal
        } else if featureSensitivity == "high" {
            self = .high
        } else {
            throw IllegalOption.invalidFeatureSensitivity(featureSensitivity)
        }
    }
}

// MARK: - Main

// Run the program until completion.
HelloPhotogrammetry.main()

