import SwiftUI

/// Head-locked HUD: score, a vertical height gauge that compares your altitude to the
/// next gap, and in-headset controls so you never need the menu window mid-game.
struct GameHUDView: View {
    @EnvironmentObject private var engine: GameEngine
    @EnvironmentObject private var settings: GameSettings
    @State private var scorePulse = false

    var body: some View {
        VStack(spacing: 14) {
            Text("\(engine.score)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .shadow(radius: 6)
                .scaleEffect(scorePulse ? 1.18 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: scorePulse)
                .onChange(of: engine.score) {
                    scorePulse = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { scorePulse = false }
                }

            if engine.phase == .countdown {
                Text(engine.countdown > 0 ? "\(engine.countdown)" : "GO")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
                    .transition(.scale)
                Text("Get set — swing to fly")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if engine.combo >= 2 {
                Text("COMBO ×\(engine.combo)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                    .transition(.scale.combined(with: .opacity))
            }

            Text("\(Int(engine.distance)) m")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            heightGauge

            controls
        }
        .padding(20)
        .frame(width: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private var controls: some View {
        switch engine.phase {
        case .playing:
            Button { engine.togglePause() } label: {
                Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            sensitivityStepper

        case .paused:
            Text("PAUSED").font(.headline).foregroundStyle(.secondary)
            Button { engine.togglePause() } label: {
                Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button { engine.startGame() } label: {
                Label("Restart", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            sensitivityStepper

        case .gameOver:
            gameOverCard
            Button { engine.startGame() } label: {
                Label("Play Again", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            sensitivityStepper

        case .countdown:
            sensitivityStepper

        case .ready:
            EmptyView()
        }
    }

    /// Quick swing-sensitivity nudge without leaving the immersive space.
    private var sensitivityStepper: some View {
        HStack {
            Text("Swing").font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Button { adjustSensitivity(-0.1) } label: { Image(systemName: "minus") }
                .buttonStyle(.borderless)
                .accessibilityLabel("Decrease swing sensitivity")
            Text("\(Int(settings.swingSensitivity * 100))%")
                .font(.caption2.monospacedDigit())
                .frame(width: 42)
                .accessibilityLabel("Swing sensitivity \(Int(settings.swingSensitivity * 100)) percent")
            Button { adjustSensitivity(0.1) } label: { Image(systemName: "plus") }
                .buttonStyle(.borderless)
                .accessibilityLabel("Increase swing sensitivity")
        }
    }

    private func adjustSensitivity(_ delta: Double) {
        settings.swingSensitivity = min(1, max(0, settings.swingSensitivity + delta))
    }

    /// A simple bar: your current altitude marker vs. the amber target band.
    private var heightGauge: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let range = GameConfig.maxAltitude - GameConfig.minAltitude
            func y(_ alt: Float) -> CGFloat {
                let t = (alt - GameConfig.minAltitude) / range
                return h - CGFloat(t) * h
            }
            let bandHalf = CGFloat(engine.targetGapHalf / range) * h

            ZStack(alignment: .top) {
                Capsule().fill(.white.opacity(0.15)).frame(width: 8)
                    .frame(maxWidth: .infinity)

                // Target gap band.
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 26, height: bandHalf * 2)
                    .position(x: geo.size.width / 2, y: y(engine.targetAltitude))

                // Player marker.
                Circle()
                    .fill(Color.green)
                    .frame(width: 18, height: 18)
                    .position(x: geo.size.width / 2, y: y(engine.altitude))
            }
        }
        .frame(height: 180)
        .accessibilityElement()
        .accessibilityLabel("Height gauge")
        .accessibilityValue(gaugeAccessibilityValue)
    }

    private var gaugeAccessibilityValue: String {
        let delta = engine.altitude - engine.targetAltitude
        let direction: String
        if abs(delta) < engine.targetGapHalf { direction = "aligned with the gap" }
        else if delta < 0 { direction = "below the gap, flap up" }
        else { direction = "above the gap, ease down" }
        return "You are \(String(format: "%.1f", engine.altitude)) meters, \(direction)."
    }

    private var gameOverCard: some View {
        VStack(spacing: 6) {
            Text("CRASH").font(.title3.weight(.heavy)).foregroundStyle(.red)
            if engine.isNewBest {
                Label("NEW BEST!", systemImage: "trophy.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            }
            Text("Score \(engine.score) · \(Int(engine.distance)) m")
                .font(.caption).foregroundStyle(.secondary)
            Text("Best \(engine.bestScore)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}
