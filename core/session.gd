extends Node
class_name RhythmSession

signal feedback(grade_name: String, lane: String, combo: int)
signal finished(summary: Dictionary)
signal countdown(number: int)

var manifest: Dictionary
var chart: Dictionary
var settings: Dictionary
var score := 0
var combo := 0
var max_combo := 0
var counts := {"Perfect": 0, "Good": 0, "Miss": 0}
var active := false
var paused := false
var song_time := 0.0
var countdown_start_usec := 0
var countdown_pause_usec := 0
var last_count := 4
var states: Array[bool] = []
var audio := AudioStreamPlayer.new()
var sfx := AudioStreamPlayer.new()
var tone_cache := {}
var ending := false

func _ready() -> void:
    add_child(audio)
    add_child(sfx)
    for key in ["Perfect", "Good", "Miss"]:
        tone_cache[key] = RhythmSynth.make_hit(key)

func configure(game: Dictionary, profile: Dictionary) -> void:
    manifest = game
    chart = game["_chart"]
    settings = profile
    states.clear()
    for _event in chart.get("events", []):
        states.append(false)
    audio.stream = RhythmSynth.make_song(str(game["id"]), float(chart["bpm"]), float(chart["duration"]), chart.get("calls", []))
    audio.volume_linear = float(settings["volume"])
    sfx.volume_linear = float(settings["volume"])
    restart()

func restart() -> void:
    audio.stop()
    score = 0
    combo = 0
    max_combo = 0
    counts = {"Perfect": 0, "Good": 0, "Miss": 0}
    for i in states.size():
        states[i] = false
    ending = false
    paused = false
    active = false
    song_time = 0.0
    last_count = 4
    countdown_start_usec = Time.get_ticks_usec()
    countdown_pause_usec = 0
    set_process(true)

func _process(_delta: float) -> void:
    if paused or ending:
        return
    if not active:
        var elapsed := float(Time.get_ticks_usec() - countdown_start_usec) / 1000000.0
        var remaining := maxi(0, 3 - int(elapsed))
        if remaining != last_count:
            last_count = remaining
            countdown.emit(remaining)
        if elapsed >= 3.0:
            active = true
            audio.play()
            countdown.emit(-1)  # UI leaves READY/GO when the actual track starts.
        return
    if not audio.playing:
        # Do not silently advance on background-tab audio suspension.
        pause_session()
        return
    song_time = _read_song_time()
    var events: Array = chart["events"]
    for i in events.size():
        if not states[i] and song_time - _event_time(events[i]) > RhythmJudge.MISS_WINDOW:
            _apply(i, "Miss")
    if song_time >= float(chart["duration"]) - 0.12:
        _finish()

func submit(lane: String) -> void:
    if not active or paused or ending:
        return
    # Always sample the audio clock on input arrival, never the render-frame delta.
    song_time = _read_song_time()
    _submit_at_time(lane, song_time)

func _submit_at_time(lane: String, at_seconds: float) -> void:
    # Separate deterministic input matching from hardware clock sampling for regression tests.
    var best_index := -1
    var best_delta := INF
    var wrong_index := -1
    var wrong_delta := INF
    var events: Array = chart["events"]
    for i in events.size():
        if states[i]:
            continue
        var delta := absf(at_seconds - _event_time(events[i]))
        if delta > RhythmJudge.MISS_WINDOW:
            continue
        if str(events[i]["lane"]) == lane:
            if delta < best_delta:
                best_delta = delta
                best_index = i
        elif delta < wrong_delta:
            wrong_delta = delta
            wrong_index = i
    if best_index >= 0 and (wrong_index < 0 or best_delta <= wrong_delta):
        _apply(best_index, RhythmJudge.grade(best_delta))
    elif wrong_index >= 0:
        # A wrong-lane press on a visible note consumes that note as a Miss.
        _apply(wrong_index, "Miss")
    else:
        # Ghost taps break combo but cannot inflate event-based Miss totals.
        combo = 0
        _sound("Miss")
        feedback.emit("Outside", lane, combo)

func _apply(index: int, grade_name: String) -> void:
    states[index] = true
    counts[grade_name] += 1
    if grade_name == "Miss":
        combo = 0
    else:
        combo += 1
        max_combo = maxi(max_combo, combo)
        score += RhythmJudge.points(grade_name) + mini(combo, 50) * 10
    _sound(grade_name)
    feedback.emit(grade_name, str(chart["events"][index]["lane"]), combo)

func _sound(grade_name: String) -> void:
    sfx.stream = tone_cache.get(grade_name, tone_cache["Miss"])
    sfx.play()

func _read_song_time() -> float:
    return RhythmJudge.corrected_time(audio.get_playback_position(), AudioServer.get_time_since_last_mix(), AudioServer.get_output_latency(), int(settings["input_ms"]), int(settings["output_ms"]))

func _event_time(event: Dictionary) -> float:
    return RhythmJudge.seconds_for_beat(float(event["beat"]), float(chart["bpm"]))

func pause_session() -> void:
    if ending or paused:
        return
    paused = true
    if active:
        audio.stream_paused = true
    else:
        countdown_pause_usec = Time.get_ticks_usec()

func resume_session() -> void:
    if not paused:
        return
    paused = false
    if active:
        audio.stream_paused = false
    else:
        # Keep the remaining countdown, excluding time spent paused.
        countdown_start_usec += Time.get_ticks_usec() - countdown_pause_usec
        countdown_pause_usec = 0

func _finish() -> void:
    ending = true
    active = false
    audio.stop()
    var highest := RhythmSave.record(str(manifest["id"]), score)
    finished.emit({"score": score, "best": highest, "max_combo": max_combo, "counts": counts.duplicate(), "total": states.size()})

func stop_session() -> void:
    audio.stop()
    active = false
    ending = true
    set_process(false)
