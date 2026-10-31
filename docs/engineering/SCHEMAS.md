# Game pack schemas (version 1)

## Manifest `games/<id>/game.json`

Required: `schema_version=1`, `id` matching directory snake_case, `name`, `description`, `scene` (inside game dir, `.tscn`), `chart` (same dir, `.json`), `controls` (`tap` or `left/right`), `color` `#RRGGBB`.

## Event chart `games/<id>/chart.json`

Required: `schema_version=1`, `bpm` 60..220, `duration` 30..90 seconds, `beats_per_measure=4`, non-empty `events` array sorted by beat with `{ "beat": float, "lane": "tap|left|right" }`. Optional sorted `calls` array contains `{ "beat": float, "tone": integer 0..6 }`; calls are audible cues embedded in the generated track, not player judgement events.

Events must be within duration minus the 0.5 beat trailing margin. Two events on a single lane cannot be closer than the 160ms Good threshold equivalent. All constraints are checked by `python tools/validate.py`.

**Registration:** dropping this manifest alongside valid `chart.json`, `visual.tscn` and `visual.gd` into `res://games/<id>/` is enough. `GameRegistry.discover()` scans directories at app startup. Export filters explicitly include `.json`. Scripts are first-party source and must not be downloaded at runtime.
