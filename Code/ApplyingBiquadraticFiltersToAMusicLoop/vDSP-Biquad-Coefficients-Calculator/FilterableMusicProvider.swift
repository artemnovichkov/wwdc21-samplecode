/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The class that provides a signal that represents a music loop.
*/

import Accelerate
import Combine

// A `FilterableMusicProvider` instance provides the music loop and exposes an
// API to filter the music loop using a biquadratic filter.
class FilterableMusicProvider: ObservableObject {

    // A `Parameters` instance contains the mutable parameters that the sample
    // code app displays in the user interface.
    class Parameters {
        init(filterType: BiquadCoefficientCalculator.FilterType = .passthrough,
             frequency: Float = 2000.0,
             Q: Float = 1 / sqrt(2),
             dbGain: Float = 0) {
            self.filterType = filterType
            self.frequency = frequency
            self.Q = Q
            self.dbGain = dbGain
        }
        
        // The `filterType` variable defines the biquadratic filter's type,
        // such as low pass or notch.
        var filterType: BiquadCoefficientCalculator.FilterType
        
        // The `frequency` variable defines the biquadratic filter's center
        // frequency.
        var frequency: Float
        
        // The `Q` variable controls the width of the biquadratic filter's effect.
        var Q: Float
        
        // The `dbGain` variable controls the biquadratic filter's gain for
        // the `.peakingEQ` filter type.
        var dbGain: Float
    }
    
    // MARK: Static Properties
    
    static let sampleCount = 1024
    
    // MARK: Published Properties
    
    // The app displays the frequency domain representations of the music loop
    // before and after it applies the biquadratic filter using the values in
    // `frequencyDomainInputValues` and `frequencyDomainOutputValues`.
    @Published var frequencyDomainInputValues = [Float](repeating: 0,
                                                        count: sampleCount)
    @Published var frequencyDomainOutputValues = [Float](repeating: 0,
                                                         count: sampleCount)
    
    // The app displays the magnitude response of the biquadratic filter using
    // the values in `magnitudeResponseValues`.
    @Published var magnitudeResponseValues = [Float](repeating: 0,
                                                     count: sampleCount)
    
    // The app displays the magnitude response of the selected section using
    // the values in `selectedSectionResponseValues`.
    @Published var selectedSectionResponseValues = [Float](repeating: 0,
                                                           count: sampleCount)
    
    @Published var selectedSectionIndex = 0 {
        didSet {
            let magnitude = magnitudeResponseCalculator.response(
                for: selectedSectionCoefficients)
            
            selectedSectionResponseValues = vDSP.amplitudeToDecibels(magnitude,
                                                                     zeroReference: 1)
        }
    }
    
    // The `parameters` structure encapsulates the user-defined parameters.
    @Published var parameters: [Parameters] {
        didSet {
            updateCoefficients = true
        }
    }

    // MARK: Public Properties
    
    public var sampleRate: Int32
    
    // The `coefficients` structure contains the five coefficients (`b₀`, `b₁`,
    // `b₂`, `a₁`, and `a₂`) for the frequency, Q, and db gain that the sample
    // defines in the user interface.
    public var selectedSectionCoefficients: BiquadCoefficientCalculator.SectionCoefficients {
        return BiquadCoefficientCalculator.coefficients(
            for: parameters[selectedSectionIndex],
               sampleRate: sampleRate)
    }
    
    // MARK: Private Properties
    
    // The `FilterableMusicProvider` declares the `updateCoefficients` Boolean
    // value to indicate when one of the parameters changes. When
    // `updateCoefficients` is `true`, the app recalculates the coefficients and
    // updates the biquadratic filter.
    private var updateCoefficients = false

    // The `biquadSectionCount` constant defines the number of sections that
    // the biquadratic filter implements.
    public let biquadSectionCount = vDSP_Length(3)
    
    private var biquadSetup: vDSP_biquad_Setup
    private let magnitudeResponseCalculator: MagnitudeResponseCalculator
    private var delay: [Float]
    
    // The `FilterableMusicProvider` instance overwrites the `outputSignal`
    // array with the filtered audio signal.
    private var outputSignal = [Float](repeating: 0,
                                       count: sampleCount)

    // The `pageNumber` variable defines the current page of `sampleCount`
    // elements in `samples`.
    private var pageNumber = 0
        
    // The `samples` array contains the samples for the entire audio resource.
    private let samples: [Float]
    
    // MARK: Initializer
    
