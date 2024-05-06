import SwiftUI
import MetalKit
import BanubaEffectPlayer

struct EffectPlayerView: NSViewRepresentable {
    public let effectPlayer: BNBEffectPlayer
    public var effectManager: BNBEffectManager? {
        effectPlayer.effectManager()
    }
    
    private let renderer: Renderer
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Cannot create MTLDevice") }
        guard let commandQueue = device.makeCommandQueue() else { fatalError("Cannot create MTLCommandQueue") }
        
        self.device = device
        self.commandQueue = commandQueue
        
        BNBEffectPlayer.setRenderBackend(.metal)
        let config = BNBEffectPlayerConfiguration.create(1280, fxHeight: 720)
        guard let effectPlayer = BNBEffectPlayer.create(config) else { fatalError("Cannot create BNBEffectPlayer") }
        self.effectPlayer = effectPlayer
        
        self.renderer = Renderer(effectPlayer: self.effectPlayer, commandQueue: self.commandQueue)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = MTKView()
        view.needsDisplay = true
        view.device = device
        view.delegate = renderer
        guard let layer = view.layer as? CAMetalLayer else { fatalError("Cannot create MTKView") }
        effectPlayer.surfaceCreated(1280, height: 720)
        effectPlayer.effectManager()?.setRenderSurface(
            BNBSurfaceData(
                gpuDevicePtr: Int64(Int(bitPattern: Unmanaged.passUnretained(device).toOpaque())),
                commandQueuePtr: Int64(Int(bitPattern: Unmanaged.passUnretained(commandQueue).toOpaque())),
                surfacePtr: Int64(Int(bitPattern: Unmanaged.passUnretained(layer).toOpaque()))
            )
        )
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

private final class Renderer: NSObject, MTKViewDelegate {
    private let effectPlayer: BNBEffectPlayer
    private let commandQueue: MTLCommandQueue

    init(effectPlayer: BNBEffectPlayer, commandQueue: MTLCommandQueue) {
        self.effectPlayer = effectPlayer
        self.commandQueue = commandQueue
    }
    
    deinit {
        effectPlayer.surfaceDestroyed()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        effectPlayer.surfaceChanged(Int32(size.width), height: Int32(size.height))
    }

    func draw(in view: MTKView) {
        guard let processor = effectPlayer.frameProcessor() else { return }
        let result = processor.pop()
        guard let fd = result.frameData else { return }
        let size = fd.getFullImgFormat()
        effectPlayer.effectManager()?.setEffectSize(Int32(size.width), fxHeight: Int32(size.height))
        effectPlayer.draw(withExternalFrameData: fd)
    }
}
