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
var max_song_time := 0.0
var countdown_start_usec := 0
var countdown_pause_usec := 0
var last_count := 4
var states: Array[bool] = []
var event_grades: Array[String] = []
var audio := AudioStreamPlayer.new()
var sfx := AudioStreamPlayer.new()
var tone_cache := {}
var ending := false
var is_holding := false
var hold_start_time := 0.0

func _ready() -> void:
	add_child(audio)
	add_child(sfx)
	audio.finished.connect(_on_audio_finished)
	for key in ["Perfect", "Good", "Miss"]:
		tone_cache[key] = RhythmSynth.make_hit(key)
	tone_cache["Tick"] = RhythmSynth.make_ui_sfx("focus")

func configure(game: Dictionary, profile: Dictionary) -> void:
	manifest = game
	chart = game["_chart"]
	settings = profile
	states.clear()
	event_grades.clear()
	for _event in chart.get("events", []):
		states.append(false)
		event_grades.append("")
	var gid := str(game["id"])
	tone_cache["Perfect"] = RhythmSynth.make_world_hit(gid, "Perfect")
	tone_cache["Perfect:left"] = RhythmSynth.make_world_hit(gid, "Perfect", "left")
	tone_cache["Perfect:right"] = RhythmSynth.make_world_hit(gid, "Perfect", "right")
	tone_cache["Good"] = RhythmSynth.make_world_hit(gid, "Good")
	tone_cache["Miss"] = RhythmSynth.make_world_hit(gid, "Miss")
	tone_cache["Tick"] = RhythmSynth.make_ui_sfx("focus")
	audio.stream = RhythmSynth.make_song(gid, float(chart["bpm"]), float(chart["duration"]), chart.get("calls", []))
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
		if i < event_grades.size():
			event_grades[i] = ""
	ending = false
	paused = false
	active = false
	is_holding = false
	hold_start_time = 0.0
	song_time = 0.0
	max_song_time = 0.0
	last_count = 4
	countdown_start_usec = Time.get_ticks_usec()
	countdown_pause_usec = 0
	set_process(true)

func _on_audio_finished() -> void:
	if active and not paused and not ending:
		_resolve_remaining_misses()
		_finish()

func _resolve_remaining_misses() -> void:
	var events: Array = chart.get("events", [])
	for i in events.size():
		if not states[i]:
			_apply(i, "Miss")

func _process(_delta: float) -> void:
	if paused or ending:
		return
	if not active:
		var elapsed := float(Time.get_ticks_usec() - countdown_start_usec) / 1000000.0
		var spb := clampf(60.0 / float(chart.get("bpm", 100.0)), 0.40, 1.00)
		var beats_elapsed := elapsed / spb
		var remaining := maxi(0, 3 - int(beats_elapsed))
		if remaining != last_count:
			last_count = remaining
			if remaining > 0 and tone_cache.has("Tick"):
				sfx.stream = tone_cache["Tick"]
				sfx.play()
			countdown.emit(remaining)
		if beats_elapsed >= 4.0:
			active = true
			audio.play()
			countdown.emit(-1)  # UI leaves READY/GO on the exact 4/4 downbeat of measure 1!
		return
	var duration_sec := float(chart.get("duration", 36.0))
	var events: Array = chart.get("events", [])
	var last_ev_sec := _event_time(events[events.size() - 1]) if not events.is_empty() else duration_sec
	if not audio.playing:
		# If the track reached its natural end (or passed the final chart event), finish instead of pausing!
		if max_song_time >= duration_sec - 1.5 or max_song_time >= last_ev_sec:
			_resolve_remaining_misses()
			_finish()
			return
		# Otherwise background-tab audio suspension occurred mid-song:
		pause_session()
		return
	song_time = _read_song_time()
	max_song_time = maxf(max_song_time, song_time)
	var all_done := true
	for i in events.size():
		if not states[i] and song_time - _event_time(events[i]) > RhythmJudge.MISS_WINDOW:
			_apply(i, "Miss")
		if not states[i]:
			all_done = false
	if song_time >= duration_sec - 0.35 or (all_done and song_time >= last_ev_sec + 1.2):
		_finish()

func submit(lane: String) -> void:
	submit_press(lane)

func submit_press(lane: String) -> void:
	if not active or paused or ending:
		return
	song_time = _read_song_time()
	max_song_time = maxf(max_song_time, song_time)
	is_holding = true
	hold_start_time = song_time
	_submit_at_time(lane, song_time, "press")

func submit_release(lane: String) -> void:
	if not active or paused or ending or not is_holding:
		return
	is_holding = false
	song_time = _read_song_time()
	max_song_time = maxf(max_song_time, song_time)
	_submit_at_time(lane, song_time, "release")

func _submit_at_time(lane: String, at_seconds: float, action: String = "press") -> void:
	# Separate deterministic input matching from hardware clock sampling for regression tests.
	var best_index := -1
	var best_delta := INF
	var wrong_index := -1
	var wrong_delta := INF
	var events: Array = chart["events"]
	for i in events.size():
		if states[i]:
			continue
		var ev_act: String = str(events[i].get("action", "press"))
		if ev_act != action:
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
	elif action == "press":
		# Ghost taps break combo but cannot inflate event-based Miss totals.
		combo = 0
		_sound("Miss", lane)
		feedback.emit("Outside", lane, combo)

func _apply(index: int, grade_name: String) -> void:
	states[index] = true
	if index < event_grades.size():
		event_grades[index] = grade_name
	counts[grade_name] += 1
	if grade_name == "Miss":
		combo = 0
	else:
		combo += 1
		max_combo = maxi(max_combo, combo)
		score += RhythmJudge.points(grade_name) + mini(combo, 50) * 10
	var lane_name := str(chart["events"][index]["lane"])
	_sound(grade_name, lane_name)
	feedback.emit(grade_name, lane_name, combo)

func _sound(grade_name: String, lane: String = "") -> void:
	var key := "%s:%s" % [grade_name, lane]
	if tone_cache.has(key):
		sfx.stream = tone_cache[key]
	else:
		sfx.stream = tone_cache.get(grade_name, tone_cache["Miss"])
	sfx.play()

func _read_song_time() -> float:
	var since_mix := clampf(AudioServer.get_time_since_last_mix(), 0.0, 0.050)
	var out_lat := clampf(AudioServer.get_output_latency(), 0.0, 0.060)
	return RhythmJudge.corrected_time(audio.get_playback_position(), since_mix, out_lat, int(settings["input_ms"]), int(settings["output_ms"]))

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
	if ending:
		return
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
