import Foundation

/// Central place for every tunable number in the game. Keeping them here makes it
/// trivial to retune feel without hunting through the simulation code.
enum GameConfig {

    // MARK: Vertical (Flappy Bird) feel
    /// Constant downward pull on the player's altitude, in meters / second².
    static let gravity: Float = -3.2
    /// Upward velocity added by a single arm swing, scaled by how hard you swung.
    static let flapImpulseBase: Float = 1.6
    /// Hardest swing can multiply the base impulse by up to this much.
    static let flapImpulseMaxScale: Float = 2.2
    /// Player altitude is clamped to this range (meters above the start line).
    static let minAltitude: Float = -0.2
    static let maxAltitude: Float = 3.6
    /// Vertical velocity is clamped so a flurry of flaps can't launch you instantly.
    static let maxVerticalSpeed: Float = 4.0

    // MARK: Forward (Gorilla Tag) feel
    /// You always drift forward at least this fast (meters / second).
    static let baseForwardSpeed: Float = 2.6
    /// Vigorous swinging adds this much on top of the base speed.
    static let maxSwingBoost: Float = 3.2
    /// How quickly accumulated swing energy bleeds off when you stop swinging.
    static let swingEnergyDecay: Float = 1.4
    /// Each registered swing adds this much swing energy (drives forward boost).
    static let swingEnergyPerSwing: Float = 0.55

    // MARK: Obstacles
    /// Number of obstacle "windows" kept alive and recycled at any time.
    static let obstaclePoolSize: Int = 6
    /// Spacing between consecutive obstacles along the course (meters).
    static let obstacleSpacing: Float = 7.0
    /// Half-height of the gap you fly through. Constant so the difficulty is purely
    /// "find the right altitude", and so obstacles can be rigid recyclable prefabs.
    static let gapHalfHeight: Float = 0.55
    /// Random gap-center altitude is chosen in this band.
    static let gapCenterRange: ClosedRange<Float> = 0.4...3.0
    /// How far behind the player an obstacle may fall before it gets recycled ahead.
    static let recycleBehind: Float = 2.5
    /// Effective collision radius of the player when checking gap fit.
    static let playerRadius: Float = 0.22

    // MARK: Hand tracking
    /// A downward wrist speed above this (m/s) counts as a swing/flap.
    static let swingSpeedThreshold: Float = 0.9
    /// Per-hand cooldown so one physical swing fires exactly once (seconds).
    static let swingCooldown: TimeInterval = 0.28

    // MARK: Comfort
    /// Forward distance between the start line and the first obstacle.
    static let startRunway: Float = 6.0
    /// Player's starting altitude (roughly eye height of the easiest first gap).
    static let startAltitude: Float = 1.4
}
