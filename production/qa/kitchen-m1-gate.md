# Kitchen M1 — Studio QA / handoff gate

Status: **IN_PROGRESS / NOT APPROVED**. This file is an acceptance checklist, not evidence of a completed playable slice.

## CCGS adapted reviewer gates
- [x] Read upstream studio approach and root `intent.md` / `what_to_avoid.md`.
- [x] Confirm a single Kitchen benchmark, existing archive preserved, web-first scope.
- [x] Probe owner-supplied MP4/MP3, record dimensions/duration/hashes.
- [x] Inspect representative frames, write observed scene states.
- [x] Derive **candidate** BPM and identify consistent MP4-vs-MP3 audio offset.
- [ ] Validate tempo/downbeat at native sample rate with music/cue segmentation.
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
- Confirmed target branch: `feat/kitchen-benchmark`.
- No M2 or M3 code written.
- No live browser game or visual playtest performed.
- No existing archive, main branch, original benchmark media or internal tools modified.

## M2 entry requirements
Approved M1 visual asset baseline or explicit limited timing-spike exception; native-rate annotated beat/cue timeline; source alignment receipt; implementation and measurable QA acceptance criteria.
