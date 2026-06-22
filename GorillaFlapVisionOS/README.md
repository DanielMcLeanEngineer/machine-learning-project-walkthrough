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
faint ground grid for an optical-flow reference, and no artificial yaw/roll — you still
freely turn your real head.

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
    GameConfig.swift         // every tunable number in one place
    GameEngine.swift         // simulation + per-frame step, scoring, game-over
    ObstacleCourse.swift     // procedural pool of recyclable gap "windows"
    HandMotionTracker.swift  // ARKit hand tracking -> flap impulse + forward thrust
    AssetFactory.swift       // simple primitive visuals
  Views/
    MainMenuView.swift       // 2D start/restart + how-to
    ImmersiveGameView.swift  // RealityView host + head-locked HUD
    GameHUDView.swift        // score + altitude gauge
```

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
