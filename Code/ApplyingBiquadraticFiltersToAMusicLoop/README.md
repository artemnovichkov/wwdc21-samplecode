# Applying Biquadratic Filters to a Music Loop

Change the frequency response of an audio signal using a cascaded biquadratic filter.

## Overview

The vDSP library provides single-channel and multichannel biquadratic filters that allow you to shape the output of an audio signal, such as by boosting or cutting the bass or treble of a music track. The biquadratic filters in the vDSP library are cascaded biquadratics, which means they support multiple sections where each section specifies a particular frequency response. 

The vDSP library defines a biquadratic filter from a set of five coefficients for each section. This sample code app calculates those coefficients from a set of properties that it displays as controls in the user interface. The user interface provides controls to select the filter type (such as low-pass or high-pass), the center frequency of the filter, and the Q value that controls the width of the filter's frequency band.

The sample code app displays the magnitude response of the selected section, the magnitude response of the entire filter, the frequency domain representation of the input signal, and the frequency domain representation of the filtered, output signal. 

![A screenshot of the sample app that includes four graphs. A dashed line graph indicates the magnitude response of the selected section. A solid line graph indicates the frequency domain representation of the original signal. A background filled line graph indicates the magnitude response of the biquadratic filter. A foreground filled line graph indicates the frequency domain representation of the filtered output.](Documentation/biquad-demo-overview.png)

Before exploring the code, try building and running the app to familiarize yourself with the effect of the different parameters on the music loop.

## Initialize the Biquadratic Filter

The `biquadSectionCount` constant defines the number of sections that the biquadratic filter implements. The sample code app sets this to `3` by default.

``` swift
public let biquadSectionCount = vDSP_Length(3)
```

The [`vDSP_biquad_CreateSetup`](https://developer.apple.com/documentation/accelerate/1450374-vdsp_biquad_createsetup) function returns a new biquadratic filter structure that contains `biquadSectionCount` sections. The sample code app defines the coefficients to produce a filter that returns an output that's identical to the input.

``` swift
let coefficients = [[Float]](
    repeating: BiquadCoefficientCalculator.passthroughCoefficients.array,
    count: Int(biquadSectionCount)).flatMap {
    $0
}

biquadSetup = vDSP_biquad_CreateSetup(vDSP.floatToDouble(coefficients),
                                      biquadSectionCount)!
```

## Define the Biquadratic Coefficients

Five coefficients define each section of a biquadratic filter. The following formula describes the underlying math of the biquadratic filter, with _z_ referring to the complex frequency-domain representation of the signal:

![A mathematical formula that describes the transfer function that the vDSP library uses for biquadratic filtering. Cap H open parentheses z close parentheses equals b sub zero, plus b sub 1 times z to the power of minus one, plus b sub 2 times z to the power of minus two, over one plus a sub 1 times z to the power of minus one, plus a sub 2 times z to the power of minus 2.](Documentation/biquad_formula.png)

The sample code app includes the `BiquadCoefficientCalculator` structure that provides the `static BiquadCoefficientCalculator.coefficients(for:sampleRate:)` function. This function returns the five coefficients for a filter type, center frequency, Q, and sample rate.

Each filter type uses the same shared values.

``` swift
let omega = 2.0 * .pi * frequency / Float(sampleRate)
let sinOmega = sin(omega)
let alpha = sinOmega / (2 * Q)
let cosOmega = cos(omega)
```

A `switch` statement calculates the coefficients for each filter type case. For example, the following code calculates the coefficients for a low-pass filter (that reduces high frequencies):

``` swift
case .lowpass:
    b0 = (1 - cosOmega) / 2
    b1 = 1 - cosOmega
    b2 = (1 - cosOmega) / 2
    a0 = 1 + alpha
    a1 = -2 * cosOmega
    a2 = 1 - alpha
```

## Set the Biquadratic Coefficients

The `vDSP_biquad_SetCoefficientsSingle` function sets the coefficients for a section of the biquadratic filter. The sample code app defines `selectedSectionIndex` as the index of the currently selected section, and the `BiquadCoefficientCalculator.SectionCoefficients` structure provides an `array` variable that returns `[b0, b1, b2, a1, a2]`.

``` swift
vDSP_biquad_SetCoefficientsSingle(biquadSetup,
                                  selectedSectionCoefficients.array,
                                  vDSP_Length(selectedSectionIndex),
                                  1)
```

## Apply the Biquadratic Filter to the Audio Sample

The [`vDSP_biquad(_:_:_:_:_:_:_:)`](https://developer.apple.com/documentation/accelerate/1450838-vdsp_biquad) function applies the biquadratic filter to a page of input samples and writes the result to the `outputSignal` array. The `delay` array contains the past state for each section of the biquadratic filter.

``` swift
vDSP_biquad(biquadSetup,
            &delay,
            page, 1,
            &outputSignal, 1,
            vDSP_Length(Self.sampleCount))
```

On return, `outputSignal` contains the filtered version of `page`, and `delay` contains the final state data of the filter. The sample code app passes `delay` to the next call of [`vDSP_biquad(_:_:_:_:_:_:_:)`].
