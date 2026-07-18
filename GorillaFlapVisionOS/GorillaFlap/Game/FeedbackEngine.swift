import AVFoundation
import GameController
import CoreHaptics

/// One entry point for all game "feel": sound + haptics. The game calls semantic
/// events (`flap`, `score`, `crash`, `startRun`, `endRun`) and this routes them to the
/// audio synth and, when a haptic-capable controller is connected, to CoreHaptics.
///
/// Platform note: Apple Vision Pro has no built-in haptic actuator the wearer feels, so
/// haptics here are a genuine but best-effort path — they fire only on a paired,
/// haptic-capable game controller and are otherwise a clean no-op. Sound is the
/// always-on layer and is synthesized at runtime (no audio asset files).
@MainActor
final class FeedbackEngine: ObservableObject {

    private let sound = SoundSynth()
    private let haptics = ControllerHaptics()

    /// Whether anything haptic is currently wired up — surfaced for the UI/README.
    var hapticsAvailable: Bool { haptics.isAvailable }

    func prepare() {
        sound.prepare()
        haptics.prepare()
    }

    func startRun() {
        sound.startWind()
    }

    func endRun() {
        sound.stopWind()
    }

    func pauseRun() {
        sound.stopWind()
    }

    func resumeRun() {
        sound.startWind()
    }

    /// Continuously couple ambience to motion. `speed` is 0...1 (normalized).
    func updateMotion(speed: Float) {
        sound.setWindLevel(0.12 + 0.22 * max(0, min(1, speed)))
    }

    /// `intensity` is 0...1 — how hard the swing was.
    func flap(intensity: Float) {
        let i = max(0, min(1, intensity))
        sound.playFlap(intensity: i)
        haptics.transient(intensity: 0.5 + 0.5 * i, sharpness: 0.4)
    }

    func score() {
        sound.playScore()
        haptics.transient(intensity: 0.8, sharpness: 0.7)
    }

    /// Pass-by swish; `nearness` 0 (dead center) … 1 (skimmed the edge).
    func pass(nearness: Float) {
        sound.playWhoosh(volume: 0.2 + 0.6 * max(0, min(1, nearness)))
        if nearness > 0.8 { haptics.transient(intensity: 0.5, sharpness: 0.5) }
    }

    func coin() {
        sound.playCoin()
        haptics.transient(intensity: 0.6, sharpness: 0.9)
    }

    func crash() {
        sound.stopWind()
        sound.playCrash()
        haptics.rumble(intensity: 1.0, sharpness: 0.2, duration: 0.45)
    }
}

// MARK: - Procedural audio

/// Synthesizes every sound effect into PCM buffers at startup and plays them through a
/// small AVAudioEngine graph. Asset-free by design, matching the game's primitive look.
@MainActor
private final class SoundSynth {

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private let flapNode = AVAudioPlayerNode()
    private let scoreNode = AVAudioPlayerNode()
    private let coinNode = AVAudioPlayerNode()
    private let whooshNode = AVAudioPlayerNode()
    private let crashNode = AVAudioPlayerNode()
    private let windNode = AVAudioPlayerNode()

    private var flapBuffer: AVAudioPCMBuffer!
    private var scoreBuffer: AVAudioPCMBuffer!
    private var coinBuffer: AVAudioPCMBuffer!
    private var whooshBuffer: AVAudioPCMBuffer!
    private var crashBuffer: AVAudioPCMBuffer!
    private var windBuffer: AVAudioPCMBuffer!

    private var started = false

    func prepare() {
        guard !started else { return }
        started = true

        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        flapBuffer = makeFlap()
        scoreBuffer = makeScore()
        coinBuffer = makeCoin()
        whooshBuffer = makeWhoosh()
        crashBuffer = makeCrash()
        windBuffer = makeWind()

        for node in [flapNode, scoreNode, coinNode, whooshNode, crashNode, windNode] {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }
        engine.prepare()
        try? engine.start()
    }

    func playFlap(intensity: Float) {
        guard engine.isRunning else { return }
        flapNode.volume = 0.35 + 0.55 * intensity
        flapNode.scheduleBuffer(flapBuffer, at: nil, options: .interrupts, completionHandler: nil)
        flapNode.play()
    }

    func playScore() {
        guard engine.isRunning else { return }
        scoreNode.scheduleBuffer(scoreBuffer, at: nil, options: .interrupts, completionHandler: nil)
        scoreNode.play()
    }

    func playCoin() {
        guard engine.isRunning else { return }
        coinNode.scheduleBuffer(coinBuffer, at: nil, options: .interrupts, completionHandler: nil)
        coinNode.play()
    }

    func playWhoosh(volume: Float) {
        guard engine.isRunning else { return }
        whooshNode.volume = max(0, min(1, volume))
        whooshNode.scheduleBuffer(whooshBuffer, at: nil, options: .interrupts, completionHandler: nil)
        whooshNode.play()
    }

    func playCrash() {
        guard engine.isRunning else { return }
        crashNode.scheduleBuffer(crashBuffer, at: nil, options: .interrupts, completionHandler: nil)
        crashNode.play()
    }

    func startWind() {
        guard engine.isRunning else { return }
        windNode.volume = 0.14
        windNode.scheduleBuffer(windBuffer, at: nil, options: .loops, completionHandler: nil)
        windNode.play()
    }

