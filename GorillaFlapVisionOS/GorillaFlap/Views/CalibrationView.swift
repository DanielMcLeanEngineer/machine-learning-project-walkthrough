import SwiftUI

/// Live calibration sliders. Because the simulation reads `GameSettings` every frame,
/// dragging any slider changes the feel immediately — including while a run is in
/// progress in the immersive space.
struct CalibrationView: View {
    @EnvironmentObject private var settings: GameSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Calibration", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Button("Reset") { settings.resetToDefaults() }
                    .font(.caption)
                    .buttonStyle(.borderless)
            }

            slider("Swing sensitivity",
                   value: $settings.swingSensitivity,
                   low: "Hard", high: "Light",
                   help: "Lower the effort needed to register an arm swing.")

            slider("Lift strength",
                   value: $settings.liftStrength, in: 0.6...1.7,
                   low: "Gentle", high: "Springy",
                   help: "How much each swing boosts you upward.")

            slider("Floatiness",
                   value: $settings.floatiness,
                   low: "Heavy", high: "Floaty",
                   help: "How quickly gravity pulls you back down.")

            slider("Comfort vignette",
                   value: $settings.comfortVignette,
                   low: "Off", high: "Strong",
                   help: "Dims your peripheral vision during fast motion to ease motion comfort.")
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func slider(_ title: String,
                        value: Binding<Double>,
                        in range: ClosedRange<Double> = 0...1,
                        low: String, high: String,
                        help: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold))
            Slider(value: value, in: range) {
                Text(title)
            } minimumValueLabel: {
                Text(low).font(.caption2).foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text(high).font(.caption2).foregroundStyle(.secondary)
            }
            Text(help).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
