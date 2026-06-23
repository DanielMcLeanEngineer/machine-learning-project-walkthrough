import SwiftUI
import RealityKit

@main
struct GorillaFlapApp: App {

    @StateObject private var settings: GameSettings
    @StateObject private var hands: HandMotionTracker
    @StateObject private var feedback: FeedbackEngine
    @StateObject private var engine: GameEngine

    init() {
        ObstacleParts.registerComponent()
        SpinComponent.registerComponent()

        let settings = GameSettings()
        let hands = HandMotionTracker(settings: settings)
        let feedback = FeedbackEngine()
        _settings = StateObject(wrappedValue: settings)
        _hands = StateObject(wrappedValue: hands)
        _feedback = StateObject(wrappedValue: feedback)
        _engine = StateObject(wrappedValue: GameEngine(hands: hands, feedback: feedback, settings: settings))
    }

    var body: some Scene {
        WindowGroup(id: "menu") {
            MainMenuView()
                .environmentObject(engine)
                .environmentObject(hands)
                .environmentObject(feedback)
                .environmentObject(settings)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 820)

        ImmersiveSpace(id: "game") {
            ImmersiveGameView()
                .environmentObject(engine)
                .environmentObject(hands)
                .environmentObject(feedback)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
