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
    # Sample the audio clock at input arrival; do not reuse last render-frame time.
    song_time = _read_song_time()
    var best_index := -1
    var best_delta := INF
    var events: Array = chart["events"]
    for i in events.size():
        if states[i] or str(events[i]["lane"]) != lane:
            continue
        var delta := absf(song_time - _event_time(events[i]))
        if delta <= RhythmJudge.MISS_WINDOW and delta < best_delta:
            best_delta = delta
            best_index = i
    if best_index < 0:
        _sound("Miss")
        feedback.emit("Outside", lane, combo)
        return
    _apply(best_index, RhythmJudge.grade(best_delta))

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

func resume_session() -> void:
    if not paused:
        return
    paused = false
    if active:
        audio.stream_paused = false
    else:
        countdown_start_usec = Time.get_ticks_usec()
        last_count = 4

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
