import SwiftUI

/// 2D window: start the run, see your best score, and read the one-paragraph how-to.
struct MainMenuView: View {
    @EnvironmentObject private var engine: GameEngine
    @EnvironmentObject private var hands: HandMotionTracker

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var immersiveOpen = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("GORILLA·FLAP")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                    Text("Swing to run. Swing to fly. Find the gap.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                instructions

                if engine.bestScore > 0 {
                    Label("Best: \(engine.bestScore)", systemImage: "trophy.fill")
                        .font(.title3.weight(.semibold))
                }

                Button(action: launch) {
                    Text(immersiveOpen ? "Restart Run" : "Enter & Play")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                if immersiveOpen {
                    Button("Exit to Reality") { Task { await close() } }
                        .buttonStyle(.bordered)
                }

                CalibrationView()

                if immersiveOpen {
                    Text("Tip: tweak these sliders while you play — changes apply instantly.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if hands.authorizationDenied {
                    Text("Hand tracking is off. Enable it in Settings ▸ Privacy to play.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Text("Spatial sound is built in. Haptics play through a paired game controller — Vision Pro has no haptics of its own.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("figure.gymnastics", "Swing both arms down", "like hauling yourself forward — Gorilla Tag style.")
            row("arrow.up", "Each swing flaps you up", "harder swings lift higher; gravity always pulls down.")
            row("rectangle.portrait", "Thread the glowing gaps", "the amber frame is your next target's height.")
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func row(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.title2).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func launch() {
        Task {
            if !immersiveOpen {
                switch await openImmersiveSpace(id: "game") {
                case .opened: immersiveOpen = true
                default: return
                }
            }
            engine.startGame()
        }
    }

    private func close() async {
        await dismissImmersiveSpace()
        immersiveOpen = false
    }
}
