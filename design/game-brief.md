# Kitchen — Lean Game Brief (CCGS minimal, M1)

## Goal
Reproduce one benchmark: 「下ごしらえ」 from リズム天国 ミラクルスターズ, using owner-provided 2026 no-miss gameplay/audio as the authoritative observational reference. The player must anticipate ingredients and catch on the musical cue, with natural pose/sound feedback. No second game is in scope.

## Player experience
Audio-led call/response, readable anticipation, immediate physical catch, charming expressive reactions, longer complete musical progression and scene changes. Reference fidelity is judged by owner playtesting, not by “runs without crashing.”

## Core sequence
Introduction/instruction → kitchen performance → changing screen treatments → end/results. Observed visuals are documented in `docs/research/kitchen-benchmark-m1.md`. **Do not treat approximate scene sampling as a verified chart.**

## Known vs unresolved
- Known: main kitchen has back-facing chef, layered counters/bowls, flying vegetables; staged changes to monochrome/green/underwater background.
- Known from gameplay guide: catch incoming vegetables, fast triple response after yellow vegetable.
- Strong audio *candidate*: 132 BPM in music sections (not approved as master tempo).
- Unresolved: sample-aligned downbeat, whole-chart timestamps, actual hit windows, all cue variants, input rules and exact animation frames.

## Approved build strategy
1. M1: art research, unified asset set, event observation and verification plan. No gameplay code yet.
2. M2: browser-native music-clock synchronization and per-device calibration.
3. M3: sprite-based interactive vertical slice, owner-approved feel, then full song and results.

## Rejection conditions
All of `what_to_avoid.md`, including placeholder primitives, dirty alpha borders, blown-up thumbnails, baked UI, generic loops, missed audio alignment, insufficient warning, fake animation, keyboard mapping regressions.

## Platform
Web-first: TypeScript + Vite + PixiJS + native Web Audio. Keep chart, grading and animation-state definitions independent of PixiJS/Web APIs for a potential Unity port.
