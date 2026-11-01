# M1 Asset Manifest — production tracking

**NO production-ready sprite, separated pose sheet, or approved music master is checked in.** Reject infographic-like outputs and low-resolution source-frame crops.

| Asset group | Art direction/spec | Export required | M1 status |
|---|---|---|---|
| Kitchen back/mid/foreground | `design/art/art-bible.md` | layered high-resolution scene, separate UI and text | SPECIFIED — NOT PRODUCED |
| Chef body, head, hands | `design/assets/sprite-atlas-contract.json` | registered transparent 8-state/pose sprites | SPECIFIED — NOT PRODUCED |
| Tomatoes, yellow pepper, broccoli | same contract | distinct flight and catch sprites | SPECIFIED — NOT PRODUCED |
| Cat and scene props | same contract | blink and independent success/miss reaction sprites | SPECIFIED — NOT PRODUCED |
| Day / white / marine / return scenes | `docs/research/scene-state-candidates.json` | separate background layers, verified transitions | TIME SEGMENTS OBSERVED — ART NOT PRODUCED |
| Music/cues/beat chart | `docs/research/source-audio-alignment.json`, `beat-grid-candidate.json` | native-rate aligned cue and actual input ledger | RELATIVE ALIGNMENT VERIFIED; EVENT CHART NOT PRODUCED |
| UI | Art Bible | separate glyph-safe user interface, no baked UI | SPECIFIED — NOT PRODUCED |

## Recorded rejection
Image generation in the follow-up session returned **status dashboard/infographic art instead of a transparent multi-pose sprite atlas** on two attempts. Neither result meets the root `what_to_avoid.md`; therefore **no art asset is marked accepted**. Do not crop/repackage these low-resolution dashboard images as game sprites.

## Next acceptance
Only promote a production set after inspecting the actual transparent sprites and full kitchen composite, pose alignment, clean alpha, native resolution, scene layers, and true catch/recovery motion. Record provenance and owner approval.

Reference video and MP3 remain outside this repository. The mention of 12 earlier v3 reference images in intent.md is historical; full original sources were not independently recovered during this M1 pass.
