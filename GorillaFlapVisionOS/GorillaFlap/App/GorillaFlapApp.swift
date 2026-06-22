import SwiftUI

@main
struct GorillaFlapApp: App {

    @StateObject private var hands: HandMotionTracker
    @StateObject private var engine: GameEngine

    init() {
        let hands = HandMotionTracker()
        _hands = StateObject(wrappedValue: hands)
        _engine = StateObject(wrappedValue: GameEngine(hands: hands))
    }

    var body: some Scene {
        WindowGroup(id: "menu") {
            MainMenuView()
                .environmentObject(engine)
                .environmentObject(hands)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 620)

        ImmersiveSpace(id: "game") {
            ImmersiveGameView()
                .environmentObject(engine)
                .environmentObject(hands)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
