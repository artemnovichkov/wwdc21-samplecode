/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scale visualizer.
*/

import SwiftUI

struct ShapeVisualizer: View {
    var gradients: [Gradient]
    @State private var state = SymbolState()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(state.entries.indices, id: \.self) { index in
                    let entry = state.entries[index]
                    entry.symbol
                        .foregroundStyle(.elliptical(
                            gradients[entry.gradientSeed % gradients.count]))
                        .scaleEffect(entry.selected ? 4 : 1)
                        .position(
                            x: proxy.size.width * entry.x,
                            y: proxy.size.height * entry.y)
                        .onTapGesture {
                            withAnimation {
                                state.entries[index].selected.toggle()
                            }
                        }
                        .accessibilityAction {
                            state.entries[index].selected.toggle()
                        }
                }
            }
        }
        .font(.system(size: 24))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 2)) {
                state.reposition()
            }
        }
        .accessibilityAction(named: "Reposition") {
            state.reposition()
        }
        .drawingGroup()
    }
}

struct SymbolState {
    var entries: [Entry] = []

    init(count: Int = 100) {
        for index in 0..<count {
            entries.append(Entry(gradientSeed: index))
        }
    }

    mutating func reposition() {
        for index in entries.indices {
            entries[index].reposition()
        }
    }

    struct Entry {
        var gradientSeed: Int
        var symbolSeed: Int
        var x: Double
        var y: Double
        var selected: Bool = false

        init(gradientSeed: Int) {
            self.gradientSeed = gradientSeed
            symbolSeed = Int.random(in: 1..<symbols.count)
            x = Double.random(in: 0..<1)
            y = Double.random(in: 0..<1)
        }

        mutating func reposition() {
            x = Double.random(in: 0..<1)
            y = Double.random(in: 0..<1)
        }

        var symbol: Image {
            Image(systemName: symbols[symbolSeed])
        }
    }
}

private let symbols = [
    "triangle.fill",
    "heart.fill",
    "star.fill",
    "diamond.fill",
    "octagon.fill",
    "capsule.fill",
    "square.fill",
    "seal.fill"
]
