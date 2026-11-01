#!/usr/bin/env python3
"""Offline and dependency-free validator for all Rhythm Rhythm game packs."""
import argparse
import json
import re
import sys
from pathlib import Path

ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
ALLOWED = {"tap", "left", "right"}


def validate_repo(root: Path):
    root = root.resolve()
    issues = []
    games = root / "games"
    if not games.is_dir():
        return [], ["Missing games/ directory"]
    found = []
    for game_dir in sorted(path for path in games.iterdir() if path.is_dir()):
        path = game_dir / "game.json"
        if not path.is_file():
            # Resource-only directories are ignored, not advertised as game packs.
            continue
        pack = game_dir.name
        found.append(pack)
        try:
            manifest = json.loads(path.read_text(encoding="utf8"))
        except (ValueError, OSError) as exc:
            issues.append(f"{pack}: cannot read manifest: {exc}")
            continue
        if not isinstance(manifest, dict):
            issues.append(f"{pack}: manifest must be object")
            continue
        if manifest.get("schema_version") != 1:
            issues.append(f"{pack}: unsupported manifest schema_version")
        if not ID_PATTERN.fullmatch(pack) or manifest.get("id") != pack:
            issues.append(f"{pack}: id must equal canonical snake_case folder name")
        for field in ("name", "description", "scene", "chart", "controls", "color"):
            if not isinstance(manifest.get(field), str) or not manifest[field].strip():
                issues.append(f"{pack}: missing or invalid {field}")
        if manifest.get("controls") not in ("tap", "left/right"):
            issues.append(f"{pack}: controls must be tap or left/right")
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", str(manifest.get("color", ""))):
            issues.append(f"{pack}: color must be #RRGGBB")
        expected_prefix = f"res://games/{pack}/"
        for field, extension in (("scene", ".tscn"), ("chart", ".json")):
            resource = manifest.get(field)
            if not isinstance(resource, str) or not resource.startswith(expected_prefix) or not resource.endswith(extension):
                issues.append(f"{pack}: {field} must stay within its own folder")
                continue
            relative = resource[6:]
            target = (root / relative).resolve()
            if not target.is_relative_to(game_dir.resolve()) or not target.is_file():
                issues.append(f"{pack}: missing or escaped {field} resource {resource}")
        chart_path = root / "games" / pack / "chart.json"
        if not chart_path.exists():
            continue
        try:
            chart = json.loads(chart_path.read_text(encoding="utf8"))
        except (ValueError, OSError) as exc:
            issues.append(f"{pack}: cannot read chart: {exc}")
            continue
        if not isinstance(chart, dict):
            issues.append(f"{pack}: chart must be object")
            continue
        if chart.get("schema_version") != 1:
            issues.append(f"{pack}: unsupported chart schema_version")
        bpm = chart.get("bpm")
        duration = chart.get("duration")
        if type(bpm) not in (int, float) or not 60 <= bpm <= 220:
            issues.append(f"{pack}: bpm must be 60..220")
            bpm = 120
        if type(duration) not in (int, float) or not 30 <= duration <= 90:
            issues.append(f"{pack}: duration must be 30..90 seconds")
            duration = 60
        if chart.get("beats_per_measure") != 4:
            issues.append(f"{pack}: beats_per_measure must currently be 4")
        max_beat = duration * bpm / 60 - 0.5
        events = chart.get("events")
        if not isinstance(events, list) or not events:
            issues.append(f"{pack}: events must be a nonempty list")
            continue
        previous = -1
        last_per_lane = {}
        for index, event in enumerate(events):
            if not isinstance(event, dict):
                issues.append(f"{pack}: event #{index} must be object")
                continue
            beat, lane = event.get("beat"), event.get("lane")
            if type(beat) not in (int, float) or not 0 <= beat <= max_beat:
                issues.append(f"{pack}: event #{index} beat outside playable timeline")
                continue
            if beat < previous:
                issues.append(f"{pack}: event #{index} out of sorted order")
            previous = beat
            if lane not in ALLOWED:
                issues.append(f"{pack}: event #{index} has unknown lane")
                continue
            if manifest.get("controls") == "tap" and lane != "tap":
                issues.append(f"{pack}: event #{index} uses lane not mapped in controls")
            if manifest.get("controls") == "left/right" and lane == "tap":
                issues.append(f"{pack}: event #{index} uses lane not mapped in controls")
            # Allow rapid rhythmic patterns (16th notes / fast triplets down to 120ms) while guarding against duplicate frames
            if beat - last_per_lane.get(lane, -100) < 0.12 * bpm / 60:
                issues.append(f"{pack}: overlapping judgement events on lane {lane}")
            last_per_lane[lane] = beat
        calls = chart.get("calls", [])
        if not isinstance(calls, list):
            issues.append(f"{pack}: calls must be list")
            continue
        last_call = -1.0
        for index, event in enumerate(calls):
            if not isinstance(event, dict) or type(event.get("beat")) not in (float, int):
                issues.append(f"{pack}: invalid call #{index}")
                continue
            beat = event["beat"]
            if beat < last_call or beat < 0 or beat > max_beat:
                issues.append(f"{pack}: call #{index} not sorted or outside timeline")
            if type(event.get("tone")) is not int or not 0 <= event["tone"] <= 6:
                issues.append(f"{pack}: call #{index} has invalid tone")
            last_call = beat
    if not found:
        issues.append("No games registered")
    return found, issues


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    found, issues = validate_repo(args.root)
    print(f"Checked {len(found)} game pack(s): {', '.join(found)}")
    if issues:
        for issue in issues:
            print("ERROR:", issue)
        sys.exit(1)
    print("Manifest and beatmap validation: PASS")


if __name__ == "__main__":
    main()
