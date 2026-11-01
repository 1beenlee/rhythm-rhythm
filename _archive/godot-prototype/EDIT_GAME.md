# EDIT_GAME — iterate safely

1. Adjust the target `chart.json` for beat positions and lane pattern (beat 4 = 2s at 120 BPM).
2. Optionally modify `visual.gd` as the game's own mechanic, cue presentation and animation.
3. Do **not** change `core/session.gd` to add a mini-game. Common engine defects require their own test and PR.
4. Run validator + regression, import Godot, play 3 full loops and check high-score persistence.
5. Test on one slow phone and desktop keyboard; tune offset in settings rather than changing chart values to mask device latency.
6. Record playtest result and screenshots in `production/qa/evidence/` (not inferred from successful build).
7. Confirm offline packaged `.json` and image files; follow `docs/engineering/EXPORT_QA.md`.
