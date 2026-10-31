extends RefCounted
class_name RhythmSave

const PATH := "user://rhythm.cfg"
const DEFAULT_INPUT_MS := 0

static func settings() -> Dictionary:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    return {
        "input_ms": clampi(int(cfg.get_value("audio", "input_ms", DEFAULT_INPUT_MS)), -250, 250),
        "output_ms": clampi(int(cfg.get_value("audio", "output_ms", 0)), -250, 250),
        "volume": clampf(float(cfg.get_value("audio", "volume", 0.8)), 0.0, 1.0),
        "reduced_motion": bool(cfg.get_value("accessibility", "reduced_motion", false))
    }

static func write_settings(value: Dictionary) -> Error:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    for key in ["input_ms", "output_ms", "volume"]:
        cfg.set_value("audio", key, value[key])
    cfg.set_value("accessibility", "reduced_motion", value["reduced_motion"])
    return cfg.save(PATH)

static func record(game_id: String, score: int) -> int:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    var best := maxi(int(cfg.get_value("records", game_id, 0)), score)
    cfg.set_value("records", game_id, best)
    cfg.save(PATH)
    return best

static func best(game_id: String) -> int:
    var cfg := ConfigFile.new()
    cfg.load(PATH)
    return int(cfg.get_value("records", game_id, 0))
