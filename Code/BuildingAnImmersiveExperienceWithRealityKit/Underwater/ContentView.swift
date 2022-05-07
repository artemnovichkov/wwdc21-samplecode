/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's content view.
*/

import SwiftUI
import RealityKit
import ARKit
import Combine
import MetalKit

struct GameState {
    var characterSpeed: SIMD2<Float>? // Length between 0 and 1.
    var jumpIndex: UInt = 0
}

struct ContentView: View {

    @State private var gameState = GameState()
    @State private var showDebugOptions: Bool = false
    @StateObject var settings = Settings()

    var body: some View {
        // Scene + Debug (optional)
        HStack {

            // Scene
            ZStack {

                // Viewport
                ARViewContainer(gameState, settings: settings)
                    .edgesIgnoringSafeArea(.all)
                    .gesture(
                        DragGesture()
                            .onChanged({ event in
                        var translation = 1E-2 * SIMD2<Float>(Float(event.translation.width), Float(event.translation.height))
                        let length = translation.length
                        if length > 1 { translation /= length }
                        gameState.characterSpeed = translation
                    })
                            .onEnded({ _ in gameState.characterSpeed = nil })
                    )

                // Buttons (on top of the viewport)
                HStack {
                    VStack {

                        if UserDefaults.standard.bool(forKey: "show_controls") {
                            Button(
                                action: { showDebugOptions = !showDebugOptions },
                                label: { Text("⚙️").font(.system(size: 30, weight: .bold)) }
                            )

                        }
                        Spacer()
                        Button(
                            action: { gameState.jumpIndex += 1 },
                            label: { Text("⬆️").font(.system(size: 30, weight: .bold)) }
                        ).opacity((UserDefaults.standard.bool(forKey: "show_controls")) ? 1.0 : 0.0)
                    }
                    Spacer()
                }
            }

            // Debug options (optional; on the right)
            if showDebugOptions {
                ScrollView {

                    Group {
                        SettingsView(settings: settings)
                    }.frame(maxWidth: 200)
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {

    private var gameState: GameState
    private var settings: Settings

    public init(_ gameState: GameState, settings: Settings) {
        self.gameState = gameState
        self.settings = settings
    }

    func makeUIView(context: Context) -> UnderwaterView {
        let arView = UnderwaterView(frame: .zero, settings: settings)
        arView.setup()
        arView.gameState = gameState
        return arView
    }

    func updateUIView(_ view: UnderwaterView, context: Context) {
        view.gameState = gameState
    }

}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
