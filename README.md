# Rhythm Rhythm · v0.1 candidate

**Tiny games. Big grooves.** An original, standalone offline-first rhythm game collection built with Godot **4.7.2-stable** and GDScript. No account, remote API, CDN or purchased artwork. All music and SFX are synthesized locally.

## Play it locally

1. Download [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (standard, not .NET) and open `project.godot`.
2. Press **F5** to run. Start Beat Factory (Space or tap), Echo Planet (listen, then Space/tap) or Rhythm Kitchen (A/L or left/right touch).
3. P/Esc toggles pause. F3 shows audio clock debugging. Settings control input/output offset, volume and reduced motion. Results are saved under Godot's `user://rhythm.cfg`.
4. Run `python tools/validate.py` and `python -m unittest discover -s tests -v` to test packs. Godot headless: `godot --headless --path . --import && godot --headless --path . --script tests/godot_judge_test.gd`.

## MVP game pack

| Game | Mechanic | Notes |
|---|---|---|
| Beat Factory | One-button stamp | Straight eighth-beat progression into offset syncopation |
| Echo Planet | Auditory call and response | Six 4+4-beat sequences, new cue patterns |
| Rhythm Kitchen | Two lanes | Alternating left/right and anticipatory falling ingredients |

> **Verification boundary:** Python schema/scaffold tests pass in the authoring environment. Actual Godot runtime, UI, audio playtest, Web/PWA and Windows offline testing must be confirmed with device-level evidence before calling this shipped MVP VERIFIED.

## Add or edit games

`python tools/scaffold_game.py my_game "My Game"` creates chart, manifest, scene and a procedural visual. Edit only the new game directory, run `python tools/validate.py`, and restart Godot. The game selection menu discovers the manifest automatically. See [ADD_GAME](ADD_GAME.md), [EDIT_GAME](EDIT_GAME.md), [schemas](docs/engineering/SCHEMAS.md) and [design system](docs/design-system/README.md).

## Architecture and build

Read [architecture](docs/engineering/ARCHITECTURE.md), [export/offline QA](docs/engineering/EXPORT_QA.md), [manual gate](production/qa/CHECKLIST.md), and [CCGS scope](docs/CCGS_ADOPTION.md). `export_presets.cfg` enables single-thread Web PWA (Godot-managed service worker) and standalone Windows export. Source first; **no public deployment without separate approval**.

## IP / licensing

All code, art primitives, procedural music and in-repo icons are original to this project. CCGS (MIT, © 2026 Donchitos) is an attributed *workflow reference*: no upstream executable code is bundled or installed globally. Do not use assets from existing rhythm game franchises. Godot's own license and redistributable engine/export template obligations apply to exported games.
