/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The model that is responsible for matching against the catalog and update the SwiftUI Views.
*/

import ShazamKit
import AVFAudio
import Combine

struct MatchResult: Equatable {
    let mediaItem: SHMatchedMediaItem?
    let question: Question?
    
    static func == (lhs: MatchResult, rhs: MatchResult) -> Bool {
        return lhs.question == rhs.question
    }
}

class Matcher: NSObject, ObservableObject, SHSessionDelegate {
    @Published var result = MatchResult(mediaItem: nil, question: nil)
    
    private var session: SHSession?
    private let audioEngine = AVAudioEngine()
    
    func match(catalog: SHCustomCatalog) throws {
        
        session = SHSession(catalog: catalog)
        session?.delegate = self
        
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: audioEngine.inputNode.outputFormat(forBus: 0).sampleRate,
                                        channels: 1)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: audioFormat) { [weak session] buffer, audioTime in
            session?.matchStreamingBuffer(buffer, at: audioTime)
        }
        
        try AVAudioSession.sharedInstance().setCategory(.record)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] success in
            guard success, let self = self else { return }
            try? self.audioEngine.start()
        }
    }
    
    func session(_ session: SHSession, didFind match: SHMatch) {
        DispatchQueue.main.async {
            
            // Find the Question from all the questions that we want to show.
            // In this example, use the last Question that's after the current match offset.
            let newQuestion = Question.allQuestions.last { question in
                (match.mediaItems.first?.predictedCurrentMatchOffset ?? 0) > question.offset
            }
            
            // Filter out similar Question objects in case of similar matches and update matchResult.
            if let currentQuestion = self.result.question, currentQuestion == newQuestion {
                return
            }
            
            self.result = MatchResult(mediaItem: match.mediaItems.first, question: newQuestion)
        }
    }
}
