import SwiftUI
import MetalKit
import QuantumMechanicsLabCore

#if os(macOS)
struct MetalWavefunctionView2D: NSViewRepresentable {
    var snapshot: SimulationSnapshot

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.autoResizeDrawable = true
        view.preferredFramesPerSecond = 60
        context.coordinator.setup(device: view.device)
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.snapshot = snapshot
        nsView.setNeedsDisplay(nsView.bounds)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
#else
struct MetalWavefunctionView2D: UIViewRepresentable {
    var snapshot: SimulationSnapshot

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.autoResizeDrawable = true
        view.preferredFramesPerSecond = 60
        context.coordinator.setup(device: view.device)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.snapshot = snapshot
        uiView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
#endif

class Coordinator: NSObject, MTKViewDelegate {
    var snapshot: SimulationSnapshot?
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var texture: MTLTexture?
    var pipelineState: MTLRenderPipelineState?

    func setup(device: MTLDevice?) {
        self.device = device
        self.commandQueue = device?.makeCommandQueue()

        let libraryCode = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
            float2 positions[4] = {
                float2(-1.0, -1.0),
                float2( 1.0, -1.0),
                float2(-1.0,  1.0),
                float2( 1.0,  1.0)
            };
            VertexOut out;
            out.position = float4(positions[vertexID], 0.0, 1.0);
            out.texCoord = float2((positions[vertexID].x + 1.0) * 0.5, 1.0 - (positions[vertexID].y + 1.0) * 0.5);
            return out;
        }

        float3 hsv2rgb(float3 c) {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
            constexpr sampler s(coord::normalized, address::clamp_to_edge, filter::linear);
            float4 sample = tex.sample(s, in.texCoord);

            float realPart = sample.r;
            float imagPart = sample.g;
            float potentialNorm = sample.b;

            float density = realPart * realPart + imagPart * imagPart;

            float4 outColor = float4(0, 0, 0, 1.0);

            if (density > 0.002) {
                float phase = atan2(imagPart, realPart);
                float hue = (phase + 3.14159265359) / (2.0 * 3.14159265359);
                float brightness = max(0.15, min(sqrt(density), 1.0));
                float3 rgb = hsv2rgb(float3(hue, 0.85, brightness));
                outColor.rgb = rgb;
            }

            if (potentialNorm > 0.05) {
                float potentialAlpha = 0.16 + min(potentialNorm, 1.0) * 0.34;
                float3 potentialColor = float3(1.0, 165.0/255.0, 0.0);
                outColor.rgb = mix(outColor.rgb, potentialColor, potentialAlpha);
            }

            return outColor;
        }
        """

        guard let device = device else { return }
        do {
            let library = try device.makeLibrary(source: libraryCode, options: nil)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \\(error)")
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let snapshot = snapshot,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let pipelineState = pipelineState
        else { return }

        let width: Int
        let height: Int
        let pointCount: Int

        switch snapshot.grid {
        case let .twoD(grid):
            width = grid.width
            height = grid.height
            pointCount = grid.pointCount
        case let .orbital(resolution):
            width = resolution
            height = resolution
            pointCount = resolution * resolution
        default:
            return
        }

        if texture == nil || texture?.width != width || texture?.height != height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: width, height: height, mipmapped: false)
            texture = device?.makeTexture(descriptor: descriptor)
        }

        guard let texture = texture else { return }

        // Build texture data
        let density = snapshot.psi.probabilityDensity()
        let maxDensity = max(density.max() ?? 0, .ulpOfOne)
        let sqrtMaxDensity = sqrt(maxDensity)
        var pixels = [Float](repeating: 0, count: width * height * 4)

        var potentialNorms: [Float] = Array(repeating: 0, count: pointCount)
        if let potential = snapshot.potential, potential.values.count == pointCount {
            let maxPot = potential.values.max() ?? .ulpOfOne
            for i in 0..<pointCount {
                potentialNorms[i] = Float(potential.values[i] / maxPot)
            }
        }

        for row in 0..<height {
            for column in 0..<width {
                // Determine linear index depending on how grid is structured.
                // Both TwoD and Orbital flatten as row-major.
                let index = row * width + column
                let sample = snapshot.psi[index]

                let pixelIndex = index * 4
                pixels[pixelIndex] = Float(sample.real / sqrtMaxDensity)
                pixels[pixelIndex + 1] = Float(sample.imaginary / sqrtMaxDensity)
                pixels[pixelIndex + 2] = potentialNorms[index]
                pixels[pixelIndex + 3] = 0.0
            }
        }

        texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: width * 4 * MemoryLayout<Float>.size)

        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0.92)
        renderPassDescriptor?.colorAttachments[0].loadAction = .clear

        if let renderPassDescriptor = renderPassDescriptor,
           let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
