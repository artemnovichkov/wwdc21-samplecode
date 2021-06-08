/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The content view for the biquadratic filter app.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var musicProvider: FilterableMusicProvider
    
    var body: some View {
        
        HSplitView {
            
            GeometryReader { geometry in
                Color.gray.opacity(0.5)
                // The following path displays the magnitude response for all
                // of the biquadratic filter's sections.
                Path { path in
                    Self.updatePath(
                        &path,
                        size: geometry.size,
                        closePath: true,
                        values: musicProvider.magnitudeResponseValues)
                }
                .fill(Color.blue.opacity(0.2))
                
                // The following path displays the magnitude response for the
                // biquadratic filter's selected section.
                Path { path in
                    Self.updatePath(
                        &path,
                        size: geometry.size,
                        values: musicProvider.selectedSectionResponseValues)
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
                
                // The following path displays the frequency domain representation
                // of the transformed output.
                Path { path in
                    Self.updatePath(
                        &path,
                        size: geometry.size,
                        closePath: true,
                        zeroAtBase: true,
                        values: musicProvider.frequencyDomainOutputValues)
                }
                .fill(Color.red)
                
                // The following path displays the frequency domain representation
                // of the original input.
                Path { path in
                    Self.updatePath(
                        &path,
                        size: geometry.size,
                        zeroAtBase: true,
                        values: musicProvider.frequencyDomainInputValues)
                }
                .stroke(Color.white, lineWidth: 1)
            }
            .frame(width: 640, height: 480)
            
            GeometryReader { geometry in
                VStack {
                    
                    Picker("Select Section", selection: $musicProvider.selectedSectionIndex) {
                        ForEach((0 ..< Int(musicProvider.biquadSectionCount)), id: \.self) {
                            Text("Section \($0)").tag($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .labelsHidden()
                    
                    HStack {
                        Text("Select Type:")
                            .frame(width: geometry.size.width / 4,
                                           alignment: .trailing)
                        
                        Picker("Type", selection: $musicProvider.parameters[musicProvider.selectedSectionIndex].filterType) {
                            ForEach(BiquadCoefficientCalculator.FilterType.allCases) { filterType in
                                Text(filterType.rawValue)
                                    .tag(filterType)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .labelsHidden()
                    }.frame(width: geometry.size.width,
                            alignment: .leading)
                    
                    Divider()
                    
                    Slider(
                        value: $musicProvider.parameters[musicProvider.selectedSectionIndex].frequency,
                        in: 20 ... Float(musicProvider.sampleRate / 2) - 20
                    ) {
                        Text("Frequency: \n\(musicProvider.parameters[musicProvider.selectedSectionIndex].frequency, specifier: "%.1f") Hz")
                            .font(.system(.body, design: .default).monospacedDigit())
                            .multilineTextAlignment(.trailing)
                            .frame(width: geometry.size.width / 4,
                                                alignment: .trailing)
                    }
                    .disabled(musicProvider.parameters[musicProvider.selectedSectionIndex].filterType == .passthrough)
                    
                    Slider(
                        value: $musicProvider.parameters[musicProvider.selectedSectionIndex].Q,
                        in: 0.1 ... 25
                    ) {
                        Text("Q: \(musicProvider.parameters[musicProvider.selectedSectionIndex].Q, specifier: "%.3f")")
                            .font(.system(.body, design: .default).monospacedDigit())
                            .frame(width: geometry.size.width / 4,
                                        alignment: .trailing)
                    }
                    .disabled(musicProvider.parameters[musicProvider.selectedSectionIndex].filterType == .passthrough)
                    
                    Slider(
                        value: $musicProvider.parameters[musicProvider.selectedSectionIndex].dbGain,
                        in: -50 ... 50
                    ) {
                        Text("db Gain: \(musicProvider.parameters[musicProvider.selectedSectionIndex].dbGain, specifier: "%.3f")")
                            .font(.system(.body, design: .default).monospacedDigit())
                            .frame(width: geometry.size.width / 4,
                                        alignment: .trailing)
                    }
                    .disabled(musicProvider.parameters[musicProvider.selectedSectionIndex].filterType != .peakingEQ)
                    
                    Divider()
                    
                    Text("\(musicProvider.selectedSectionCoefficients.description)")
                        .font(.system(size: 14, design: .monospaced))
                }
            }
            .padding([.bottom, .leading, .trailing])
            .frame(width: 320, height: 480)
        }
        .padding()
    }
    
    static func updatePath(_ path: inout Path,
                           size: CGSize,
                           closePath: Bool = false,
                           zeroAtBase: Bool = false,
                           values: [Float]) {
        
        let cgPath = CGMutablePath()
        let hScale = size.width / CGFloat(values.count)
        var points: [CGPoint] = values.enumerated().map {
            
            var y: CGFloat
            
            if zeroAtBase {
                y = (size.height * 1 * CGFloat($0.element))
            } else {
                y = size.height * 0.5 + (size.height * 0.01 * CGFloat($0.element))
            }

            y = size.height - min(max(0, y), size.height)
            
            return CGPoint(x: CGFloat($0.offset) * hScale,
                           y: y)
        }
        
        if closePath {
            points.append(CGPoint(x: size.width, y: size.height))
            points.append(CGPoint(x: 0, y: size.height))
            points.append(points.first!)
        }
        
        cgPath.addLines(between: points)
        
        path = Path(cgPath)
    }
}
