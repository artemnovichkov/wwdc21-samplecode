/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class that conains methods for tone generation.
*/

import AVFoundation
import Accelerate

// The `AudioUtilities` structure provides a single function that returns an
// array of single-precision values from an audio resource.
struct AudioUtilities {
    
    // The `getAudioSamples` function returns the naturtal time scale and
    // an array of single-precision values that represent an audio resource.
    static func getAudioSamples(forResource: String,
                                withExtension: String) -> (naturalTimeScale: CMTimeScale,
                                                           data: [Float])? {

        guard let path = Bundle.main.url(forResource: forResource,
                                         withExtension: withExtension) else {
                                            return nil
        }
        
        let asset = AVAsset(url: path.absoluteURL)
        
        guard
            let reader = try? AVAssetReader(asset: asset),
            let track = asset.tracks.first else {
                return nil
        }
        
        let outputSettings: [String: Int] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVNumberOfChannelsKey: 1,
            AVLinearPCMIsBigEndianKey: 0,
            AVLinearPCMIsFloatKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsNonInterleaved: 1
        ]
        
        let output = AVAssetReaderTrackOutput(track: track,
                                              outputSettings: outputSettings)

        reader.add(output)
        reader.startReading()
        
        var samplesData = [Float]()
        
        while reader.status == .reading {
            if
                let sampleBuffer = output.copyNextSampleBuffer(),
                let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                
                let bufferLength = CMBlockBufferGetDataLength(dataBuffer)
                let count = bufferLength / 4
     
                let data = [Float](unsafeUninitializedCapacity: count) {
                    buffer, initializedCount in
                    
                    CMBlockBufferCopyDataBytes(dataBuffer,
                                               atOffset: 0,
                                               dataLength: bufferLength,
                                               destination: buffer.baseAddress!)
                    
                    initializedCount = count
                }
   
                samplesData.append(contentsOf: data)
            }
        }

        return (naturalTimeScale: track.naturalTimeScale,
                data: samplesData)
    }
}

// The `SignalGenerator` class renders the signal that a `SignalProvider`
// instance provides as audio.
class SignalGenerator {
    private let engine = AVAudioEngine()
    
    // The `page` array contains the current page of single-precision audio samples.
    private var page = [Float]()
    
    // The `signalProvider` property defines the instance that provides audio
    // samples.
    private let signalProvider: SignalProvider

    // The `sampleRate` property defines the sample rate for the input and output
    // format.
    let sampleRate: CMTimeScale
    
    private lazy var format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate),
                                            channels: 1)
    
    // The `sourceNode` requests audio data from the signal provider and supplies
    // the audio data to the audio engine for rendering.
    private lazy var sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let audioBufferListPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

        // Fade in volume after `engine.start()`.
        if self.engine.mainMixerNode.outputVolume <= 0.5 {
            self.engine.mainMixerNode.outputVolume += 0.1 * self.engine.mainMixerNode.outputVolume
        }
        
        for frame in 0..<Int(frameCount) {
            let value = self.getSignalElement()
            
            for buffer in audioBufferListPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = value
            }
        }
        return noErr
    }
    
    // The `SignalGenerator.init(signalProvider:)` initializer creates a new
    // `SignalGenerator` instance and connects the source node, the main mixer
    //  node, and the output node.
    init(signalProvider: SignalProvider) {
        self.signalProvider = signalProvider
        self.sampleRate = signalProvider.sampleRate
        
        engine.attach(sourceNode)
        
        engine.connect(sourceNode,
                       to: engine.mainMixerNode,
                       format: format)
        
        engine.connect(engine.mainMixerNode,
                       to: engine.outputNode,
                       format: format)
        
        engine.mainMixerNode.outputVolume = 0
        engine.prepare()
    }
    
    public func start() throws {
        engine.mainMixerNode.outputVolume = 1e-4
        try engine.start()
    }

    private func getSignalElement() -> Float {
        if page.isEmpty {
            page = signalProvider.getSignal()
        }
        
        return page.isEmpty ? 0 : page.removeFirst()
    }
    
    deinit {
        engine.stop()
    }
}

protocol SignalProvider {
    func getSignal() -> [Float]
    var sampleRate: CMTimeScale { get }
}
