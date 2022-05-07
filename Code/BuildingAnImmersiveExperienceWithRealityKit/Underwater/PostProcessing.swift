/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Swift code needed for metal postprocessing.
*/

import ARKit
import MetalKit
import RealityKit
import SwiftUI
import Combine

enum RenderingDebugOption: Int, CaseIterable {
    case final = 0
    case none = 1
    case depth = 2
    case position = 3
    case godRays = 4
    case direction = 5
    case normals = 6

    var name: String {
        switch self {
        case .final: return "Final"
        case .none: return "None"
        case .depth: return "Depth"
        case .position: return "Position"
        case .godRays: return "God Rays"
        case .direction: return "Direction"
        case .normals: return "Normals"
        }
    }
}

class PostProcessing {

    struct Options {

        var selectedRenderingDebugOption: RenderingDebugOption = .final
        var selectedRenderingDebugOptionIndex: Int {
            get { return selectedRenderingDebugOption.rawValue }
            set { selectedRenderingDebugOption = .init(rawValue: newValue)! }
        }

        var enableCaustics: Bool = true
        var interpolateLidarDepth: Bool = true
        var useColorRamp: Bool = false
        var fogColor: Color = .init(cgColor: #colorLiteral(red: 0.106, green: 0.467, blue: 0.518, alpha: 1.0))

        struct ShaderFloats {
            var fogIntensity: Float = 2.9
            var fogFalloff: Float = 2.2
            var fogExponent: Float = 0.134
            var causticStrength: Float = 0.4
            var causticAddition: Float = 1.0
            var causticWaveScale: Float = 0.1
            var causticWaveSpeed: Float = 0.9
            var causticOrientation: Float = 1.0
            var causticSlope: Float = 0.4
        }
        var shaderFloats = ShaderFloats()

        struct View: SwiftUI.View {

            var options: Binding<Options>

            var parameters: [ParameterView.Parameter] {
                [
                    ("fog intensity", options.shaderFloats.fogIntensity),
                    ("fog falloff", options.shaderFloats.fogFalloff),
                    ("fog exponent", options.shaderFloats.fogExponent),
                    ("caustic strength", options.shaderFloats.causticStrength),
                    ("caustic addition", options.shaderFloats.causticAddition),
                    ("caustic wave scale", options.shaderFloats.causticWaveScale),
                    ("caustic wave speed", options.shaderFloats.causticWaveSpeed),
                    ("caustic orientation", options.shaderFloats.causticOrientation),
                    ("caustic slope", options.shaderFloats.causticSlope)
                ].map { .init(id: $0.0, binding: $0.1) }
            }

            var body: some SwiftUI.View {

                VStack {

                    // Rendering mode
                    Picker(
                        selection: options.selectedRenderingDebugOptionIndex,
                        label: Text("Post processing")
                    ) {
                        ForEach((0..<RenderingDebugOption.allCases.count)) {
                            Text(RenderingDebugOption.allCases[$0].name)
                        }
                    }

                    // Individual parameters
                    ForEach(parameters) { parameter in
                        ParameterView(parameter: parameter)
                        Spacer()
                    }

                    Toggle("Caustics", isOn: options.enableCaustics)
                    Toggle("Lidar interpolation", isOn: options.interpolateLidarDepth)
                    Toggle("Color ramp", isOn: options.useColorRamp)
                    ColorPicker("Fog", selection: options.fogColor)
                }
            }
        }
    }

    struct FunctionConstants: Hashable {
        var renderMode: Int
        var withCaustics: Bool
        var useColorRamp: Bool
    }

    var postProcessPipelines: [FunctionConstants: MTLComputePipelineState] = [:]
    func postProcessPipeline(for constants: FunctionConstants) throws -> MTLComputePipelineState {
        if let existing = postProcessPipelines[constants] { return existing }
        let mtlConstants = MTLFunctionConstantValues()
        var constants2 = constants
        mtlConstants.setConstantValue(&constants2.renderMode, type: .int, index: 0)
        mtlConstants.setConstantValue(&constants2.withCaustics, type: .bool, index: 1)
        mtlConstants.setConstantValue(&constants2.useColorRamp, type: .bool, index: 2)
        let function = try MetalLibLoader.library.makeFunction(name: "postProcess", constantValues: mtlConstants)
        postProcessPipelines[constants] = try MetalLibLoader.mtlDevice.makeComputePipelineState(function: function)
        return try postProcessPipeline(for: constants)
    }

