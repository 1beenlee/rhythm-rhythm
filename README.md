# Rhythm Rhythm · v0.2 Groove Show Rebuild

**Tiny games. Big grooves.** An original, standalone offline-first 2D cartoon rhythm game collection built with Godot **4.7.2-stable** and GDScript. No account, remote API, CDN, or copyrighted franchise assets. All cartoon stage worlds, character animations, and 44.1kHz stereo soundtracks/SFX are original first-party creations.

## What's New in v0.2 (Art, Animation & Audio Rebuild)

- **2D Cartoon Stage Presentation (`core/cartoon_draw.gd`, `core/stage_ui_art.gd`)**:
  - Thick dark-ink outlines (`3–5px`), squash-and-stretch character animation, multi-layer stage depth, and full-bleed stages occupying ~90% of the viewport.
  - Replaced the v0.1 admin-style button stacks and falling-note bottom bars with direct stage interaction (click/tap anywhere on the stage for 1-button games, or click/tap the left/right half of the stage for Rhythm Kitchen) and a compact corner pause button + modal overlay.
  - Added a **Rhythm Heaven Groove**-inspired Title Stage Banner, illustrated **Episode Poster Cards**, an interactive **Rehearsal Stage** with live sound testing, and illustrated **Result Vignettes** (`SUPERB! ★`, `OK! ♪`, `TRY AGAIN...`).
- **Three Expressive Cartoon Mini-Game Worlds**:
  - **Beat Factory (104 BPM)**: Stubborn factory worker **Poko** (`YOU`) operates a spring-loaded facial stamping rig while **Supervisor Bird** watches from the factory window, background gears turn, a pendant lamp swings on the beat, steam pipes puff musical cues, and expressive parcels receive golden crown/star seals on `Perfect` or squash with `X_X` dizzy eyes on `Miss`.
  - **Echo Planet (96 BPM)**: Alien choir lead **Luma-Lou** sings 4-beat cosmic call phrases under a desert mesa night sky while upper-sky constellation stars pop in syllable by syllable; spotlight sweeps to **Pip & Astro** (`YOU`) beside their retro Radar Van to echo the rhythm back with neon star bursts.
  - **Rhythm Kitchen (102 BPM)**: **Chef Mimo** (`YOU`) in a sunlit yellow-and-mint tiled kitchen (watched by **Nori** the white sous-chef cat by the palm-tree window) catches parabolic flying tomatoes, eggs, herbs, and mushrooms into the sizzling **Left Skillet** (`A` / `Left`) or **Right Mixing Bowl** (`L` / `Right`).
- **44.1kHz 16-bit Stereo Multi-Track Soundtracks & World SFX (`assets/audio/`, `tools/generate_audio_assets.py`)**:
  - Replaced the 11,025Hz mono sine-wave placeholders with 3 original 44.1kHz stereo tracks (`beat_factory_song.wav`, `echo_planet_song.wav`, `rhythm_kitchen_song.wav`) featuring drums, basslines, chord progressions, lead melodies, intro/verse/bridge/climax sections, and embedded stereo musical cues.
  - 12 custom world-specific 44.1kHz stereo SFX (`Perfect`, `Good`, `Miss` per world, stereo-panned skillet flip & bowl splash for Rhythm Kitchen, plus `fanfare_superb.wav` and `fanfare_ok.wav`) with full provenance in `assets/audio/PROVENANCE.json`.

## Play it locally

1. Download [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (standard, not .NET) and open `project.godot`.
2. Press **F5** to run. Choose an episode poster card, test your sound in the Rehearsal screen, and start the show:
   - **Beat Factory**: `Space` / `F` / `J` or click/tap the stage on the beat.
   - **Echo Planet**: Listen for 4 beats, then `Space` / `F` / `J` or click/tap the stage for 4 beats.
   - **Rhythm Kitchen**: `A` / `Left Arrow` (or click/tap Left half of stage) for Skillet; `L` / `Right Arrow` (or click/tap Right half of stage) for Mixing Bowl.
3. `P` / `Esc` (or top-right `II PAUSE`) opens the Pause Modal. `F3` toggles the audio clock & score debug overlay.
4. Run `python tools/validate.py` and `python -m unittest discover -s tests -v` to validate packs. Run `python tools/generate_audio_assets.py` to regenerate the 44.1kHz stereo WAV assets deterministically.

## IP / Licensing

All code, 2D cartoon vector illustrations, procedural multi-track music compositions, sound effects, and icons are 100% original to this repository (`CC0-1.0` / project-authored; see `assets/audio/PROVENANCE.json` and `production/qa/ART_AUDIO_REVIEW.md`).
