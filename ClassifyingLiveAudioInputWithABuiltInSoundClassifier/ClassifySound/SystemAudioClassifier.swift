/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class for listening to live system audio input, and for performing sound
classification using Sound Analysis.
*/

import Foundation
import AVFoundation
import SoundAnalysis
import Combine

/// A class for performing sound classification that the app interacts with through a singleton instance.
///
/// This class manages the app's audio session, so it's important to avoid adding audio behavior outside of
/// this instance. When the session is inactive, many instance variables assume a `nil` value, and
/// non-`nil` when the singleton is in an active state.
final class SystemAudioClassifier: NSObject {
    /// An enumeration that represents the error conditions that the class emits.
    ///
    /// This class emits classification results and errors through the subject you specify when calling
    /// `startSoundClassification`. The Sound Analysis framework provides most error conditions,
    /// but there are a few where this class generates an error.
    enum SystemAudioClassificationError: Error {

        /// The app encounters an interruption during audio recording.
        case audioStreamInterrupted

        /// The app doesn't have permission to access microphone input.
        case noMicrophoneAccess
    }

    /// A dispatch queue to asynchronously perform analysis on.
    private let analysisQueue = DispatchQueue(label: "com.example.apple-samplecode.classifying-sounds.AnalysisQueue")

    /// An audio engine the app uses to record system input.
    private var audioEngine: AVAudioEngine?

    /// An analyzer that performs sound classification.
    private var analyzer: SNAudioStreamAnalyzer?

    /// An array of sound analysis observers that the class stores to control their lifetimes.
    ///
    /// To perform sound classification, the app registers an observer and a request with an analyzer. While
    /// registered, the analyzer claims a strong reference on the request and not on the observer. It's the
    /// responsibility of the caller to handle the observer's lifetime. When sound classification isn't active,
    /// the variable is `nil`, freeing the observers from memory.
    private var retainedObservers: [SNResultsObserving]?

    /// A subject to deliver sound classification results to, including an error, if necessary.
    private var subject: PassthroughSubject<SNClassificationResult, Error>?

    /// Initializes a SystemAudioClassifier instance, and marks it as private because the instance operates as a singleton.
    private override init() {}

    /// A singleton instance of the SystemAudioClassifier class.
    static let singleton = SystemAudioClassifier()