    weak var arView: UnderwaterView?

    var depth: MTLTexture?
    var frame: ARFrame?

    struct Directions {
        var topLeft: SIMD3<Float>
        var topRight: SIMD3<Float>
        var bottomLeft: SIMD3<Float>
        var bottomRight: SIMD3<Float>
    }

    // Note: if you modify InputArgs, you must make the same exact changes in
    // PostProcessing.metal, otherwise everything will be green.
    struct InputArgs {
        var viewMatrixInverse: float4x4
        var viewMatrix: float4x4
        var viewTranslation: SIMD4<Float>
        var directions: Directions
        var time: Float
        var orientationTransform: float2x2
        var orientationOffset: (Float, Float)
        var floats: PostProcessing.Options.ShaderFloats
        var fogColor: SIMD4<Float>

        // Must be last.
        let validityCheck: UInt8 = 42
    }

    var directions: Directions?
    var directionsCancellable: Cancellable?

    struct ShaderTextures {
        var colorRamp: MTLTexture
        var mixingRamp: MTLTexture
        var cellNoise: MTLTexture
    }

    init(arView: UnderwaterView) {
        self.arView = arView

        self.directionsCancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            guard let self = self else { return }

            self.directions = Directions(
                topLeft: arView.ray(through: .init(x: 0, y: arView.bounds.height))!.direction,
                topRight: arView.ray(through: .init(x: arView.bounds.width, y: arView.bounds.height))!.direction,
                bottomLeft: arView.ray(through: .init(x: 0, y: 0))!.direction,
                bottomRight: arView.ray(through: .init(x: arView.bounds.width, y: 0))!.direction)
        }

        let textureLoader = MTKTextureLoader(device: MetalLibLoader.mtlDevice)
        textureLoader.newTextures(
            URLs: ["ColorRamp", "MixingRamp", "cell_noise_1"].compactMap { Bundle.main.url(forResource: $0, withExtension: "png") },
            options: nil
        ) { [weak self] textures, error in
            guard textures.count == 3 else {
                assertionFailure("Cannot load textures \(String(describing: error))")
                return
            }

            let colorRamp = textures[0]
            let mixingRamp = textures[1]
            let cellNoise = textures[2]

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.setupRenderCallback(textures: .init(
                    colorRamp: colorRamp,
                    mixingRamp: mixingRamp,
                    cellNoise: cellNoise
                ))
            }
        }
    }

    var depthBytes: [Float32]?
}

extension PostProcessing {

