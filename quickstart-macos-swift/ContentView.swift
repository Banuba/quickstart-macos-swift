import SwiftUI
import BanubaEffectPlayer

struct ContentView: View {
    let effectPlayerView = EffectPlayerView()
    let camera = Camera()
    
    var processor: BNBFrameProcessor?
    
    init() {
        processor = BNBFrameProcessor.createRealtimeProcessor(.async, config: BNBProcessorConfiguration.create())
        
        effectPlayerView.effectPlayer.setFrameProcessor(processor)
    }
    
    var body: some View {
        VStack {
            effectPlayerView
                .aspectRatio(16 / 9, contentMode: .fill)
                .onAppear {
                    effectPlayerView.effectManager?.loadAsync("DebugWireframe")
                }
        }
        .task {
            await camera.start()
            for await pixelBuffer in camera.previewStream {
                let fd = BNBFrameData.create()
                let fullImageData = BNBFullImageData(
                    pixelBuffer,
                    cameraOrientation: .deg0,
                    requireMirroring: true,
                    faceOrientation: 0,
                    fieldOfView: 55.0
                )
                fd?.addFullImg(fullImageData)
                processor?.push(fd)
            }
        }
    }
}

#Preview {
    ContentView()
}