    // The `FilterableMusicProvider.init()` initializer returns a new
    // `FilterableMusicProvider` instance with a pass through the biquadratic
    // filter.
    init() {

        guard let samples = AudioUtilities.getAudioSamples(
            forResource: "MRS",
            withExtension: "aif") else {
            fatalError("Unable to parse the audio resource.")
        }

        self.samples = samples.data
        self.sampleRate = samples.naturalTimeScale
        
        parameters = (0 ..< biquadSectionCount).map { _ in
            Parameters()
        }
 
        let coefficients = [[Float]](
            repeating: BiquadCoefficientCalculator.passthroughCoefficients.array,
            count: Int(biquadSectionCount)).flatMap {
            $0
        }
    
        biquadSetup = vDSP_biquad_CreateSetup(vDSP.floatToDouble(coefficients),
                                              biquadSectionCount)!
        
        magnitudeResponseCalculator = MagnitudeResponseCalculator(sampleCount: Self.sampleCount)
        
        delay = [Float](repeating: 0,
                        count: 2 * Int(biquadSectionCount) + 2)
        
        setSelectedSectionCoefficients()
    }
    
    // MARK: Private Methods
    
    // The `setCoefficients` function calculates the magnitude response values
    // of the biquadratic filter and updates the filter's coefficients.
    private func setSelectedSectionCoefficients() {
        
        DispatchQueue.main.async { [self] in
            // The app displays the magnitude response for all sections as
            // the product of the individual magnitude responses of each section.
            
            var accumulator = [Float](repeating: 1, count: Self.sampleCount)
            
            for index in 0 ..< parameters.count {
                let params = parameters[index]
                
                let coeffs = BiquadCoefficientCalculator.coefficients(for: params,
                                                                      sampleRate: sampleRate)
                
                let magnitude = magnitudeResponseCalculator.response(for: coeffs)
                
                if index == selectedSectionIndex {
                    selectedSectionResponseValues = vDSP.amplitudeToDecibels(magnitude,
                                                                             zeroReference: 1)
                }
                
                vDSP.multiply(magnitude, accumulator,
                              result: &accumulator)
            }
            
            magnitudeResponseValues = vDSP.amplitudeToDecibels(accumulator,
                                                               zeroReference: 1)
        }

        vDSP_biquad_SetCoefficientsSingle(biquadSetup,
                                          selectedSectionCoefficients.array,
                                          vDSP_Length(selectedSectionIndex),
                                          1)
    }
    
    deinit {
        vDSP_biquad_DestroySetup(biquadSetup)
    }
}

// MARK: SignalProvider Extension

extension FilterableMusicProvider: SignalProvider {
    // The `FilterableMusicProvider.getSignal()` function returns a page
    // containing `sampleCount` samples from the `samples` array, and increments
    // `pageNumber`.
    func getSignal() -> [Float] {
        let start = pageNumber * Self.sampleCount
        let end = (pageNumber + 1) * Self.sampleCount
   
        let page = Array(samples[start ..< end])
        
        pageNumber += 1
        
        if (pageNumber + 1) * Self.sampleCount >= samples.count {
            pageNumber = 0
        }

        vDSP_biquad(biquadSetup,
                    &delay,
                    page, 1,
                    &outputSignal, 1,
                    vDSP_Length(Self.sampleCount))

        if updateCoefficients {
            setSelectedSectionCoefficients()
            updateCoefficients = false
        }
        
        DispatchQueue.main.async {
            Self.makeFrequencyDomainWaveform(source: page,
                                             destination: &self.frequencyDomainInputValues)
            Self.makeFrequencyDomainWaveform(source: self.outputSignal,
                                             destination: &self.frequencyDomainOutputValues)
        }

        return outputSignal
    }
    
    private static let dct = vDSP.DCT(count: sampleCount, transformType: .II)!
    
    // The `makeFrequencyDomainWaveform(source:destination:)` function populates
    // the destination array with an animated frequency domain representation of
    // the specified source.
    //
    // The function calls `linearInterpolate(_:_:using:result:)`, which returns
    // a weighted average of the existing values in `destination` and `input`.
    //
    // This averaging step provides a visual delay or animation effect to the
    // waveform that the app displays in the user interface.
    private static func makeFrequencyDomainWaveform(source: [Float],
                                                    destination: inout [Float]) {
        var input = dct.transform(source)
        vDSP.absolute(input, result: &input)
        vDSP.add(1, input, result: &input)
        vForce.log10(input, result: &input)
        
        vDSP.linearInterpolate(input,
                               destination,
                               using: 0.8,
                               result: &destination)
    }
}
