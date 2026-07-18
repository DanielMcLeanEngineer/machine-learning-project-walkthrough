# Changelog

All notable changes to GorillaFlap are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## [1.0.0] — Unreleased

First feature-complete build: a visionOS game fusing Gorilla Tag arm-swing locomotion
with Flappy Bird altitude control.

### Gameplay
- Hand-tracked arm swings drive both forward thrust and upward "flaps"; constant gravity.
- Procedural, recyclable obstacle "windows" with gaps at varying heights.
- Score-based difficulty ramp: gaps tighten and forward speed rises.
- Bonus coins in ~40% of gaps; spinning collectibles worth 3 points each.
- Precision combo system rewarding centered passes with capped bonus points.
- Practice mode: snap into the gap instead of crashing, for learning the swing.

### Feel
- Fully procedural, asset-free spatial audio (flap, score, coin, pass-by whoosh, crash,
  speed-coupled wind ambience).
- Best-effort CoreHaptics via a connected game controller (Vision Pro has no haptics).
- Optional comfort vignette that dims the periphery during fast motion.
- Difficulty-driven wall color shift (white → red).

### UI / systems
- Head-locked HUD: score, distance, height gauge, combo badge, in-headset controls
  (pause / restart / play again, quick swing-sensitivity stepper).
- Live, persisted calibration sliders (swing sensitivity, lift, floatiness, comfort).
- Local top-5 high-score table; best score persisted.
- Game Center authentication, score submission, and native leaderboard dashboard.

### Accessibility & robustness
- Honors system Reduce Motion (comfort-vignette floor, reduced top speed).
- Auto-pauses when the scene backgrounds or the immersive space is dismissed.
- Accessibility labels/values on HUD controls and the height gauge.
