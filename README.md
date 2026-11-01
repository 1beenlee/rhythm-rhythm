# Rhythm々 — Kitchen Benchmark (Web First)

**Current phase: M1 / Benchmark study & 2D asset pre-production.** There is no runnable web game on this branch yet. Do not treat document completion as a playable build.

- **North star:** [intent.md](intent.md)
- **Hard rejection criteria:** [what_to_avoid.md](what_to_avoid.md)
- **Sole benchmark:** 「下ごしらえ」 in リズム天国 ミラクルスターズ, based on the supplied no-miss gameplay recording.
- **Target stack (approved, not yet installed):** TypeScript, Vite, PixiJS/WebGL, native Web Audio API.
- **Later only:** Unity port after a player-approved, audio/visual-verified web version.
- **Preserved history:** `_archive/godot-prototype/` is reference-only, not the new game's foundation.

## Current work products

- [M1 recording analysis](docs/research/kitchen-benchmark-m1.md) — observation vs. hypotheses, media hashes, segment timings.
- [Lean game brief](design/game-brief.md) — single-benchmark constraints.
- [Art Bible](design/art/art-bible.md) — cohesive scene, sprite, animation rules.
- [Asset inventory](design/assets/entity-inventory.md) and [production manifest](design/assets/asset-manifest.md).
- [Audio clock architecture decision](docs/architecture/ADR-001-web-audio-clock.md).
- [M1 QA gate](production/qa/kitchen-m1-gate.md).

## CCGS adaptation

The project uses a **scoped adaptation** of [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios), framework config version `1.2.0`, with four project-scoped role charters in `.claude/agents/`. This is **not** a claim that all 49 upstream agents, 74 skills, hooks, slash commands, or engine adapters have been installed or executed. CCGS `/setup-engine` targets Godot/Unity/Unreal, so Web-first requires a custom adapter and manual ADR instead of mislabeling a Godot setup as web.

The upstream template and previous Godot experiment are read-only references. No unreviewed CCGS hook, permission change or executable code is installed. Subsequent work should follow the applicable workflow gates (scope → art specification → architecture → prototype → visual/audio/interactive evidence).

## Reference media

Owner supplied a 138.5-second MP4 and matching MP3 in the project discussion. They are **not in this public repository**; the analysis records stable SHA-256 identifiers instead of uploading multi-megabyte originals. Local QA should obtain owner-provided source files before attempting frame-level chart verification.

## Change controls

Create changes on `feat/kitchen-benchmark` or task branches; do not implement on `main`. No other minigames, placeholder geometric characters, 3-second BGM loops, background-baked UI, or unverified `1ms` hardware claims. Implementation of M2/M3 follows the M1 approval gate.
