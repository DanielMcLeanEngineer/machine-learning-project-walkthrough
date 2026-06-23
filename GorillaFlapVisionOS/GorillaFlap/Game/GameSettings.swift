import Foundation
import Combine

/// Player-tunable calibration that the game reads live every frame, so changes from the
/// menu sliders take effect instantly — even mid-run. Values persist across launches.
///
/// `GameConfig` holds the fixed design defaults; this layers user adjustments on top of
/// them (a sensitivity, a lift multiplier, and a gravity scale).
@MainActor
final class GameSettings: ObservableObject {

    /// 0 = must swing hard to register, 1 = the lightest flick counts.
    @Published var swingSensitivity: Double { didSet { persist(\.swingSensitivity, key: Keys.sensitivity) } }
    /// Direct multiplier on how much each swing lifts you (0.6 = heavy, 1.7 = springy).
    @Published var liftStrength: Double { didSet { persist(\.liftStrength, key: Keys.lift) } }
    /// 0 = falls fast (heavy), 1 = hangs in the air (floaty).
    @Published var floatiness: Double { didSet { persist(\.floatiness, key: Keys.float) } }
    /// 0 = no peripheral dimming, 1 = strong vignette during fast motion (comfort).
    @Published var comfortVignette: Double { didSet { persist(\.comfortVignette, key: Keys.vignette) } }
    /// Practice mode: hitting a wall snaps you to the gap instead of ending the run.
    @Published var practiceMode: Bool { didSet { UserDefaults.standard.set(practiceMode, forKey: Keys.practice) } }

    // MARK: Defaults (chosen so the sliders start at today's hand-tuned feel)
    static let defaultSensitivity = 0.6
    static let defaultLift = 1.0
    static let defaultFloatiness = 0.5
    static let defaultComfortVignette = 0.6

    private enum Keys {
        static let sensitivity = "gf.swingSensitivity"
        static let lift = "gf.liftStrength"
        static let float = "gf.floatiness"
        static let vignette = "gf.comfortVignette"
        static let practice = "gf.practiceMode"
    }

    init() {
        let defaults = UserDefaults.standard
        swingSensitivity = defaults.object(forKey: Keys.sensitivity) as? Double ?? Self.defaultSensitivity
        liftStrength = defaults.object(forKey: Keys.lift) as? Double ?? Self.defaultLift
        floatiness = defaults.object(forKey: Keys.float) as? Double ?? Self.defaultFloatiness
        comfortVignette = defaults.object(forKey: Keys.vignette) as? Double ?? Self.defaultComfortVignette
        practiceMode = defaults.object(forKey: Keys.practice) as? Bool ?? false
    }

    func resetToDefaults() {
        swingSensitivity = Self.defaultSensitivity
        liftStrength = Self.defaultLift
        floatiness = Self.defaultFloatiness
        comfortVignette = Self.defaultComfortVignette
    }

    // MARK: Derived values consumed by the simulation

    /// Downward wrist speed (m/s) needed to register a swing. High sensitivity → low
    /// threshold. Maps sensitivity 0...1 to 1.6...0.45 m/s.
    var swingSpeedThreshold: Float {
        lerp(1.6, 0.45, Float(swingSensitivity))
    }

    /// Multiplier applied to each swing's upward impulse.
    var liftMultiplier: Float {
        Float(liftStrength)
    }

    /// User-scaled cap on how dark the comfort vignette can get.
    var vignetteAmount: Float {
        Float(comfortVignette)
    }

    /// Gravity after the floatiness scale. Floatiness 0...1 maps the pull to 1.4...0.6×.
    var effectiveGravity: Float {
        GameConfig.gravity * lerp(1.4, 0.6, Float(floatiness))
    }

    private func persist(_ keyPath: KeyPath<GameSettings, Double>, key: String) {
        UserDefaults.standard.set(self[keyPath: keyPath], forKey: key)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * max(0, min(1, t))
    }
}