    func setupRenderCallback(textures: ShaderTextures) {

        arView?.renderCallbacks.postProcess = { [weak self] context in
            guard let self = self else { return }
            guard let arView = self.arView else { return }

            let orientationTransform = self.frame?.displayTransform(
                for: .landscapeRight,
                   viewportSize: .init(width: context.sourceColorTexture.width, height: context.sourceColorTexture.height)
            ).inverted() ?? .identity

            // Make sure that this matches the Metal struct.
            assert(MemoryLayout<float4x4>.size == MemoryLayout<Float>.size * 4 * 4)
            assert(MemoryLayout<float2x2>.size == MemoryLayout<Float>.size * 2 * 2)

            let options = arView.settings.postProcessing

            let viewMatrix = context.projection * Transform(
                scale: arView.cameraTransform.scale,
                rotation: arView.cameraTransform.rotation
            ).matrix

            guard let directions = self.directions else { return }

            let inputArgs = InputArgs(
                viewMatrixInverse: viewMatrix.inverse,
                viewMatrix: viewMatrix,
                viewTranslation: .init(
                    arView.cameraTransform.translation.x,
                    arView.cameraTransform.translation.y,
                    arView.cameraTransform.translation.z,
                    1.0
                ),
                directions: directions,
                time: Float(context.time),
                orientationTransform: .init(
                    .init(Float(orientationTransform.a), Float(orientationTransform.b)),
                        .init(Float(orientationTransform.c), Float(orientationTransform.d))
                ),
                orientationOffset: (Float(orientationTransform.tx), Float(orientationTransform.ty)),
                floats: options.shaderFloats,
                fogColor: options.fogColor
                    .cgColor?.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .absoluteColorimetric, options: nil)?
                    .components.map { SIMD4<Float>(Float($0[0]), Float($0[1]), Float($0[2]), 1.0) } ?? SIMD4<Float>()
            )

            self.postProcess(context: context, inputArgs: inputArgs, textures: textures, options: options)
        }
    }

    func postProcess(
        context: ARView.PostProcessContext,
        inputArgs: InputArgs,
        textures: ShaderTextures,
        options: Options
    ) {
        guard let depth = self.depth else { return }

        let postProcessPipeline: MTLComputePipelineState
        do {
            postProcessPipeline = try self.postProcessPipeline(for: .init(
                renderMode: options.selectedRenderingDebugOption.rawValue,
                withCaustics: options.enableCaustics,
                useColorRamp: options.useColorRamp
            ))
        } catch {
            assertionFailure("\(error)")
            return
        }

        guard let encoder = context.commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        encoder.setComputePipelineState(postProcessPipeline)
        encoder.setTexture(context.sourceColorTexture, index: 0)
        encoder.setTexture(context.sourceDepthTexture, index: 1)
        encoder.setTexture(context.targetColorTexture, index: 2)
        encoder.setTexture(depth, index: 3)
        encoder.setTexture(textures.colorRamp, index: 4)
        encoder.setTexture(textures.mixingRamp, index: 5)
        encoder.setTexture(textures.cellNoise, index: 6)
        var args = inputArgs
        withUnsafeBytes(of: &args) {
            encoder.setBytes($0.baseAddress!, length: MemoryLayout<InputArgs>.stride, index: 0)
        }

        let threadsPerGrid = MTLSize(width: context.sourceColorTexture.width,
                                     height: context.sourceColorTexture.height,
                                     depth: 1)

        let w = postProcessPipeline.threadExecutionWidth
        let h = postProcessPipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)

        encoder.dispatchThreads(threadsPerGrid,
                                threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }

    func getDepthBytes(length: Int) -> [Float32] {
        if let depthBytes = self.depthBytes, depthBytes.count == length { return depthBytes }
        self.depthBytes = [Float](repeating: 0, count: length)
        return getDepthBytes(length: length)
    }

    func makeDepthTexture(width: Int, height: Int, format: MTLPixelFormat) -> MTLTexture {
        if let depth = self.depth,
           depth.width == width,
           depth.height == height,
           depth.pixelFormat == format {
            return depth
        }
        self.depth = MetalLibLoader.mtlDevice.makeTexture(
            descriptor: .texture2DDescriptor(
                pixelFormat: format,
                width: width,
                height: height,
                mipmapped: false
            )
        )
        return makeDepthTexture(width: width, height: height, format: format)
    }

    func update(_ frame: ARFrame) {
        guard let cvDepth = (frame.smoothedSceneDepth ?? frame.sceneDepth)?.depthMap else { return }

        self.frame = frame

        let width = CVPixelBufferGetWidth(cvDepth)
        let height = CVPixelBufferGetHeight(cvDepth)

        var textureRef: CVMetalTexture?

        if CVMetalTextureCacheCreateTextureFromImage(nil, MetalLibLoader.textureCache, cvDepth, nil, .r32Float,
                                                     width, height, 0, &textureRef) != kCVReturnSuccess {
            fatalError()
        }

        if let textureRef = textureRef, let originalDepth = CVMetalTextureGetTexture(textureRef) {

            // Interpolating Depth32 is not supported; convert the texture to Float16 instead.
            if arView?.settings.postProcessing.interpolateLidarDepth ?? false {
                var bytes = getDepthBytes(length: width * height)
                let region = MTLRegion(origin: .init(), size: .init(width: width, height: height, depth: 1))
                bytes.withUnsafeMutableBytes {
                    originalDepth.getBytes(
                        $0.baseAddress!,
                        bytesPerRow: width * MemoryLayout<Float32>.stride,
                        from: region,
                        mipmapLevel: 0
                    )
                }
                let convertedBytes = bytes.map { Float16($0) }
                convertedBytes.withUnsafeBytes {
                    let newDepth = makeDepthTexture(width: width, height: height, format: .r16Float)
                    newDepth.replace(
                        region: region,
                        mipmapLevel: 0,
                        withBytes: $0.baseAddress!,
                        bytesPerRow: width * MemoryLayout<Float16>.stride
                    )
                    depth = newDepth
                }
            } else {
                depth = originalDepth
            }
        } else {
            assertionFailure("Could not get a MTLTexture")
        }
    }
}
