# ADD_GAME — make a new mini-game in minutes

1. Run `python tools/scaffold_game.py spinning_top "Spinning Top"` (Python 3; no dependencies).
2. Edit `games/spinning_top/game.json`: name, description, controls, color. IDs are immutable snake_case keys for local scores.
3. Edit `games/spinning_top/chart.json`: BPM, 30–90s duration, sorted `events` (beats/lane), optional audible `calls`.
4. Edit `games/spinning_top/visual.gd` to implement **one original mechanic**; no core edits. `visual.tscn` is pre-wired.
5. Run `python tools/validate.py` and `python -m unittest discover -s tests -v`.
6. Open `project.godot` in Godot 4.7.2 and press F6/F5 to preview; play via keyboard/touch, F3 for audio debug; assess joy and synchronization by ear.
7. Check select menu automatically includes the new game. Verify play-to-results, pause, retry, mobile screen and offline export.
8. Commit the new pack and tests on a feature branch; PR only after QA evidence.

## 4th game dry-run example

The Python test `test_fourth_game_registers_without_touching_core` scaffolds `fourth_test` in a temporary root and proves validator discovery. This confirms file conventions, **not Godot runtime registration or real gameplay**. To test in Godot, create the pack with the command above, run it, then either retain it for release or move it outside `games/` before publishing. No shared core changes are needed.
