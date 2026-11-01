# Rhythm々 — Claude Code Studio Charter

## Mandatory read order
1. `intent.md` — project goals and fidelity standards.
2. `what_to_avoid.md` — hard rejection criteria.
3. `design/game-brief.md`
4. Current milestone and related specifications.

If other archived briefs or an upstream framework example conflict with (1) or (2), the root documents win. The user's latest explicit instructions supersede older archived project scope.

## Studio
Adapts CCGS `Donchitos/Claude-Code-Game-Studios` (framework config `1.2.0`) **only at project scope**. Four proposed custom role charters are in `.claude/agents/`: `game-director`, `tech-lead`, `audio-director`, `2d-artist`. Roles describe review ownership; their runtime invocation has not been verified.

The owner retains approval at each major gate. Do not run unknown upstream hooks or install the full template without a separate review.

## Phase policy
- Current phase: M1. Source observation, music/visual reference study, Art Bible, sprite specifications and provenance planning.
- M2 later: AudioContext transport, beat-map, calibration, measured input/audio clocks.
- M3 later: interactive Kitchen vertical slice, then entire track after actual listening and playing.
- No unrelated games, Godot rebuild or Unity implementation now.
- Web stack is TypeScript/Vite/PixiJS/Web Audio; upstream CCGS /setup-engine has no native web adapter and must not be reported as executed.

## Acceptance
- Keep exact audio/video offsets as **measured estimates**, not invented beat events.
- 30fps recording supports ~33.33ms frame sampling, **not** 1ms visual event timestamps.
- Screenshot + audible playtest are mandatory for visible/audio changes even when unit tests pass.
- Distinct actual character poses and quality-assured sprites, not particle-only or rectangle-body stand-ins.
- Keep captured reference media out of public commits unless explicitly instructed to publish them.
- Preserve `_archive/`, `intent.md`, `what_to_avoid.md`. Task branch, reviewable checkpoint commits.
