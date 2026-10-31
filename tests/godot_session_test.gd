extends SceneTree

# Regression: wrong-lane / ghost inputs and countdown pause must not be exploitable.
var failures := 0
var last_countdown := 99

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("RhythmSession FAIL: " + label)

func _countdown_changed(n: int) -> void:
    last_countdown = n

func _reset_event(s: RhythmSession) -> void:
    s.chart = {"bpm": 120.0, "events": [{"beat": 4.0, "lane": "left"}]}
    s.states.clear()
    s.states.append(false)
    s.counts = {"Perfect": 0, "Good": 0, "Miss": 0}
    s.combo = 7
    s.score = 0

func _initialize() -> void:
    var s := RhythmSession.new()
    root.add_child(s)
    _reset_event(s)
    s._submit_at_time("right", 2.0)
    _check(s.states[0] and s.counts["Miss"] == 1 and s.combo == 0, "wrong lane consumes closest note and breaks combo")

    _reset_event(s)
    s._submit_at_time("right", 0.0)
    _check(not s.states[0] and s.counts["Miss"] == 0 and s.combo == 0, "ghost tap breaks combo without phantom Miss")

    _reset_event(s)
    s._submit_at_time("left", 2.0)
    _check(s.states[0] and s.counts["Perfect"] == 1 and s.combo == 8, "correct lane still scores")

    s.restart()
    s.countdown_start_usec = Time.get_ticks_usec() - 1500000
    s.pause_session()
    var before := float(s.countdown_pause_usec - s.countdown_start_usec) / 1000000.0
    s.countdown_pause_usec -= 800000  # simulate 0.8 s of paused wall-clock time
    s.resume_session()
    var after := float(Time.get_ticks_usec() - s.countdown_start_usec) / 1000000.0
    _check(absf(before - after) < 0.05, "resume preserves remaining countdown")

    s.countdown.connect(_countdown_changed)
    s.audio.stream = RhythmSynth.make_hit("Good")
    s.countdown_start_usec = Time.get_ticks_usec() - 3100000
    s._process(0.016)
    _check(s.active and last_countdown == -1, "song start clears READY/GO countdown")
    s.stop_session()
    s.free()
    if failures > 0:
        quit(1)
    else:
        print("RhythmSessionRegression: PASS")
        quit(0)