    func stopWind() {
        windNode.stop()
    }

    func setWindLevel(_ level: Float) {
        windNode.volume = level
    }

    // MARK: Buffer synthesis

    private func makeBuffer(seconds: Double, _ fill: (_ i: Int, _ t: Float, _ frames: Int) -> Float) -> AVAudioPCMBuffer {
        let frames = Int(seconds * format.sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]
        for i in 0..<frames {
            let t = Float(i) / Float(format.sampleRate)
            data[i] = fill(i, t, frames)
        }
        return buffer
    }

    /// Airy upward "whoosh": filtered noise with a quick attack and exponential decay,
    /// brightened by a small rising tone so harder swings read as more lift.
    private func makeFlap() -> AVAudioPCMBuffer {
        var last: Float = 0
        return makeBuffer(seconds: 0.20) { i, t, _ in
            let decay = expf(-t * 14)
            let attack = min(1, t * 60)
            let noise = Float.random(in: -1...1)
            last = last * 0.85 + noise * 0.15            // cheap low-pass for "air"
            let sweep = sinf(2 * .pi * (320 + 900 * t) * t) * 0.25
            return (last * 0.8 + sweep) * decay * attack * 0.6
        }
    }

    /// Bright two-note chime (a perfect fifth) — clean reward cue.
    private func makeScore() -> AVAudioPCMBuffer {
        return makeBuffer(seconds: 0.32) { _, t, _ in
            let f: Float = t < 0.12 ? 880 : 1320
            let local = t < 0.12 ? t : t - 0.12
            let decay = expf(-local * 9)
            let tone = sinf(2 * .pi * f * t)
            let harmonic = 0.3 * sinf(2 * .pi * f * 2 * t)
            return (tone + harmonic) * decay * 0.35
        }
    }

    /// Quick bright "ting" for grabbing a coin — a high sine with a fast decay.
    private func makeCoin() -> AVAudioPCMBuffer {
        return makeBuffer(seconds: 0.18) { _, t, _ in
            let decay = expf(-t * 16)
            let tone = sinf(2 * .pi * 1760 * t)
            let shimmer = 0.4 * sinf(2 * .pi * 2640 * t)
            return (tone + shimmer) * decay * 0.3
        }
    }

    /// A short airy "pass-by" swish — band-passed noise with a symmetric swell, played
    /// louder the closer you skim a wall edge.
    private func makeWhoosh() -> AVAudioPCMBuffer {
        var last: Float = 0
        return makeBuffer(seconds: 0.24) { _, t, _ in
            let env = sinf(.pi * min(1, t / 0.24))   // fade in and out
            let noise = Float.random(in: -1...1)
            last = last * 0.8 + noise * 0.2
            return last * env * 0.6
        }
    }

    /// Low thud: a short low sine punch mixed with a fast-decaying noise burst.
    private func makeCrash() -> AVAudioPCMBuffer {
        return makeBuffer(seconds: 0.45) { _, t, _ in
            let bodyDecay = expf(-t * 7)
            let body = sinf(2 * .pi * (90 - 30 * t) * t) * bodyDecay
            let noise = Float.random(in: -1...1) * expf(-t * 22)
            return (body * 0.7 + noise * 0.5) * 0.6
        }
    }

    /// Seamless 2-second wind loop: low-passed noise with a slow amplitude swell so the
    /// loop point is inaudible.
    private func makeWind() -> AVAudioPCMBuffer {
        var last: Float = 0
        return makeBuffer(seconds: 2.0) { _, t, _ in
            let noise = Float.random(in: -1...1)
            last = last * 0.96 + noise * 0.04            // heavier low-pass = soft rush
            let swell = 0.6 + 0.4 * sinf(2 * .pi * 0.5 * t)
            return last * swell
        }
    }
}

// MARK: - Controller haptics (best effort)

/// Drives CoreHaptics through a connected, haptic-capable game controller. On a Vision
/// Pro with no such controller paired this stays a no-op — the headset itself has no
/// haptic actuator.
@MainActor
private final class ControllerHaptics {

    private var hapticEngine: CHHapticEngine?
    private var observers: [NSObjectProtocol] = []

    var isAvailable: Bool { hapticEngine != nil }

    func prepare() {
        wireCurrentController()
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.wireCurrentController() }
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.hapticEngine = nil }
        })
    }

    private func wireCurrentController() {
        guard hapticEngine == nil,
              let controller = GCController.controllers().first(where: { $0.haptics != nil }),
              let engine = controller.haptics?.createEngine(withLocality: .default) else { return }
        engine.isAutoShutdownEnabled = true
        try? engine.start()
        hapticEngine = engine
    }

    /// A single tap — used for flaps and scoring.
    func transient(intensity: Float, sharpness: Float) {
        play(events: [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                .init(parameterID: .hapticIntensity, value: intensity),
                .init(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0)
        ])
    }

    /// A sustained buzz — used for crashes.
    func rumble(intensity: Float, sharpness: Float, duration: TimeInterval) {
        play(events: [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                .init(parameterID: .hapticIntensity, value: intensity),
                .init(parameterID: .hapticSharpness, value: sharpness)
            ], relativeTime: 0, duration: duration)
        ])
    }

    private func play(events: [CHHapticEvent]) {
        guard let hapticEngine else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // A failed haptic should never affect gameplay.
        }
    }
}
