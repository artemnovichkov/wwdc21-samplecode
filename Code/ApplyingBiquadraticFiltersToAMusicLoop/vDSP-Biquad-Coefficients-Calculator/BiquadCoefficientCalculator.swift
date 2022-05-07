/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A structure that calculates the biquadratic coefficients for a specified center frequency and Q value.
*/

import Accelerate

// The `BiquadCoefficientCalculator` structure provides a single function that
// returns a set of biquadratic filter coefficients from a center frequency, Q,
// and — in the case of a peak EQ filter — a db gain.
struct BiquadCoefficientCalculator {
    
    // The `FilterType` enumeration defines the filter types that the
    // coefficient calculator supports.
    enum FilterType: String, CaseIterable, Identifiable {
        case passthrough = "Pass Through"
        case lowpass = "Low Pass"
        case highpass = "High Pass"
        case bandpass = "Band Pass"
        case notch = "Notch"
        case peakingEQ = "Peaking EQ"
        
        var id: String { self.rawValue }
    }
    
    // The `SectionCoefficients` structure contains the five biquadratic filter
    // coefficients.
    struct SectionCoefficients: CustomStringConvertible {
        var description: String {
            return """
    b₀: \(b0)
    b₁: \(b1)
    b₂: \(b2)
    a₁: \(a1)
    a₂: \(a2)
    """
        }
        
        let b0: Float
        let b1: Float
        let b2: Float
        let a1: Float
        let a2: Float
        
        var array: [Float] {
            return [b0, b1, b2, a1, a2]
        }
    }
    
    // The `passthroughCoefficients(for:)` function returns a set of biquadratic
    // filter coefficients that generate a passthrough filter.
    static var passthroughCoefficients: SectionCoefficients {
        return SectionCoefficients(b0: 1, b1: 0, b2: 0, a1: 0, a2: 0)
    }
    
    // The `coefficients(for:frequency:Q:dBgain:sampleRate:)` function returns
    // the coefficients from a center frequency, Q, and, in the case of a peak
    // EQ filter, a decibel gain.
    static func coefficients(for parameters: FilterableMusicProvider.Parameters,
                             sampleRate: Int32) -> SectionCoefficients {
        
        let filterType = parameters.filterType
        let frequency = parameters.frequency
        let Q = parameters.Q
        let dbGain = parameters.dbGain
        
        let omega = 2.0 * .pi * frequency / Float(sampleRate)
        let sinOmega = sin(omega)
        let alpha = sinOmega / (2 * Q)
        let cosOmega = cos(omega)
        
        let b0: Float
        let b1: Float
        let b2: Float
        let a0: Float
        let a1: Float
        let a2: Float
        
        switch filterType {
        case .passthrough:
            
            let coefficients = passthroughCoefficients
            b0 = coefficients.b0
            b1 = coefficients.b1
            b2 = coefficients.b2
            a0 = 1
            a1 = coefficients.a1
            a2 = coefficients.a2
            
        case .lowpass:
            b0 = (1 - cosOmega) / 2
            b1 = 1 - cosOmega
            b2 = (1 - cosOmega) / 2
            a0 = 1 + alpha
            a1 = -2 * cosOmega
            a2 = 1 - alpha
            
        case .highpass:
            b0 = (1 + cosOmega) / 2
            b1 = -(1 + cosOmega)
            b2 = (1 + cosOmega) / 2
            a0 = 1 + alpha
            a1 = -2 * cosOmega
            a2 = 1 - alpha
            
        case .bandpass:
            b0 = alpha
            b1 = 0.0
            b2 = -alpha
            a0 = 1 + alpha
            a1 = -2 * cosOmega
            a2 = 1 - alpha
            
        case .notch:
            b0 = 1.0
            b1 = -2 * cosOmega
            b2 = 1.0
            a0 = 1 + alpha
            a1 = -2 * cosOmega
            a2 = 1 - alpha
            
        case .peakingEQ:
            let A = pow(10.0, dbGain / 40)
            
            b0 = 1 + alpha * A
            b1 = -2 * cosOmega
            b2 = 1 - alpha * A
            a0 = 1 + alpha / A
            a1 = -2 * cosOmega
            a2 = 1 - alpha / A
        }
        
        return SectionCoefficients(b0: b0 / a0,
                                   b1: b1 / a0,
                                   b2: b2 / a0,
                                   a1: a1 / a0,
                                   a2: a2 / a0)
    }
}
