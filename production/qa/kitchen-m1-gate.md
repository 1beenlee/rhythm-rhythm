# Kitchen M1 — Studio QA / handoff gate

Status: **IN_PROGRESS / NOT APPROVED**. This file is an acceptance checklist, not evidence of a completed playable slice.

## CCGS adapted reviewer gates
- [x] Read upstream studio approach and root `intent.md` / `what_to_avoid.md`.
- [x] Confirm a single Kitchen benchmark, existing archive preserved, web-first scope.
- [x] Probe owner-supplied MP4/MP3, record dimensions/duration/hashes.
- [x] Inspect representative frames, write observed scene states.
- [x] Derive **candidate** BPM and identify consistent MP4-vs-MP3 audio offset.
- [x] Verify **relative source-audio alignment** at native 44.1kHz (seven windows, 1,105 samples lag).
- [x] Video-wide heuristic scene-state scan (4,153 frames; not frame-level chart sign-off).
- [ ] Certify first downbeat, instrument/voice separation and event-specific audio timings.
- [ ] Enumerate all actual ingredient events with source time+frame provenance and uncertainty.
- [ ] Review and approve actual high-resolution kitchen art direction.
- [ ] Produce source art and export full chef animation poses, ingredients, cat and layered backdrops.
- [ ] Prove no blurry upscale, alpha halo/fringe, baked UI, or fake pose substitution.
- [ ] Have Game Director + 2D Artist approve a single complete visual sprite set.
- [ ] Owner sign-off for M1 before enabling M2 gameplay/audio engine implementation.

## Reviewer roles
**Game Director:** benchmark fidelity, scene transitions, interaction/cue intent.
**Tech Lead:** source timing, branch hygiene, architecture boundaries.
**Audio Director:** BPM hypothesis, cue/stem separation, audio-source alignment.
**2D Artist:** complete source-to-export sprite pipeline and visual quality.

## Progress
- Target branch: `feat/kitchen-benchmark`; benchmark media kept out of GitHub.
- Preliminary audio and scene-data receipts: `docs/research/source-audio-alignment.json`, `beat-grid-candidate.json`, `scene-state-candidates.json`; narrative: `kitchen-m1-addendum-2026-11-01.md`.
- Sprite production/export remains **BLOCKED by unsatisfactory image-generation output** (non-sprite dashboard); rejected outputs not committed.
- No M2 or M3 gameplay code written. No actual browser playtest occurred.
- No original reference media, archived Godot version, root intent/avoid documents or global agent settings modified.

## M2 entry requirements
Approved M1 art baseline OR explicit limited timing-spike exception; native-rate event-specific annotated cue/target ledger; source alignment receipt; owner-approved implementation scope.
