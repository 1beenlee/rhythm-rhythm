# Rhythm Rhythm v0.1 — Local execution handoff (provisional READY packet)

**Target:** `1beenlee/rhythm-rhythm`, current remote `main` contains a minimal README Bootstrap. Remote task branch already created: `feat/rhythm-v0-1-platform`.

**Important:** This is a *human-readable WDO-ready brief*, **not a schema-validated WDO task.yaml**. The Local Agent must validate or materialize against its installed WDO 1.1.x runtime contracts before enqueueing. No WDO execution is claimed.

## Goal and authorized scope

Import the supplied complete source archive into `feat/rhythm-v0-1-platform`, verify its files/hashes, run Godot import/tests/exports and actual three-game playtest, then commit/push to the existing feature branch and create/update a draft PR into main. No main direct push, tag/release, public deployment, force-push, global skill/hook install or destructive cleanup. Record screenshots/manual evidence. Stop for approval before public GitHub Pages publishing.

## Safety preflight

1. Choose a fresh task worktree under `%USERPROFILE%\\Documents\\Projects\\_worktrees\\rhythm-rhythm\\v0-1` (or configured root). `git fetch origin`; verify repo identity and current base before adopting local changes.
2. Confirm `main` is the initial Bootstrap and feature branch is at the same base or reconcile if it moved; **do not hard-reset** existing dirty worktrees.
3. Inspect the source archive before extraction. No prior target files should be overwritten: this was a new repository; preserve any newer collaborator changes.
4. CCGS wrappers in `.claude/skills/` are project-authored adapters. No hooks or permissions and no global environment mutations are authorized. Registry allowlist and WDO/Persona remain untouched.

## Practical commands (Windows PowerShell, adapt the Godot path)

```powershell
# In clean feature worktree
Expand-Archive -LiteralPath '<downloaded-rhythm_source.zip>' -DestinationPath .
python tools/validate.py
python -m unittest discover -s tests -v
& '<Godot-4.7.2-exe>' --headless --path . --import
& '<Godot-4.7.2-exe>' --headless --path . --script tests/godot_judge_test.gd
& '<Godot-4.7.2-exe>' --path .
# Inspect and execute production/qa/CHECKLIST.md; save evidence.
New-Item -ItemType Directory -Force build/web, build/windows | Out-Null
& '<Godot-4.7.2-exe>' --headless --path . --export-release 'Web' build/web/index.html
& '<Godot-4.7.2-exe>' --headless --path . --export-release 'Windows Desktop' build/windows/RhythmRhythm.exe
# Inspect git status / diff, test outcome, only then commit + push to task branch; open Draft PR.
```

## Blocking acceptance checks
- Zero GDScript parse/import errors; actual first-to-results runs for each game (keyboard and touch), distinct mechanics and audible prompts, success/failure, pause/restart, local records.
- Audio clock and input timestamp real-device validation, actual Windows EXE offline and PWA offline cold relaunch.
- Screenshots in `production/qa/evidence/` and a concise reproducible report.
- If CI minutes are restricted or binaries cannot be downloaded, report **BLOCKED**, never fake verified builds or screenshots.

## Current evidence
- Python `tools/validate.py` PASS for 3 packs.
- `python -m unittest discover -s tests -v`: 5 tests PASS, including fourth-game scaffold and invalid chart/manifest detection.
- Godot runtime, browser, PWA, Windows tests: **NOT_VERIFIED**.
