extends SceneTree

func _initialize() -> void:
    assert(RhythmJudge.grade(0.0) == "Perfect")
    assert(RhythmJudge.grade(0.075) == "Perfect")
    assert(RhythmJudge.grade(0.15) == "Good")
    assert(RhythmJudge.grade(0.19) == "Miss")
    assert(RhythmJudge.grade(0.25) == "Outside")
    assert(is_equal_approx(RhythmJudge.seconds_for_beat(4, 120), 2.0))
    assert(is_equal_approx(RhythmJudge.corrected_time(1.0, 0.02, 0.05, 10, 0), 0.98))
    print("RhythmJudge: PASS")
    quit(0)
