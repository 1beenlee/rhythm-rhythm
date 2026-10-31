# Technical architecture

```text
scenes/app.gd                     Home / select / guide / play / results / settings / offline
  core/game_registry.gd           Discover res://games/*/game.json automatically
  core/save_data.gd               user://rhythm.cfg, settings + records
  core/session.gd                 Countdown, AudioStreamPlayer, play/pause, judgement, signals
    core/judge.gd                 Pure audio-time and scoring functions
    core/synth.gd                 Procedural PCM track and hit SFX
  core/game_visual.gd             Shared playfield hooks / feedback / upcoming note painter
    games/*/visual.gd             Three different scene-specific rendering mechanics
  tools/validate.py               Offline chart + pack validation
  tools/scaffold_game.py          Pack scaffold (no core edits)
```

`session.gd` is the sole gameplay truth. The visual's `_process(delta)` can animate shapes but never drives judgement. Each event is assessed by audio playback position + mix time − audio hardware latency + explicit input/output offset. Chart `beat` values map to seconds via `(60 / bpm) * beat`. Hit windows are **±75ms Perfect**, **±160ms Good**, and **±210ms Miss**; overdue notes transition to Miss when audio time exceeds their threshold. Single button or directional lane maps to the same `submit(lane)` method. Track generation, calls and SFX are all local. Audio starts after a 3-second countdown.

### Lifecycle
`configure → restart → countdown → active → paused/resumed → finished → results → retry/exit`. Focus loss suspends audio and time. `F3` shows a live diagnostic overlay; P or Esc pauses. Music is one actual `AudioStreamPlayer`, not frame-advanced metronome state.

### Audio caveat
Output latency availability varies by backend, browsers and devices; user output offset is additive. A player must empirically calibrate in settings. Rhythm accuracy and browser focus behavior require listening/playtest, not an assertion from pure math. Procedural PCM generation is CPU-bound at start and may need an optimization pass on older phones.

### Security and autonomy
Manifest is declarative. Runtime does not eval user code, load remote assets, call APIs or require CDN. Scenes are trusted project code only. Python scaffold writes only one new game directory and refuses overwrites. No scripts or permissions from upstream CCGS are installed.
