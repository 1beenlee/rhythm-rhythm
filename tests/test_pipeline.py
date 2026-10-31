import array
import json
import math
import tempfile
import unittest
import wave
from pathlib import Path
from tools.scaffold_game import scaffold
from tools.validate import validate_repo

ROOT = Path(__file__).resolve().parents[1]


class GamePipelineTests(unittest.TestCase):
    def test_three_production_games_validate(self):
        registered, issues = validate_repo(ROOT)
        self.assertEqual(issues, [], issues)
        self.assertEqual(registered, ["beat_factory", "echo_planet", "rhythm_kitchen"])

    def test_echo_planet_audio_chart_sync(self):
        chart = json.loads((ROOT / "games" / "echo_planet" / "chart.json").read_text(encoding="utf-8"))
        wav_path = ROOT / "assets" / "audio" / "echo_planet_song.wav"
        self.assertTrue(wav_path.exists())
        with wave.open(str(wav_path), "rb") as wf:
            sr = wf.getframerate()
            self.assertEqual(sr, 44100)
            self.assertEqual(wf.getnchannels(), 2)
            samples = array.array("h")
            samples.frombytes(wf.readframes(wf.getnframes()))
        spb = 60.0 / float(chart["bpm"])

        def window_rms(sec_start: float, sec_dur: float) -> float:
            i0 = max(0, int(sec_start * sr) * 2)
            i1 = min(len(samples), int((sec_start + sec_dur) * sr) * 2)
            if i1 <= i0:
                return 0.0
            acc = sum(int(samples[i]) * int(samples[i]) for i in range(i0, i1, 2))
            return math.sqrt(acc / max(1, (i1 - i0) // 2))

        for item in chart["calls"] + chart["events"]:
            t_beat = float(item["beat"]) * spb
            onset_rms = window_rms(t_beat, 0.055)
            pre_rms = window_rms(max(0.0, t_beat - 0.070), 0.045)
            self.assertGreater(onset_rms, 3500.0, f"Weak audio cue at beat {item['beat']}")
            if t_beat >= 0.1:
                self.assertGreater(onset_rms, pre_rms * 1.25, f"Missing sharp onset transient at beat {item['beat']}")

    def test_fourth_game_registers_without_touching_core(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            extra = scaffold(root, "fourth_test", "Fourth Test")
            registered, issues = validate_repo(root)
            self.assertEqual(registered, ["fourth_test"])
            self.assertEqual(issues, [], issues)
            self.assertTrue((extra / "visual.tscn").exists())
            with self.assertRaises(FileExistsError):
                scaffold(root, "fourth_test", "Overwrite")

    def test_invalid_chart_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            pack = scaffold(root, "bad_chart", "Bad Chart")
            data = json.loads((pack / "chart.json").read_text())
            data["events"][0]["lane"] = "invalid"
            data["events"][1]["beat"] = -1
            (pack / "chart.json").write_text(json.dumps(data))
            _, issues = validate_repo(root)
            self.assertTrue(any("unknown lane" in issue for issue in issues))
            self.assertTrue(any("outside playable timeline" in issue for issue in issues))

    def test_invalid_manifest_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            pack = scaffold(root, "bad_pack", "Bad Pack")
            data = json.loads((pack / "game.json").read_text())
            data["scene"] = "res://core/session.gd"
            (pack / "game.json").write_text(json.dumps(data))
            _, issues = validate_repo(root)
            self.assertTrue(any("scene must stay" in issue for issue in issues))

    def test_scaffold_disallows_path_traversal(self):
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaises(ValueError):
                scaffold(Path(temp), "../../escape", "Escape")


if __name__ == "__main__":
    unittest.main()
