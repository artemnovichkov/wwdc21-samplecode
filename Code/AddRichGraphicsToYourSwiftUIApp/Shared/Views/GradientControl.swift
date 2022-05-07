/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The gradient view.
*/

import SwiftUI

struct GradientControl: View {
    @Binding var gradient: GradientModel
    @Binding var selectedStopID: Int?
    var drawGradient = true

    var body: some View {
        GeometryReader { geom in
#if os(iOS)
            let dragGesture = DragGesture(minimumDistance: 0)
                .onEnded {
                    selectedStopID = gradient.append(
                        color: Color.white, at: $0.location.x / geom.size.width
                    ).id
                }
#endif
            VStack(spacing: 0) {
                if drawGradient {
                    LinearGradient(gradient: gradient.gradient, startPoint: .leading, endPoint: .trailing)
                        .border(.secondary, width: 1)
                }
                ZStack {
                    ForEach(gradient.stops) { stop in
                        StopHandle(stop: stop, gradient: $gradient, selectedStopID: $selectedStopID, width: geom.size.width)
                            .position(x: geom.size.width * stop.location, y: 10)
                    }
                }
                .frame(height: drawGradient ? 20 : 10)
            }
#if os(iOS)
            .contentShape(Rectangle())
            .gesture(dragGesture)
#endif
        }
        .coordinateSpace(name: "gradient")
        .frame(minWidth: 200)
        .frame(height: drawGradient ? 50 : 10)
    }

    private struct StopHandle: View {
        var stop: GradientModel.Stop
        @Binding var gradient: GradientModel
        @Binding var selectedStopID: Int?
        var width: Double

        @GestureState
        private var oldLocation: Double?

        var body: some View {
            let dragGesture = DragGesture(coordinateSpace: .named("gradient"))
                .updating($oldLocation) { value, state, _ in
                    if state == nil { state = stop.location }
                    gradient[stopID: stop.id].location
                        = max(0, min(1, state! + value.translation.width / width))
                }

            let tapGesture = TapGesture().onEnded {
                selectedStopID = (selectedStopID == stop.id) ? nil : stop.id
            }

            Triangle()
                .frame(width: 12, height: 10)
                .foregroundStyle(stop.color)
                .overlay {
                    Triangle().stroke(.secondary)
                }
                .scaleEffect(selectedStopID == stop.id ? 1.5 : 1)
                .animation(.default, value: selectedStopID == stop.id)
                .gesture(dragGesture)
                .gesture(tapGesture)
#if os(macOS)
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        gradient.remove(stop.id)
                    }

                    Button("Duplicate") {
                        gradient.append(color: stop.color, at: stop.location + 0.05)
                    }

                    SystemColorPicker(color: $gradient[stopID: stop.id].color)
                }
                .focusable()
                .onDeleteCommand {
                    gradient.remove(stop.id)
                }
                .onMoveCommand { direction in
                    guard direction == .left || direction == .right else { return }
                    let multiplier: Double = direction == .left ? -1 : 1
                    let newLocation = stop.location + multiplier * 0.01
                    gradient[stopID: stop.id].location = max(0, min(1, newLocation))
                }
#endif
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
