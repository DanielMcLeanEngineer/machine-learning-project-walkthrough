# GorillaFlap — a Vision Pro movement game

A visionOS game that fuses **Gorilla Tag** locomotion with **Flappy Bird** altitude
control. You physically swing your arms to run *and* to fly, while constant gravity
pulls you down. Walls rush toward you with gaps at ever-changing **heights** — your
whole job is to be at the right altitude at the right moment.

The brief was: *run around like Gorilla Tag, fused with Flappy Bird so there's a height
to distinguish, simple assets, and movement as seamless as possible.* This is built
around exactly those three priorities.

## How it plays

- **Swing both arms down** (like hauling yourself forward / pushing off the ground).
  Hand tracking detects each downward swing.
- Every swing does two things at once:
  - adds an **upward flap** — harder swings lift you higher (Flappy Bird), and
  - adds **forward swing-energy** — keep swinging to keep your pace up (Gorilla Tag).
- **Gravity is always on.** Stop swinging and you sink.
- **Thread the glowing gaps.** Each wall has a fixed-size opening at a random height.
  The **amber** frame marks your *next* target; green frames are later walls.
- Clear a gap to score. Clip a wall and the run ends. Your best score is kept.

A head-locked HUD shows your score and a vertical **height gauge**: a green dot (you)
versus an amber band (the next gap's height), so reading altitude is instant.

## Why it feels seamless (and comfortable)

The player's camera never moves artificially. Instead, a single `worldRoot` entity is
slid around the still player:

- gaining altitude slides the world **down**,
- moving forward slides the world **toward** you.

Vestibular comfort comes from: a frame-synced fixed simulation step (clamped so a frame
hitch can't tunnel you through a wall), capped vertical speed and gentle gravity, a
faint ground grid for an optical-flow reference, no artificial yaw/roll (you still freely
turn your real head), and an optional **comfort vignette** that dims your periphery as
forward/vertical speed rises — the standard VR trick for reducing vection. Its strength
is a slider (default on, ~60%).

## Sound & haptic feedback

All "feel" is routed through one facade, `FeedbackEngine`, which the game calls with
semantic events (`flap`, `score`, `crash`, `startRun`, `endRun`).

**Sound** is fully procedural — synthesized into PCM buffers at launch and played via a
small `AVAudioEngine` graph, so there are still **no audio asset files**:
- *flap* — an airy upward whoosh that gets louder/brighter the harder you swing,
- *score* — a bright two-note (perfect-fifth) chime,
- *crash* — a low thud with a noise burst,
- *wind* — a soft, seamlessly looping ambience that runs only during a run.

**Haptics** — important platform note: **Apple Vision Pro has no built-in haptic
actuator the wearer can feel.** So haptics are implemented as a correct best-effort
path via `CoreHaptics` + `GameController`: if a haptic-capable controller is paired,
flaps/scores fire transient taps and crashes fire a short rumble; with no such
controller (the normal hand-tracking case) it's a clean no-op. The menu states this so
expectations are clear.

## Difficulty & scoring

The run gets harder the better you do (all curves live in `GameConfig`):

- **Gaps tighten** from `0.58` to `0.34` half-height over your first ~25 points.
- **Forward speed ramps** up by ~2.2 m/s over your first ~30 points.
- **Bonus coins** spawn in ~40% of gaps; grabbing one (fly through its center) is worth
  3 points and plays a bright "ting". Coins gently spin.
- **Combo**: passing through the *center* of a gap (not just squeaking through) builds a
  streak; each clean pass adds bonus points equal to the current combo (capped at 5),
  shown as a `COMBO ×N` badge. A sloppy-but-safe pass keeps your run alive but resets it.
- **Walls warm** from white toward red as difficulty rises, so the ramp is visible.

The HUD's amber target band now reflects the *actual* size of the next gap, so it visibly
shrinks as difficulty climbs. Distance travelled is shown on the HUD and the crash card.
Best score is persisted locally and submitted to Game Center when beaten.

## Game Center

`Leaderboard` (in `Game/`) authenticates the local player on launch and submits the best
score. It's fully best-effort — the game is identical if Game Center is unavailable or
declined. To light it up:

1. In **Signing & Capabilities**, add the **Game Center** capability to the target.
2. In **App Store Connect**, create a leaderboard and set its ID to match
   `Leaderboard.leaderboardID` (`com.danielmclean.gorillaflap.highscores`).

## Assets

Deliberately minimal — **everything is a RealityKit primitive** (boxes) with a tiny
material palette and a few emissive accent bars. No imported meshes, textures, or USDZ.
See `AssetFactory.swift`.

## Project layout

```
GorillaFlap/
  App/
    GorillaFlapApp.swift     // @main: menu window + full immersive space
  Game/
    GameConfig.swift         // fixed design defaults, all in one place
    GameSettings.swift       // live, persisted player calibration (read every frame)
    GameEngine.swift         // simulation + per-frame step, scoring, game-over
    ObstacleCourse.swift     // procedural pool of recyclable gap "windows"
    HandMotionTracker.swift  // ARKit hand tracking -> flap impulse + forward thrust
    FeedbackEngine.swift     // procedural spatial sound + best-effort controller haptics
    ComfortVignette.swift    // generated head-locked peripheral dimmer
    Leaderboard.swift        // best-effort Game Center auth + score submit
    AssetFactory.swift       // simple primitive visuals
  Views/
    MainMenuView.swift       // 2D start/restart + how-to
    CalibrationView.swift    // live sliders: swing sensitivity / lift / floatiness
    ImmersiveGameView.swift  // RealityView host + head-locked HUD
    GameHUDView.swift        // score + altitude gauge
```

## Calibration

The menu has a **Calibration** panel with three sliders, persisted across launches and
read by the simulation every frame — so you can drag them **while playing** and feel the
change instantly:

- **Swing sensitivity** — how hard you must swing for it to register (maps to the
  detection threshold, 1.6 → 0.45 m/s).
- **Lift strength** — multiplier on each swing's upward boost (0.6×–1.7×).
- **Floatiness** — scales gravity (1.4×–0.6×), from heavy to hang-time.
- **Comfort vignette** — how strongly the periphery dims during fast motion.

There's also a **Practice mode** toggle: hit a wall and you snap into the gap (combo
resets, soft cue) instead of crashing — ideal for learning the arm-swing timing before
going for a real score.

The in-headset HUD also has a quick swing-sensitivity +/- stepper and Pause / Restart /
Play Again buttons, so you never need the menu window mid-session. Defaults match the
original hand-tuned feel; **Reset** restores them. These layer on top
of `GameConfig`, which still holds the fixed design constants.

## Build & run

Requirements: **Xcode 16+**, **visionOS 2.0 SDK**.

1. Open `GorillaFlap.xcodeproj`.
2. Select the **GorillaFlap** scheme.
3. Run on **Apple Vision Pro** (device) or the **visionOS Simulator**.
   - Hand tracking only produces input on a real device; in the Simulator the world,
     menu, HUD, and obstacle flow all run, but you won't generate swings.
4. On first launch, accept the hand-tracking permission prompt.

The Xcode project uses a file-system-synchronized group, so any `.swift` file you add
under `GorillaFlap/` is picked up automatically — no manual project bookkeeping.

## Tuning

Open `GameConfig.swift`. Want floatier flight? Raise `flapImpulseBase` or soften
`gravity`. Faster runs? Raise `baseForwardSpeed` / `maxSwingBoost`. Harder gaps? Shrink
`gapHalfHeight` or widen `gapCenterRange`. Swings not registering? Lower
`swingSpeedThreshold`.
