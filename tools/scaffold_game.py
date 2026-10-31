#!/usr/bin/env python3
"""Make a playable fourth game without touching the rhythm engine or registry."""
import argparse
import json
import re
from pathlib import Path


def scaffold(root: Path, identifier: str, name: str):
    if not re.fullmatch(r"[a-z][a-z0-9_]*", identifier):
        raise ValueError("game ID must be snake_case (lowercase, digits, underscore)")
    target = root / "games" / identifier
    if target.exists():
        raise FileExistsError(f"Refusing to overwrite existing pack: {target}")
    target.mkdir(parents=True)
    manifest = {
        "schema_version": 1, "id": identifier, "name": name,
        "description": "An original, one-button rhythm experiment.",
        "scene": f"res://games/{identifier}/visual.tscn",
        "chart": f"res://games/{identifier}/chart.json",
        "controls": "tap", "color": "#7568e9"
    }
    chart = {
        "schema_version": 1, "bpm": 110, "duration": 34,
        "beats_per_measure": 4, "calls": [],
        "events": [{"beat": float(beat), "lane": "tap"} for beat in range(4, 53)]
    }
    visual = '''extends RhythmVisual

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("e9f3ff"))
    paint_event_bar("tap", size.y * 0.5, size.x * 0.5, 100.0)
    draw_circle(size * 0.5, 40.0, RhythmTokens.LAVENDER)
    paint_feedback()
'''
    scene = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://games/ID/visual.gd" id="1_visual"]

[node name="GameVisual" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_visual")
'''.replace("ID", identifier)
    for filename, value in [("game.json", json.dumps(manifest, indent=2) + "\n"),
                            ("chart.json", json.dumps(chart, indent=2) + "\n"),
                            ("visual.gd", visual), ("visual.tscn", scene)]:
        (target / filename).write_text(value, encoding="utf8")
    return target


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("id")
    parser.add_argument("name")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    print("Created:", scaffold(args.root, args.id, args.name))


if __name__ == "__main__":
    main()
