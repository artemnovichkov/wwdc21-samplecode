/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view for visualizing the confidence with which the system is detecting sounds
from the audio input.
*/

import Foundation
import SwiftUI

///  Provides a visualization the app uses when detecting sounds.
struct DetectSoundsView: View {
    /// The runtime state that contains information about the strength of the detected sounds.
    @ObservedObject var state: AppState

    /// The configuration that dictates aspects of sound classification, as well as aspects of the visualization.
    @Binding var config: AppConfiguration

    /// An action to perform when the user requests to edit the app's configuration.
    let configureAction: () -> Void

    /// Generates an array of colors for the bars in a confidence meter.
    ///
    /// Confidence meters resemble the bars of an equalizer. Bars illuminate as the confidence increases.
    /// The color of the bars provides a visual indicator of whether the confidence in a label is low, medium, or high.
    ///
    /// - Parameter numBars: The total number of bars to draw in the confidence meter.
    ///
    /// - Returns: An array of colors that contains elements equal to the provided `numBars` argument.
    ///   Each color denotes the color of a single bar within a confidence meter. Bars represent evenly spaced
    ///   confidence scores. The last bar represents a score of 1.0. If there are N bars, the spacing between
    ///   bars is (1.0 / N).
    static func generateConfidenceMeterBarColors(numBars: Int) -> [Color] {
        let numGreenBars = Int(Double(numBars) / 3.0)
        let numYellowBars = Int(Double(numBars) * 2 / 3.0) - numGreenBars
        let numRedBars = Int(numBars - numYellowBars)

        return [Color](repeating: .green, count: numGreenBars) +
          [Color](repeating: .yellow, count: numYellowBars) +
          [Color](repeating: .red, count: numRedBars)
    }

    /// Frames the view within a fixed-size colored plate background.
    ///
    /// - Parameter view: The view to frame within the bounds of a colored plate.
    ///
    /// - Returns: The view with a colored plate in its background, clipping the original view to
    ///   the bounds of the plate.
    static func cardify<T: View>(view: T) -> some View {
        let dimensions = (CGFloat(100.0), CGFloat(200.0))
        let cornerRadius = 20.0
        let color = Color.blue
        let opacity = 0.2

        return view
          .frame(width: dimensions.0,
                 height: dimensions.1)
          .background(
            RoundedRectangle(cornerRadius: cornerRadius)
              .foregroundColor(color)
              .opacity(opacity))
    }

    /// Creates a view that illustrates a confidence score.
    ///
    /// - Parameter confidence: The score to reflect in the generated visualization.
    ///
    /// - Returns: A view that contains an equalizer-like meter for visualizing a confidence score's strength.
    static func generateMeter(confidence: Double) -> some View {
        let numBars = 20
        let barColors = generateConfidenceMeterBarColors(numBars: numBars)
        let confidencePerBar = 1.0 / Double(numBars)
        let barSpacing = CGFloat(2.0)
        let barDimensions = (CGFloat(15.0), CGFloat(2.0))
        let numLitBars = Int(confidence / confidencePerBar)
        let litBarOpacities = [Double](repeating: 1.0, count: numLitBars)
        let unlitBarOpacities = [Double](repeating: 0.1, count: numBars - numLitBars)
        let barOpacities = litBarOpacities + unlitBarOpacities

        return VStack(spacing: barSpacing) {
            ForEach(0..<numBars) {
                Rectangle()
                  .foregroundColor(barColors[numBars - 1 - $0])
                  .opacity(barOpacities[numBars - 1 - $0])
                  .frame(width: barDimensions.0, height: barDimensions.1)
            }
        }.animation(.easeInOut, value: confidence)
    }

    /// Creates a view that illustrates a confidence score and label.
    ///
    /// - Parameters:
    ///   - confidence: The score the generated meter reflects.
    ///   - label: A name to display beneath the meter in the view.
    ///
    /// - Returns: A view that contains an equalizer-like meter for visualizing a confidence score's
    ///   strength, and the name of the sound.
    static func generateLabeledMeter(confidence: Double, label: String) -> some View {
        let textHeight = CGFloat(60)

        return VStack {
            generateMeter(confidence: confidence)
            Text(label)
              .lineLimit(nil)
              .multilineTextAlignment(.center)
              .frame(height: textHeight)
        }
    }

    /// Generates a confidence meter that fades in and out over a placeholder.
    ///
    /// - Parameters:
    ///   - confidence: The score the generated meter reflects.
    ///   - label: A name to display beneath the meter in the view.
    ///
    /// - Returns: A view that contains an equalizer-like meter for visualizing a confidence score's
    ///   strength, and the name of the sound. The app renders the meter over a placeholder background.
    static func generateMeterCard(confidence: Double,
                                  label: String) -> some View {
        return cardify(
          view: generateLabeledMeter(confidence: confidence,
                                     label: label))
    }

    /// Generates a grid of confidence meters that indicate sounds the app detects.
    ///
    /// - Parameter detections: A list of sounds that contain their detection states to render. The
    ///   states indicate whether the sounds appear visible, and if so, the level of confidence to render.
    ///
    /// - Returns: A view that contains a grid of confidence meters, indicating which sounds the app
    ///   detects and how strongly.
    static func generateDetectionsGrid(_ detections: [(SoundIdentifier, DetectionState)]) -> some View {
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 100))],
                      spacing: 2) {
                ForEach(detections, id: \.0.labelName) {
                    generateMeterCard(confidence: $0.1.isDetected ? $0.1.currentConfidence : 0.0,
                                      label: $0.0.displayName)
                }
            }
        }
    }

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Text("Detecting Sounds").font(.title).padding()
                    DetectSoundsView.generateDetectionsGrid(state.detectionStates)
                }.blur(radius: state.soundDetectionIsRunning ? 0.0 : 10.0)
                 .disabled(!state.soundDetectionIsRunning)

                VStack {
                    Text("Sound Detection Paused").padding()
                    Button(action: { state.restartDetection(config: config) }) {
                        Text("Start")
                    }
                }.opacity(state.soundDetectionIsRunning ? 0.0 : 1.0)
                 .disabled(state.soundDetectionIsRunning)
            }

            Button(action: configureAction) {
                Text("Edit Configuration")
            }.padding()
        }
    }
}
