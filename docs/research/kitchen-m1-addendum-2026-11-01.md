# Kitchen M1 — native-rate sync & scene timing addendum

**Evidence date:** 2026-11-01 KST. **State:** preproduction observation and asset-spec refinement, not a completed chart or playtest.

## 1. Evidence-bearing audio recheck

Previously reported ~25.03ms relative MP4/MP3 displacement was from 11.025kHz exploratory audio. The follow-up re-decoded both source files at **44,100Hz** with FFmpeg, then correlated seven independent 0.65-second windows with ±90ms search space.

- MP3 content lags matching MP4-embedded audio by **1,105 samples = 25.056689ms** at all sampled starts (10, 20, 40, 65, 85, 105, 125 seconds).
- Normalized matched waveform correlations: **0.99835–0.99979**.
- Both media containers nominally start at zero. Their **decoded waveforms do not**. Encode/decode priming or export alignment is one possible cause, not proven.
- Conventions: `t_mp3 = t_mp4 + 1105/44100` for matched recorded audible content.
- Never conflate this source-to-source displacement with actual browser/device input latency or judge offset.

Complete compact test receipt: `docs/research/source-audio-alignment.json`.

## 2. Tempo / beat-grid hypothesis

Spectral onset strength was estimated from downsampled 11,025Hz mono MP3 (hop 256), then prominent onset peaks were folded onto a **132 BPM** period (0.45454545 seconds). Aggregate phase ≈ **0.291s modulo beat period in MP3**; adjusted video-audio phase ≈ **0.265943s modulo beat period**.

Independent MP3-window phases:
- 15–40s: 0.2895s
- 40–65s: 0.2955s
- 65–90s: 0.2885s
- 90–113s: 0.2920s

These are consistent enough to support **132 BPM as a working hypothesis**, not enough to certify downbeat or per-ingredient target timestamps. Musical percussion can occur at a half-beat offset and shift detected onset peaks. The provisional JSON `docs/research/beat-grid-candidate.json` deliberately has **zero verified hit events**. Avoid fake accuracy: offset estimation from onset sampling has millisecond-scale uncertainty and does **not** validate the 1ms judge requirement.

## 3. Full recording visual segmentation

All **4,153 frames** of the 640×360/30fps H.264 source were read, with color traces from fixed patches in the left kitchen window and upper wall. Nine-frame median filtering and simple RGB conditions identified these sustained states:

| Scene | Approximate video start | Approximate end | Interpretation |
|---|---:|---:|---|
| Kitchen gameplay | 12.53s | 77.93s | normal room; short flashes and stylizations interrupt |
| White / silhouette passage | 78.07s | 85.23s | predominantly washed-out scene |
| Underwater / marine | 85.27s | 98.57s | sustained blue sea treatment |
| Kitchen return | 99.80s | 117.80s | returns to ordinary kitchen |
| Ending / results | ~117.80s | 138.43s | requires manual screen-by-screen breakdown |

Exact cut boundaries are only **frame-quantized (33.33ms resolution)**, and the heuristic can miss fades or split overlays. Source `docs/research/scene-state-candidates.json` records technique, confidence and interruptions. Do not wire these approximations directly to animation/beat callbacks.

## 4. What is still unverified

- **Complete ingredient event transcript**: the supplied video has not yet been exhaustively frame-annotated into ingredient type, cue, target contact, input, response and matching audio sample timestamps. Recorded onsets alone are NOT input targets.
- **Exact downbeat and hit judgement windows**: calibration/analysis required before runtime implementation.
- **Final sprite atlas**: attempts to generate an illustrated asset board produced unrelated dashboard/infographic compositions, **not the required separated transparent character pose sprites**. Rejected; no image has been marked production-ready or pushed as a game asset.
- **Original high-res sprite illustration source**: absent; no substitute from low-res video enlargements, simple geometry or cropped dashboard elements.
- **End-to-end browser feel**: not implemented, not playtested.

## 5. Next M1 handoff

1. Construct a verified manual/semiautomated **ingredient ledger** with video frame ID + audio cue timestamp + confidence for at least two full example phrases (single catch and rapid triple), then cover the rest of the song. Do not infer input events solely from spectral peaks.
2. Produce one **cohesive** high-res, genuinely separated source-to-export sprite pack following `design/assets/sprite-atlas-contract.json`: chef pose frames, ingredient poses, cat reaction frames, 4 scene states. Check alpha-fringe, silhouette and constant registration/catch pivot.
3. Perform visual review using actual exported images; record rejected drafts, not false completed checkboxes.
4. Keep M2 stopped until owner approves M1 acceptance or specifically authorizes a timing-only exception.

## Reproduction context

FFmpeg decodes both audio streams to 44.1kHz mono. The positive lag is defined as the later MP3 match relative to MP4. Scene detector operates only on video sample pixels. See the repo JSON receipts for exact windows, values, and limitations. The supplied copyrighted reference media is not included in the repository.
