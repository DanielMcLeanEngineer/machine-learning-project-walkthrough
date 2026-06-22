import ARKit
import RealityKit
import QuartzCore
import simd

/// Reads ARKit hand anchors and turns physical arm motion into game input.
///
/// Design: a Gorilla-Tag-style downward arm swing (pushing down/back, as if hauling
/// yourself up) is the single verb. A swing simultaneously:
///   * adds an upward "flap" impulse (Flappy Bird), scaled by how hard you swung, and
///   * adds forward swing-energy (Gorilla Tag locomotion).
///
/// Both hands are tracked independently so alternating swings give a natural running
/// cadence and a fast left-right rhythm keeps you both moving and aloft.
@MainActor
final class HandMotionTracker: ObservableObject {

    /// Set to `true` once authorization succeeds, so the UI can prompt if denied.
    @Published var isTracking = false
    @Published var authorizationDenied = false

    private let session = ARKitSession()
    private let provider = HandTrackingProvider()

    private var hands: [HandAnchor.Chirality: HandState] = [:]

    /// Upward impulse accumulated since the last `consumeFlapImpulse()` call.
    private var pendingFlap: Float = 0
    /// Forward swing energy, decayed every tick by the game loop.
    private(set) var swingEnergy: Float = 0

    private struct HandState {
        var lastY: Float
        var lastTime: TimeInterval
        var lastSwingTime: TimeInterval = 0
    }

    func start() async {
        guard HandTrackingProvider.isSupported else { return }
        do {
            try await session.run([provider])
            isTracking = true
            await consumeUpdates()
        } catch {
            authorizationDenied = true
        }
    }

    func stop() {
        session.stop()
        isTracking = false
        hands.removeAll()
        pendingFlap = 0
        swingEnergy = 0
    }

    private func consumeUpdates() async {
        for await update in provider.anchorUpdates {
            guard update.event != .removed else {
                hands[update.anchor.chirality] = nil
                continue
            }
            ingest(update.anchor)
        }
    }

    private func ingest(_ anchor: HandAnchor) {
        guard anchor.isTracked else { return }
        // Wrist world position from the anchor transform's translation column.
        let t = anchor.originFromAnchorTransform
        let y = t.columns.3.y
        let now = CACurrentMediaTime()

        guard var state = hands[anchor.chirality] else {
            hands[anchor.chirality] = HandState(lastY: y, lastTime: now)
            return
        }

        let dt = Float(now - state.lastTime)
        if dt > 0.0001 {
            let verticalSpeed = (y - state.lastY) / dt   // negative == moving down
            let downwardSpeed = -verticalSpeed

            let offCooldown = (now - state.lastSwingTime) > GameConfig.swingCooldown
            if downwardSpeed > GameConfig.swingSpeedThreshold && offCooldown {
                registerSwing(strength: downwardSpeed)
                state.lastSwingTime = now
            }
        }

        state.lastY = y
        state.lastTime = now
        hands[anchor.chirality] = state
    }

    private func registerSwing(strength: Float) {
        // Map swing speed (m/s, starting at the threshold) to a 1...maxScale multiplier.
        let over = strength - GameConfig.swingSpeedThreshold
        let scale = min(1 + over, GameConfig.flapImpulseMaxScale)
        pendingFlap += GameConfig.flapImpulseBase * scale
        swingEnergy = min(swingEnergy + GameConfig.swingEnergyPerSwing, GameConfig.maxSwingBoost)
    }

    /// Returns and clears the upward impulse banked since the last call.
    func consumeFlapImpulse() -> Float {
        defer { pendingFlap = 0 }
        return pendingFlap
    }

    /// Bleed off forward swing energy over time so you must keep swinging to keep pace.
    func decaySwingEnergy(deltaTime: Float) {
        swingEnergy = max(0, swingEnergy - GameConfig.swingEnergyDecay * deltaTime)
    }
}
