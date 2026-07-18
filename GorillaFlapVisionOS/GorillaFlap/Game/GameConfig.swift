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
    /// Starting (easiest) half-height of the gap you fly through.
    static let gapHalfHeight: Float = 0.58
    /// Hardest (smallest) half-height the gap shrinks to as the score climbs.
    static let gapHalfHeightMin: Float = 0.34
    /// Random gap-center altitude is chosen in this band.
    static let gapCenterRange: ClosedRange<Float> = 0.4...3.0
    /// How far behind the player an obstacle may fall before it gets recycled ahead.
    static let recycleBehind: Float = 2.5
    /// Effective collision radius of the player when checking gap fit.
    static let playerRadius: Float = 0.22

    // MARK: Difficulty ramp
    /// Score at which the gap reaches its smallest size.
    static let gapTightenByScore: Float = 25
    /// Score at which forward speed reaches its fastest.
    static let speedRampByScore: Float = 30
    /// Extra forward speed added on top of `baseForwardSpeed` at max difficulty.
    static let maxDifficultySpeedBonus: Float = 2.2

    // MARK: Combo (precision passes)
    /// A pass counts as "clean" when the center offset ratio is within this (0 = center).
    static let cleanPassThreshold: Float = 0.45
    /// Bonus points per clean pass = current combo, capped here.
    static let maxComboBonus: Int = 5

    // MARK: Collectibles
    /// Fraction of obstacles that spawn a bonus coin in the center of the gap.
    static let coinSpawnChance: Float = 0.4
    /// Points awarded for collecting a coin.
    static let coinValue: Int = 3
    /// How close (meters) the player altitude must be to grab the coin.
    static let coinGrabRadius: Float = 0.35

    /// Gap half-height for a given score — eases from `gapHalfHeight` to `gapHalfHeightMin`.
    static func gapHalf(forScore score: Int) -> Float {
        let t = min(Float(score) / gapTightenByScore, 1)
        return gapHalfHeight + (gapHalfHeightMin - gapHalfHeight) * t
    }

    /// Base forward speed for a given score — ramps from `baseForwardSpeed` upward.
    static func forwardBaseSpeed(forScore score: Int) -> Float {
        let t = min(Float(score) / speedRampByScore, 1)
        return baseForwardSpeed + maxDifficultySpeedBonus * t
    }

    /// Whether a player at `altitude` fits through a gap centred at `gapCenter` with the
    /// given half-height, accounting for the player's radius. Pure and unit-tested.
    static func fits(altitude: Float, gapCenter: Float, gapHalf: Float) -> Bool {
        abs(altitude - gapCenter) <= gapHalf - playerRadius
    }

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
