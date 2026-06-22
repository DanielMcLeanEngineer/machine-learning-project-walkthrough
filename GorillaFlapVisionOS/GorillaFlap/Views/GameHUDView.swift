import SwiftUI

/// Head-locked HUD: score, a vertical height gauge that compares your altitude to the
/// next gap, and the game-over restart prompt.
struct GameHUDView: View {
    @EnvironmentObject private var engine: GameEngine

    var body: some View {
        VStack(spacing: 14) {
            Text("\(engine.score)")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .shadow(radius: 6)

            heightGauge

            if engine.phase == .gameOver {
                gameOverCard
            }
        }
        .padding(20)
        .frame(width: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
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
            let bandHalf = CGFloat(GameConfig.gapHalfHeight / range) * h

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
    }

    private var gameOverCard: some View {
        VStack(spacing: 6) {
            Text("CRASH").font(.title3.weight(.heavy)).foregroundStyle(.red)
            Text("Best \(engine.bestScore)").font(.caption).foregroundStyle(.secondary)
            Text("Press Restart in the menu window")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}
