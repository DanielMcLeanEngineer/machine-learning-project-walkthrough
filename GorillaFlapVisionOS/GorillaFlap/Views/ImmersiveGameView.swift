import SwiftUI
import RealityKit

/// The immersive scene: mounts the game world, head-locks the HUD, and kicks off
/// hand tracking when the space opens.
struct ImmersiveGameView: View {
    @EnvironmentObject private var engine: GameEngine
    @EnvironmentObject private var hands: HandMotionTracker
    @EnvironmentObject private var feedback: FeedbackEngine
    @EnvironmentObject private var settings: GameSettings
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RealityView { content, attachments in
            content.add(engine.worldRoot)
            engine.setup(content: content)

            // Head-anchored HUD so the gauge stays comfortably in view, off to the side.
            let head = AnchorEntity(.head)
            head.anchoring.trackingMode = .continuous
            if let hud = attachments.entity(for: "hud") {
                hud.position = [0.42, -0.28, -1.4]
                head.addChild(hud)
            }

            // Head-locked comfort vignette, driven by the game loop.
            let vignette = await ComfortVignette.make()
            head.addChild(vignette)
            engine.comfortVignette = vignette

            content.add(head)
        } attachments: {
            Attachment(id: "hud") {
                GameHUDView()
                    .environmentObject(engine)
                    .environmentObject(settings)
            }
        }
        .task {
            feedback.prepare()
            await hands.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { engine.pauseIfPlaying() }
        }
        .onDisappear {
            engine.pauseIfPlaying()
            feedback.endRun()
            hands.stop()
        }
    }
}
