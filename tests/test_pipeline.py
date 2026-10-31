import json
import tempfile
import unittest
from pathlib import Path
from tools.scaffold_game import scaffold
from tools.validate import validate_repo

ROOT = Path(__file__).resolve().parents[1]


class GamePipelineTests(unittest.TestCase):
    def test_three_production_games_validate(self):
        registered, issues = validate_repo(ROOT)
        self.assertEqual(issues, [], issues)
        self.assertEqual(registered, ["beat_factory", "echo_planet", "rhythm_kitchen"])

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
