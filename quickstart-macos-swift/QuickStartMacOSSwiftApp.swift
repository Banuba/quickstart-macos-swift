import SwiftUI
import BanubaEffectPlayer

@main
struct QuickStartMacOSSwiftApp: App {
    init() {
        BNBUtilityManager.initialize(
            [
                Bundle(for: BNBEffectPlayer.self).resourcePath! + "/bnb-resources",
                Bundle.main.resourcePath! + "/effects"
            ],
            clientToken: banubaClientToken
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
