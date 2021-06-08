/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The Conversation class that manages the AVSpeechSynthesizer implementation.
 This implementation is separate from the view controller to be able to modify
 speech details quickly and clearly.
*/

import Foundation
import AVFoundation

class Conversation: NSObject, AVSpeechSynthesizerDelegate {
    
    var lines = [AVSpeechUtterance]()
    var quotes = [Quote]()
    var index = 0
    
    let speaker = NSNotification.Name("AVSpeakerData")
    let line = NSNotification.Name("AVLineData")
    
    override init() {
        super.init()
        // Make the Conversation class in charge of handling the AVSpeechSynthesizer responsibilities.
        synthesizer.delegate = self
        let script = ScriptReader()
        quotes = script.parseFile()
    }
    
    let synthesizer = AVSpeechSynthesizer()
    
    func speakNow() {
        // Iterate through all the quotes parsed from the script.
        for quote in quotes {
            let speech = prepareLine(quote: quote)
            synthesizer.speak(speech)
        }
    }
    
    func prepareLine(quote: Quote) -> AVSpeechUtterance {
        // Initialize defaults.
        let utterance = AVSpeechUtterance(string: quote.line)
        var voice = AVSpeechSynthesisVoice(language: "en")
        var rate: Float = 0.7
        var pitchMultiplier: Float = 0.8
        var preUtteranceDelay: Double = 0.05
        var utteranceVolume: Float = 1.0
        
        print(quote.speaker)
        
        // Configure your speakers here.
        if quote.speaker == "Bob" {
            voice = AVSpeechSynthesisVoice(identifier: "Alex")
            rate = 0.05
            pitchMultiplier = 0.7
            preUtteranceDelay = 0.1
            utteranceVolume = 2.0
        } else {
            voice = AVSpeechSynthesisVoice(identifier: "Samantha")
            rate = 0.7
            //pitchMultiplier = 0.75
        }
        
        // For each utterance, assign specific qualities
        // before queueing the utterance. This approach allows
        // using a single synthesizer instance to create
        // the effect of two separate speakers.
        utterance.voice = voice
        utterance.rate = rate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.preUtteranceDelay = preUtteranceDelay
        utterance.volume = utteranceVolume
        
        return utterance
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart: AVSpeechUtterance) {
        
        if index < quotes.count {
            // As long as there are lines to read, continue notifying the view to reflect the current
            // speaker name and script line.
            NotificationCenter.default.post(name: speaker, object: "\(quotes[index].speaker)")
            NotificationCenter.default.post(name: line, object: "\(quotes[index].line)")
        } else {
            index = 0
            return
        }
        
        index += 1
    }
    
    func resetAll() {
        synthesizer.stopSpeaking(at: .immediate)
        index = 0
        
        // Post a notification to inform the view to change the subtitles.
        NotificationCenter.default.post(name: speaker, object: "Speaker names will appear here.")
        NotificationCenter.default.post(name: line, object: "Speaker subtitles will appear here. Press play to start the conversation.")
    }
}

