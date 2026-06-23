import RealityKit
import SwiftUI
import Combine
import simd

/// The simulation. Holds the RealityKit world, steps the physics every frame, folds in
/// hand-tracking input, and drives scoring / game-over.
///
/// Movement is rendered by sliding a single `worldRoot` entity rather than moving the
/// player: as the player gains altitude the world drops, and as they advance the world
/// slides toward them. Keeping the player camera physically still is what makes the
/// locomotion seamless and comfortable.
@MainActor
final class GameEngine: ObservableObject {

    enum Phase { case ready, playing, gameOver }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var score = 0
    @Published private(set) var bestScore = 0
    /// Meters travelled this run — a secondary stat shown on the HUD / game-over card.
    @Published private(set) var distance: Float = 0
    /// Current altitude and the next target gap altitude, for the HUD's height gauge.
    @Published private(set) var altitude: Float = GameConfig.startAltitude
    @Published private(set) var targetAltitude: Float = GameConfig.startAltitude
    /// Half-height of the next gap, so the HUD band reflects the live difficulty.
    @Published private(set) var targetGapHalf: Float = GameConfig.gapHalfHeight

    private let bestScoreKey = "gf.bestScore"

    let worldRoot = Entity()

    private var course: ObstacleCourse!
    private let hands: HandMotionTracker
    private let feedback: FeedbackEngine
    private let settings: GameSettings

    // Player state in course coordinates.
    private var verticalVelocity: Float = 0
    private var forwardDistance: Float = 0

    private var updateSubscription: EventSubscription?

    init(hands: HandMotionTracker, feedback: FeedbackEngine, settings: GameSettings) {
        self.hands = hands
        self.feedback = feedback
        self.settings = settings
        self.bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
    }

    func setup(content: RealityViewContent) {
        if course == nil {
            course = ObstacleCourse(worldRoot: worldRoot)
            course.build()
        }
        updateSubscription = content.subscribe(to: SceneEvents.Update.self) { [weak self] event in
            self?.tick(deltaTime: Float(event.deltaTime))
        }
        applyWorldTransform()
    }

    func startGame() {
        score = 0
        distance = 0
        verticalVelocity = 0
        forwardDistance = 0
        altitude = GameConfig.startAltitude
        course.reset()
        course.refreshNextTarget(playerDistance: forwardDistance)
        targetAltitude = course.nextGapCenter(playerDistance: forwardDistance) ?? GameConfig.startAltitude
        targetGapHalf = course.nextGapHalf(playerDistance: forwardDistance) ?? GameConfig.gapHalfHeight
        applyWorldTransform()
        feedback.startRun()
        phase = .playing
    }

    func endGame() {
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
            Task { await Leaderboard.shared.submit(score: bestScore) }
        }
        feedback.endRun()
        phase = .gameOver
    }

    // MARK: - Frame step

    private func tick(deltaTime: Float) {
        guard phase == .playing, deltaTime > 0 else { return }
        let dt = min(deltaTime, 1.0 / 30.0)   // clamp to avoid tunneling on hitches

        // Vertical: gravity + banked flap impulses, integrated and clamped.
        verticalVelocity += settings.effectiveGravity * dt
        let flapImpulse = hands.consumeFlapImpulse()
        if flapImpulse > 0 {
            verticalVelocity += flapImpulse
            let maxImpulse = GameConfig.flapImpulseBase * GameConfig.flapImpulseMaxScale * settings.liftMultiplier
            feedback.flap(intensity: flapImpulse / maxImpulse)
        }
        verticalVelocity = max(-GameConfig.maxVerticalSpeed, min(GameConfig.maxVerticalSpeed, verticalVelocity))
        altitude += verticalVelocity * dt

        if altitude <= GameConfig.minAltitude {
            altitude = GameConfig.minAltitude
            verticalVelocity = 0
        } else if altitude >= GameConfig.maxAltitude {
            altitude = GameConfig.maxAltitude
            verticalVelocity = min(verticalVelocity, 0)
        }

        // Forward: score-scaled base drift + swing-energy boost, which bleeds off.
        let forwardSpeed = GameConfig.forwardBaseSpeed(forScore: score) + hands.swingEnergy
        hands.decaySwingEnergy(deltaTime: dt)
        let previousDistance = forwardDistance
        forwardDistance += forwardSpeed * dt
        distance = forwardDistance

        course.animate(deltaTime: dt)

        // Bonus coins grabbed mid-gap.
        let coins = course.collectCoins(previousDistance: previousDistance, currentDistance: forwardDistance, altitude: altitude)
        if coins > 0 {
            score += coins * GameConfig.coinValue
            feedback.coin()
        }

        // Collisions / scoring against any obstacle plane crossed this frame.
        switch course.evaluate(previousDistance: previousDistance, currentDistance: forwardDistance, altitude: altitude) {
        case .scored:
            score += 1
            feedback.score()
            course.recycle(playerDistance: forwardDistance, score: score)
            course.refreshNextTarget(playerDistance: forwardDistance)
        case .crashed:
            feedback.crash()
            applyWorldTransform()
            endGame()
            return
        case .none:
            break
        }

        course.recycle(playerDistance: forwardDistance, score: score)
        targetAltitude = course.nextGapCenter(playerDistance: forwardDistance) ?? targetAltitude
        targetGapHalf = course.nextGapHalf(playerDistance: forwardDistance) ?? targetGapHalf
        applyWorldTransform()
    }

    /// Slide the world so the player's virtual position maps to the real, still camera.
    private func applyWorldTransform() {
        worldRoot.position = [0, -altitude, forwardDistance]
    }
}