    /// Requests permission to access microphone input, throwing an error if the user denies access.
    private func ensureMicrophoneAccess() throws {
        var hasMicrophoneAccess = false
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            let sem = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { success in
                hasMicrophoneAccess = success
                sem.signal()
            })
            _ = sem.wait(timeout: DispatchTime.distantFuture)
        case .denied, .restricted:
            break
        case .authorized:
            hasMicrophoneAccess = true
        @unknown default:
            fatalError("unknown authorization status for microphone access")
        }

        if !hasMicrophoneAccess {
            throw SystemAudioClassificationError.noMicrophoneAccess
        }
    }

    /// Configures and activates an AVAudioSession.
    ///
    /// If this method throws an error, it calls `stopAudioSession` to reverse its effects.
    private func startAudioSession() throws {
        stopAudioSession()
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            stopAudioSession()
            throw error
        }
    }

    /// Deactivates the app's AVAudioSession.
    private func stopAudioSession() {
        autoreleasepool {
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setActive(false)
        }
    }

    /// Starts observing for audio recording interruptions.
    private func startListeningForAudioSessionInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: nil)
    }

    /// Stops observing for audio recording interruptions.
    private func stopListeningForAudioSessionInterruptions() {
        NotificationCenter.default.removeObserver(
          self,
          name: AVAudioSession.interruptionNotification,
          object: nil)
        NotificationCenter.default.removeObserver(
          self,
          name: AVAudioSession.mediaServicesWereLostNotification,
          object: nil)
    }

    /// Handles notifications the system emits for audio interruptions.
    ///
    /// When an interruption occurs, the app notifies the subject of an error. The method terminates sound
    /// classification, so restart it to resume classification.
    ///
    /// - Parameter notification: A notification the system emits that indicates an interruption.
    @objc
    private func handleAudioSessionInterruption(_ notification: Notification) {
        let error = SystemAudioClassificationError.audioStreamInterrupted
        subject?.send(completion: .failure(error))
        stopSoundClassification()
    }
    
    /// Starts sound analysis of the system's audio input.
    ///
    /// This method configures AVAudioSession, and begins recording and classifying sounds for it. If
    /// an error occurs, it calls the `stopAnalyzing` method to reset the state.
    ///
    /// - Parameter requestsAndObservers: A list of pairs that contains an analysis request to
    ///   register, and an observer to send results to. The system retains both the requests and the observers
    ///   during analysis.
    private func startAnalyzing(_ requestsAndObservers: [(SNRequest, SNResultsObserving)]) throws {
        stopAnalyzing()

        do {
            try startAudioSession()

            try ensureMicrophoneAccess()

            let newAudioEngine = AVAudioEngine()
            audioEngine = newAudioEngine

            let busIndex = AVAudioNodeBus(0)
            let bufferSize = AVAudioFrameCount(4096)
            let audioFormat = newAudioEngine.inputNode.outputFormat(forBus: busIndex)

            let newAnalyzer = SNAudioStreamAnalyzer(format: audioFormat)
            analyzer = newAnalyzer

            try requestsAndObservers.forEach { try newAnalyzer.add($0.0, withObserver: $0.1) }
            retainedObservers = requestsAndObservers.map { $0.1 }

            newAudioEngine.inputNode.installTap(
              onBus: busIndex,
              bufferSize: bufferSize,
              format: audioFormat,
              block: { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                  self.analysisQueue.async {
                      newAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
                  }
              })

            try newAudioEngine.start()
        } catch {
            stopAnalyzing()
            throw error
        }
    }

    /// Stops the active sound analysis and resets the state of the class.
    private func stopAnalyzing() {
        autoreleasepool {
            if let audioEngine = audioEngine {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }

            if let analyzer = analyzer {
                analyzer.removeAllRequests()
            }

            analyzer = nil
            retainedObservers = nil
            audioEngine = nil
        }
        stopAudioSession()
    }

    /// Classifies system audio input using the built-in classifier.
    ///
    /// - Parameters:
    ///   - subject: A subject publishes the results of the sound classification. The subject receives
    ///   notice when classification terminates. A caller may attach subscribers to the subject before or
    ///   after calling this method. By attaching after, you may miss errors if classification fails to start.
    ///   - inferenceWindowSize: The amount of audio, in seconds, to account for in each
    ///   classification prediction. As this value grows, the accuracy may increase for longer sounds that
    ///   need more context to identify. However, delays also increase between the moment a sound
    ///   occurs and the moment that a sound produces a classification. This is because the system needs
    ///   to collect enough audio to gather the amount of context necessary to produce a prediction.
    ///   Increased accuracy is a trade-off for the responsiveness of a live classification app.
    ///   - overlapFactor: A ratio that indicates what part of an audio window overlaps with an
    ///   adjacent audio window. A value of 0.5 indicates that the audio for two consecutive predictions
    ///   overlaps so that the last 50% of the first duration serves as the first 50% of the second
    ///   duration. The factor determines the stride between consecutive durations of audio that produce
    ///   sound classification. As the factor increases, the stride decreases. As the stride decreases, the
    ///   system produces more predictions. So, at the computational expense of producing more predictions,
    ///   decreasing the stride by raising the overlap factor can improve perceived responsiveness.
    func startSoundClassification(subject: PassthroughSubject<SNClassificationResult, Error>,
                                  inferenceWindowSize: Double,
                                  overlapFactor: Double) {
        stopSoundClassification()

        do {
            let observer = ClassificationResultsSubject(subject: subject)

            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(inferenceWindowSize, preferredTimescale: 48_000)
            request.overlapFactor = overlapFactor

            self.subject = subject

            startListeningForAudioSessionInterruptions()
            try startAnalyzing([(request, observer)])
        } catch {
            subject.send(completion: .failure(error))
            self.subject = nil
            stopSoundClassification()
        }
    }

    /// Stops any active sound classification task.
    func stopSoundClassification() {
        stopAnalyzing()
        stopListeningForAudioSessionInterruptions()
    }

    /// Emits the set of labels producible by sound classification.
    ///
    ///  - Returns: The set of all labels that sound classification emits.
    static func getAllPossibleLabels() throws -> Set<String> {
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        return Set<String>(request.knownClassifications)
    }
}
