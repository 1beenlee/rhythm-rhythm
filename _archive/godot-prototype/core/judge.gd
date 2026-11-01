extends RefCounted
class_name RhythmJudge

const PERFECT_WINDOW := 0.075
const GOOD_WINDOW := 0.160
const MISS_WINDOW := 0.210

static func grade(delta_seconds: float) -> String:
    var error := absf(delta_seconds)
    if error <= PERFECT_WINDOW:
        return "Perfect"
    if error <= GOOD_WINDOW:
        return "Good"
    if error <= MISS_WINDOW:
        return "Miss"
    return "Outside"

static func points(grade_name: String) -> int:
    match grade_name:
        "Perfect": return 1000
        "Good": return 500
    return 0

static func seconds_for_beat(beat: float, bpm: float) -> float:
    return beat * 60.0 / bpm

static func corrected_time(audio_position: float, since_mix: float, output_latency: float, input_ms: int, extra_output_ms: int) -> float:
    # The engine clock is related to actual audible sound rather than frame deltas.
    return maxf(0.0, audio_position + since_mix - output_latency + float(input_ms - extra_output_ms) / 1000.0)
