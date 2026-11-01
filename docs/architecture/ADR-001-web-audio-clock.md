# ADR-001 — Web-first rendering and authoritative audio-clock contract

**Status:** PROPOSED — M1 architecture only; implementation begins M2 after gate approval.

## Decision
- TypeScript + Vite for future web runtime, PixiJS/WebGL for sprite rendering, native Web Audio API for music and scheduled cues.
- Chart data is JSON with beat/measure indices, tempo map, scheduled cue times, expected input windows, and animation state transition keys. Keep chart and judge pure/portable to Unity.
- An `AudioContext` drives the authoritative clock. Buffered tracks/cues are scheduled via `AudioBufferSourceNode.start(when)`. Rendering samples the transport, never declares hit events on animation frames.
- Convert `KeyboardEvent.timeStamp`/input event timestamp on the performance timeline using a measured `AudioContext.getOutputTimestamp()` correspondence. Distinguish sound-output, physical-input and user adjustment offsets; do not double-apply latency.
- Explicit first-user-gesture audio unlock, pause/resume ownership, device-change recalibration and unsupported-browser fallback.
- No autoplay before gesture; no setInterval-based beat clock; no 3-second soundtrack loop; no fabricated “1ms guaranteed on any PC” statement.

## Quality targets (to validate, not yet reached)
1. Sample-indexed offline audio scheduling <=1ms from intended timestamp.
2. Deterministic judge math <=1ms with controlled synthetic inputs and no accumulated floating-time drift.
3. End-to-end human input and perceived output: measured per browser/audio device, documented p50/p95 and calibration procedure; *not* promised as globally <=1ms.
4. 60Hz rendering cannot reveal a visual frame with 1ms timing; prefer interpolated, beat-anchored poses and visually honest feedback.
5. Pausing or browser suspension does not cause music/chart/skipped events to diverge.

## Explicitly not decided in M1
Final BPM/downbeat, calibrated latency offsets, exact hit windows, decoded BGM master choice, 2D atlas dimensions after frame review, production browser support matrix.

## Source anchors
- `intent.md` and `what_to_avoid.md` govern quality.
- `docs/research/kitchen-benchmark-m1.md` logs exploratory measurements and limitations.
- MDN: https://developer.mozilla.org/en-US/docs/Web/API/AudioBufferSourceNode/start and https://developer.mozilla.org/en-US/docs/Web/API/AudioContext/getOutputTimestamp
