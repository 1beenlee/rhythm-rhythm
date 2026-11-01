extends Control
class_name RhythmVisual

var chart: Dictionary = {}
var session: RhythmSession
var last_grade := ""
var last_lane := ""
var flash := 0.0
var reaction_timer := 0.0
var last_combo := 0
var reduced_motion := false
var forced_score := -1
var forced_combo := -1

func configure(game_chart: Dictionary, live_session: RhythmSession, minimal_motion: bool) -> void:
	chart = game_chart
	session = live_session
	reduced_motion = minimal_motion
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	session.feedback.connect(show_feedback)
	set_process(true)

func _gui_input(event: InputEvent) -> void:
	if session == null or not session.active or session.paused:
		return
	var lanes: Array = session.manifest.get("lanes", ["tap"]) if session.manifest != null else ["tap"]
	var is_single := (lanes.size() == 1)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var lane := "tap" if is_single else ("left" if event.position.x < size.x * 0.5 else "right")
		if event.pressed:
			session.submit_press(lane)
		else:
			session.submit_release(lane)
		accept_event()
	elif event is InputEventScreenTouch:
		var lane := "tap" if is_single else ("left" if event.position.x < size.x * 0.5 else "right")
		if event.pressed:
			session.submit_press(lane)
		else:
			session.submit_release(lane)
		accept_event()

func show_feedback(grade_name: String, lane: String, combo_val: int) -> void:
	last_grade = grade_name if grade_name != "Outside" else "Miss"
	last_lane = lane
	last_combo = combo_val
	flash = 0.42
	reaction_timer = 0.48
	queue_redraw()

func _process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	reaction_timer = maxf(0.0, reaction_timer - delta)
	queue_redraw()

func is_counting_down() -> bool:
	return session != null and not session.active and session.song_time <= 0.0

func current_beat() -> float:
	if session == null:
		return 0.0
	return session.song_time * float(chart.get("bpm", 100.0)) / 60.0

func score_value() -> int:
	if forced_score >= 0:
		return forced_score
	return session.score if session != null else 0

func combo_value() -> int:
	if forced_combo >= 0:
		return forced_combo
	return session.combo if session != null else last_combo

func event_grade(index: int) -> String:
	if session == null:
		return ""
	if index < session.event_grades.size() and session.event_grades[index] != "":
		return session.event_grades[index]
	if index < session.states.size() and session.states[index]:
		return "Perfect"
	return ""

func next_event_diff(lane_filter: String = "") -> float:
	if is_counting_down():
		return 999.0
	var beat := current_beat()
	var best := 999.0
	var events: Array = chart.get("events", [])
	for i in range(events.size()):
		if session != null and i < session.states.size() and session.states[i]:
			continue
		var ev: Dictionary = events[i]
		if lane_filter != "" and str(ev.get("lane", "")) != lane_filter:
			continue
		var diff := float(ev.get("beat", 0.0)) - beat
		if diff >= -0.15 and diff < best:
			best = diff
	return best

func paint_feedback(custom_center: Vector2 = Vector2(-1, -1), yellow_text: bool = false) -> void:
	if flash <= 0.0:
		return
	var ratio := 1.0 if reduced_motion else clampf(flash / 0.42, 0.0, 1.0)
	var is_narrow := size.x < 520.0
	var pop_scale := (0.76 if is_narrow else 1.0) + (0.0 if reduced_motion else sin(ratio * PI) * 0.10)
	var badge_center := custom_center
	if badge_center.x < 0.0:
		badge_center = Vector2(size.x * (0.64 if is_narrow else 0.68), size.y * 0.30)

	var label_str := "PERFECT!" if last_grade == "Perfect" else ("GOOD!" if last_grade == "Good" else "MISS!")
	if last_grade == "Perfect":
		# Matches Panels 04, 06, 08 comic jagged burst + stars + bold PERFECT! text
		CartoonDraw.draw_jagged_burst_box(self, badge_center, 138.0 * pop_scale, 58.0 * pop_scale, 14, CartoonDraw.PAPER, CartoonDraw.GOLD, CartoonDraw.INK, 4.5)
		CartoonDraw.draw_star(self, badge_center + Vector2(-148.0 * pop_scale, -14.0 * pop_scale), 16.0 * pop_scale, 7.0 * pop_scale, 5, -0.3, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
		CartoonDraw.draw_star(self, badge_center + Vector2(92.0 * pop_scale, 52.0 * pop_scale), 15.0 * pop_scale, 6.5 * pop_scale, 5, 0.25, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
		var txt_col := CartoonDraw.GOLD if yellow_text else CartoonDraw.HOT_PINK
		var fs := int(round(38.0 * pop_scale))
		CartoonDraw.draw_sticker_text(self, badge_center + Vector2(-140.0 * pop_scale, float(fs) * 0.36), label_str, int(280.0 * pop_scale), fs, txt_col, CartoonDraw.INK, Color.WHITE, 4.0, 7.5)
	elif last_grade == "Good":
		CartoonDraw.draw_jagged_burst_box(self, badge_center, 108.0 * pop_scale, 46.0 * pop_scale, 12, CartoonDraw.PAPER, CartoonDraw.MINT, CartoonDraw.INK, 4.0)
		var fs := int(round(32.0 * pop_scale))
		CartoonDraw.draw_sticker_text(self, badge_center + Vector2(-110.0 * pop_scale, float(fs) * 0.36), label_str, int(220.0 * pop_scale), fs, CartoonDraw.MINT, CartoonDraw.INK, Color.WHITE, 3.5, 6.5)
	else:
		var r_w := 148.0 * pop_scale
		var r_h := 50.0 * pop_scale
		CartoonDraw.draw_outlined_box(self, Rect2(badge_center - Vector2(r_w * 0.5, r_h * 0.5), Vector2(r_w, r_h)), CartoonDraw.CORAL, CartoonDraw.INK, 4.0, 14.0)
		var fs := int(round(28.0 * pop_scale))
		CartoonDraw.draw_outlined_text(self, badge_center + Vector2(-r_w * 0.5, float(fs) * 0.36), label_str, int(r_w), fs, CartoonDraw.PAPER, CartoonDraw.INK, 3.5)

func paint_event_bar(lane: String, y: float, center_x: float, scale_x: float) -> void:
	var current := current_beat()
	for event in chart.get("events", []):
		if str(event.get("lane", "")) != lane:
			continue
		var difference := float(event["beat"]) - current
		if difference < -0.45 or difference > 5.0:
			continue
		var x := center_x + difference * scale_x
		CartoonDraw.draw_star(self, Vector2(x, y), 14.0, 6.5, 5, current * 1.5, CartoonDraw.GOLD, CartoonDraw.INK, 3.0)
