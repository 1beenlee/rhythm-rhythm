#!/usr/bin/env python3
"""
Rhythm Rhythm v0.3 — Chart & Soundtrack Phrasing Rebuild
Rebuilds Beat Factory (4-beat Built-to-Scale + Hold), Rhythm Kitchen (3-beat cadence + Triple Catch),
and Echo Planet (8-beat phrasing: 4-call/2-rest/2-response, syncopated call/punch, triple-call/response).
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def build_echo_planet_chart():
    # 100 BPM, 38.4s (64 beats = 8 eight-beat cycles)
    calls = []
    events = []

    # Cycle 0 (Beats 0-7): Pattern A (4 Call, 2 Rest, 2 Response)
    calls.extend([{"beat": 0.0, "tone": 0}, {"beat": 1.0, "tone": 1}, {"beat": 2.0, "tone": 2}, {"beat": 3.0, "tone": 4}])
    events.extend([{"beat": 6.0, "lane": "tap"}, {"beat": 7.0, "lane": "tap"}])

    # Cycle 1 (Beats 8-15): Pattern B (Syncopated Call, 1 Heavy Downbeat Hit)
    calls.extend([{"beat": 8.0, "tone": 0}, {"beat": 9.5, "tone": 2}, {"beat": 11.0, "tone": 0}, {"beat": 12.5, "tone": 4}])
    events.extend([{"beat": 15.0, "lane": "tap"}])

    # Cycle 2 (Beats 16-23): Pattern C (Triple Staccato Call & Response)
    calls.extend([{"beat": 16.0, "tone": 1}, {"beat": 17.0, "tone": 2}, {"beat": 18.0, "tone": 4}])
    events.extend([{"beat": 20.0, "lane": "tap"}, {"beat": 21.0, "lane": "tap"}, {"beat": 22.0, "lane": "tap"}])

    # Cycle 3 (Beats 24-31): Pattern A Variation (Higher Octave)
    calls.extend([{"beat": 24.0, "tone": 2}, {"beat": 25.0, "tone": 3}, {"beat": 26.0, "tone": 4}, {"beat": 27.0, "tone": 6}])
    events.extend([{"beat": 30.0, "lane": "tap"}, {"beat": 31.0, "lane": "tap"}])

    # Cycle 4 (Beats 32-39): Pattern B Variation (Syncopated Punch)
    calls.extend([{"beat": 32.0, "tone": 1}, {"beat": 33.5, "tone": 3}, {"beat": 35.0, "tone": 1}, {"beat": 36.5, "tone": 5}])
    events.extend([{"beat": 39.0, "lane": "tap"}])

    # Cycle 5 (Beats 40-47): Pattern C High (Triple Echo)
    calls.extend([{"beat": 40.0, "tone": 2}, {"beat": 41.0, "tone": 4}, {"beat": 42.0, "tone": 5}])
    events.extend([{"beat": 44.0, "lane": "tap"}, {"beat": 45.0, "lane": "tap"}, {"beat": 46.0, "lane": "tap"}])

    # Cycle 6 (Beats 48-55): Grand Finale (Pattern A Climax)
    calls.extend([{"beat": 48.0, "tone": 3}, {"beat": 49.0, "tone": 4}, {"beat": 50.0, "tone": 5}, {"beat": 51.0, "tone": 6}])
    events.extend([{"beat": 54.0, "lane": "tap"}, {"beat": 55.0, "lane": "tap"}])

    chart = {
        "schema_version": 1,
        "bpm": 100,
        "duration": 38.4,
        "beats_per_measure": 4,
        "calls": calls,
        "events": events
    }
    path = ROOT / "games" / "echo_planet" / "chart.json"
    path.write_text(json.dumps(chart, indent=2), encoding="utf-8")
    print(f"Updated {path.relative_to(ROOT)} ({len(calls)} calls, {len(events)} events)")

def build_beat_factory_chart():
    # 104 BPM, 42.0s (~72 beats = 18 four-beat measures)
    # Built-to-Scale: Box enters on beat b+0, slides b+1, b+2, strikes on b+3!
    # Hold Charge: Enters on b+0, Press & Hold on b+1, Release on b+3!
    events = []

    # Phrases (4-beat bars starting at b):
    # Bars 1-3: Normal Boxes (Hit on 3.0, 7.0, 11.0)
    for b in [0, 4, 8]:
        events.append({"beat": float(b + 3), "lane": "tap", "action": "press"})

    # Bar 4 (b=12): HOLD CHARGE BOX 1 (Press 13.0, Release 15.0)
    events.append({"beat": 13.0, "lane": "tap", "action": "press", "hold_len": 2.0})
    events.append({"beat": 15.0, "lane": "tap", "action": "release", "hold_len": 2.0})

    # Bars 5-6 (b=16, 20): Normal Boxes (Hit on 19.0, 23.0)
    events.append({"beat": 19.0, "lane": "tap", "action": "press"})
    events.append({"beat": 23.0, "lane": "tap", "action": "press"})

    # Bar 7 (b=24): Fast Double Tap (Hits on 26.0, 27.0)
    events.append({"beat": 26.0, "lane": "tap", "action": "press"})
    events.append({"beat": 27.0, "lane": "tap", "action": "press"})

    # Bar 8 (b=28): HOLD CHARGE BOX 2 (Press 29.0, Release 31.0)
    events.append({"beat": 29.0, "lane": "tap", "action": "press", "hold_len": 2.0})
    events.append({"beat": 31.0, "lane": "tap", "action": "release", "hold_len": 2.0})

    # Bars 9-11 (b=32, 36, 40): Normal Boxes & Double
    events.append({"beat": 35.0, "lane": "tap", "action": "press"})
    events.append({"beat": 39.0, "lane": "tap", "action": "press"})
    events.append({"beat": 42.0, "lane": "tap", "action": "press"})
    events.append({"beat": 43.0, "lane": "tap", "action": "press"})

    # Bar 12 (b=44): HOLD CHARGE BOX 3 (Press 45.0, Release 47.0)
    events.append({"beat": 45.0, "lane": "tap", "action": "press", "hold_len": 2.0})
    events.append({"beat": 47.0, "lane": "tap", "action": "release", "hold_len": 2.0})

    # Bars 13-14 (b=48, 52): Normal Boxes (Hit on 51.0, 55.0)
    events.append({"beat": 51.0, "lane": "tap", "action": "press"})
    events.append({"beat": 55.0, "lane": "tap", "action": "press"})

    # Bar 15 (b=56): Fast Double (Hit on 58.0, 59.0)
    events.append({"beat": 58.0, "lane": "tap", "action": "press"})
    events.append({"beat": 59.0, "lane": "tap", "action": "press"})

    # Bar 16 (b=60): HOLD CHARGE BOX 4 (Press 61.0, Release 63.0)
    events.append({"beat": 61.0, "lane": "tap", "action": "press", "hold_len": 2.0})
    events.append({"beat": 63.0, "lane": "tap", "action": "release", "hold_len": 2.0})

    # Bar 17 (b=64): Grand Finale Box (Hit on 67.0)
    events.append({"beat": 67.0, "lane": "tap", "action": "press"})

    chart = {
        "schema_version": 1,
        "bpm": 104,
        "duration": 42,
        "beats_per_measure": 4,
        "calls": [],
        "events": events
    }
    path = ROOT / "games" / "beat_factory" / "chart.json"
    path.write_text(json.dumps(chart, indent=2), encoding="utf-8")
    print(f"Updated {path.relative_to(ROOT)} ({len(events)} events, includes Hold & Release)")

def build_rhythm_kitchen_chart():
    # 102 BPM, 42.0s (~72 beats = 18 four-beat measures)
    # Pattern 1 (Single): Toss b+0 -> Catch b+3
    # Pattern 2 (Triple Catch): Roll toss b+0 -> Triple Catch on b+2.5, b+2.75, b+3.0!
    events = []

    # Bar 1 (b=0): Single Left (Toss 0 -> Catch 3.0)
    events.append({"beat": 3.0, "lane": "left", "pattern": "single"})
    # Bar 2 (b=4): Single Right (Toss 4 -> Catch 7.0)
    events.append({"beat": 7.0, "lane": "right", "pattern": "single"})
    # Bar 3 (b=8): Single Left (Toss 8 -> Catch 11.0)
    events.append({"beat": 11.0, "lane": "left", "pattern": "single"})

    # Bar 4 (b=12): TRIPLE CATCH RIGHT (Roll toss 12 -> Catch 14.5, 14.75, 15.0)
    events.append({"beat": 14.5, "lane": "right", "pattern": "triple"})
    events.append({"beat": 14.75, "lane": "right", "pattern": "triple"})
    events.append({"beat": 15.0, "lane": "right", "pattern": "triple"})

    # Bar 5 (b=16): Single Right (Toss 16 -> Catch 19.0)
    events.append({"beat": 19.0, "lane": "right", "pattern": "single"})
    # Bar 6 (b=20): Single Left (Toss 20 -> Catch 23.0)
    events.append({"beat": 23.0, "lane": "left", "pattern": "single"})

    # Bar 7 (b=24): TRIPLE CATCH LEFT (Roll toss 24 -> Catch 26.5, 26.75, 27.0)
    events.append({"beat": 26.5, "lane": "left", "pattern": "triple"})
    events.append({"beat": 26.75, "lane": "left", "pattern": "triple"})
    events.append({"beat": 27.0, "lane": "left", "pattern": "triple"})

    # Bar 8 (b=28): Single Right (Hit 31.0)
    events.append({"beat": 31.0, "lane": "right", "pattern": "single"})
    # Bar 9 (b=32): Single Left (Hit 35.0)
    events.append({"beat": 35.0, "lane": "left", "pattern": "single"})

    # Bar 10 (b=36): TRIPLE CATCH RIGHT (Hit 38.5, 38.75, 39.0)
    events.append({"beat": 38.5, "lane": "right", "pattern": "triple"})
    events.append({"beat": 38.75, "lane": "right", "pattern": "triple"})
    events.append({"beat": 39.0, "lane": "right", "pattern": "triple"})

    # Bar 11 (b=40): Single Left (Hit 43.0)
    events.append({"beat": 43.0, "lane": "left", "pattern": "single"})

    # Bar 12 (b=44): TRIPLE CATCH LEFT (Hit 46.5, 46.75, 47.0)
    events.append({"beat": 46.5, "lane": "left", "pattern": "triple"})
    events.append({"beat": 46.75, "lane": "left", "pattern": "triple"})
    events.append({"beat": 47.0, "lane": "left", "pattern": "triple"})

    # Bar 13 (b=48): Single Right (Hit 51.0)
    events.append({"beat": 51.0, "lane": "right", "pattern": "single"})
    # Bar 14 (b=52): Single Left (Hit 55.0)
    events.append({"beat": 55.0, "lane": "left", "pattern": "single"})

    # Bar 15 (b=56): TRIPLE CATCH RIGHT (Hit 58.5, 58.75, 59.0)
    events.append({"beat": 58.5, "lane": "right", "pattern": "triple"})
    events.append({"beat": 58.75, "lane": "right", "pattern": "triple"})
    events.append({"beat": 59.0, "lane": "right", "pattern": "triple"})

    # Bar 16 (b=60): Single Left (Hit 63.0)
    events.append({"beat": 63.0, "lane": "left", "pattern": "single"})
    # Bar 17 (b=64): Grand Finale Single Right (Hit 67.0)
    events.append({"beat": 67.0, "lane": "right", "pattern": "single"})

    chart = {
        "schema_version": 1,
        "bpm": 102,
        "duration": 42,
        "beats_per_measure": 4,
        "calls": [],
        "events": events
    }
    path = ROOT / "games" / "rhythm_kitchen" / "chart.json"
    path.write_text(json.dumps(chart, indent=2), encoding="utf-8")
    print(f"Updated {path.relative_to(ROOT)} ({len(events)} events, includes Single & Triple catch)")

if __name__ == "__main__":
    build_echo_planet_chart()
    build_beat_factory_chart()
    build_rhythm_kitchen_chart()
    print("ALL 3 CHARTS REBUILT SUCCESSFULLY!")
