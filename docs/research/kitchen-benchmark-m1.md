# Kitchen 「下ごしらえ」 — source media inspection, M1 receipt

**Date:** 2026-11-01 KST
**Status:** OBSERVED / PRELIMINARY. Not a complete transcription, BPM certification, frame-accurate chart, or game implementation.

## Media identity
Owner-provided files, supplied in current conversation:
- MP4: `「下ごしらえ」ノーミスクリア！【 リズム天国 ミラクルスターズ 】.mp4`; SHA-256 `8ea44155369633a953a61b2de82c2726ce527dab8d8be0435719303563630e13`; H.264 640×360, 30fps, AAC stereo 44.1kHz; **138.507029s**.
- MP3: same basename `.mp3`; SHA-256 `c0c47b7816a90f9bd248884f9b479c4b18b429a7cd57c27b938c75fa9d5889dc`; stereo 44.1kHz; **138.553458s**.
- Owner shared reference URL: https://youtu.be/lWVpdlPzI9M

Do not commit reference media, screenshots or extracted full audio to the public repository by default. Analysis uses local uploads; future collaborators must obtain the originals separately.

## Direct observation from 3.0s and 0.75s sampled frames

| Approximate video span | Observed content | Confidence / next inspection |
|---|---|---|
| 0–5.2s | bright orange title; decorative tomato, yellow pepper and broccoli illustrations; Japanese title | HIGH for major screen states |
| 5.2–12.7s | main kitchen revealed; white cat near left sink; central apron-wearing, back-facing cook; right-hand refrigerator; brief green/monochrome/stylized transitions | HIGH for composition; exact transition boundaries UNVERIFIED |
| 12.7–~78s | continuous bright kitchen performance; incoming flying vegetables; hand/cook movement and changing pose/hair | HIGH for broad action; individual cue chart UNVERIFIED |
| ~63–66s | brief saturated color / magenta or dark section treatment | MEDIUM, revisit dense frames |
| ~78–87s | overexposure then monochrome silhouette interlude, followed by new scene | MEDIUM; exact timing requires dense inspection |
| ~87–100s | vivid blue marine/underwater scene with large whale and fish imagery behind same kitchen foreground | HIGH for distinct environmental state |
| ~100–119s | returns to kitchen; further ingredients; completion transition | HIGH for high-level structure |
| ~120–133s | mostly dark/black results sequence with Japanese text and rating indicator | HIGH for separate results state |
| ~134–138.5s | illustrated plated-dish result panel | HIGH for final visual motif |

This recording is 640×360 at 30fps; sampling ambiguity is ~33.3ms per frame. Do not infer millisecond hit points from screenshot positions. Frame captures are **reference for creating original high-resolution art**, not suitable pixel sources to upscale into final gameplay sprites.

## Audio findings (direct, reproducible analysis)
- MP3 waveform decoded mono at 11,025Hz for exploratory analysis; final audio validation must work on stereo 44.1/48kHz masters.
- Across 15–45, 45–75, 75–105 and 20–113s windows, onset/beat-track linear regression gives approximately **131.94, 132.00, 131.93, and 132.00 BPM** respectively. **132 BPM is a strong *candidate*, not an accepted production tempo.**
- Estimated beat-track residual is ~11–15ms for the sampled windows; that is algorithmic onset uncertainty and **not** the game's timing accuracy or the final judge window.
- The supplied MP4's audio and MP3, when independently decoded at 11,025Hz and compared in 10s windows beginning at 10,20,40,65,85,105 and 125s, show a *constant waveform lag* of **-276 samples ≈ -25.03ms** in the convention `correlate(MP4_audio, MP3)`; normalized cross-correlation ~0.988–0.991. The video-embedded audio appears ~25ms ahead of the standalone MP3 for matched content. This may stem from codec priming/stream alignment; verify again at native rate before locking down chart origin.
- Audio continues through introduction and results; MP3 is **not proven to be a separate clean BGM-only master**. Separate music, game cues, catch SFX, and UI/results audio during the next transcription pass.
- Past Godot Rhythm Kitchen chart tempo **102 BPM must not be reused** as the source benchmark.

## Next required transcription to complete M1
1. Confirm the timing master (video stream timestamps and decoded MP4 audio, not arbitrary 0s of MP3).
2. Align audio to video and produce waveform/spectrogram + beat grid at native rate.
3. Annotate all cue sounds, incoming ingredient classes, hand contact frames, failures/success responses and phrase changes. Save timestamp, event type, source frame/time, confidence. Do not invent an event where no evidence is available.
4. Determine downbeat, music-only regions, BPM changes (if any), visual anticipation durations, real press/release mechanics; peer-review at least one representative normal and triple-beat sequence.
5. Distinguish measured source offsets, chart offsets, output/input hardware latency and game-defined judgement windows.

## Risk register
- High: conflating 30fps visual timing with 1ms judgement precision.
- High: using 102 BPM archived prototype chart in a ~132 BPM reference.
- High: matching MP3 and MP4 nominal timecodes without accounting for measured ~25ms offset.
- Medium: treating 138s full recording as 138s continuous playable music; intro and results exist.
- Medium: assuming archived small sprite sheets/v3 art tiles meet production scale or source provenance.
- Medium: treating illustrative concept images as complete animation sprite atlases.
