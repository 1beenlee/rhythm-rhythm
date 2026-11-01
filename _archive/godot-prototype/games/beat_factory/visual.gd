extends RhythmVisual

var bg_tex: Texture2D
var worker_tex: Texture2D
var boxes_tex: Texture2D
var press_tex: Texture2D
var fb_tex: Texture2D

func _ready() -> void:
	bg_tex = load("res://assets/sprites/bg_factory.png")
	worker_tex = load("res://assets/sprites/beat_factory/worker.png")
	boxes_tex = load("res://assets/sprites/beat_factory/boxes.png")
	press_tex = load("res://assets/sprites/beat_factory/stamp_press.png")
	fb_tex = load("res://assets/sprites/common/feedback.png")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var next_diff := next_event_diff("tap")
	var ant_ratio := clampf(1.0 - (next_diff / 0.85), 0.0, 1.0) if (next_diff >= 0.0 and next_diff <= 0.85) else 0.0
	var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# 1. Full-Resolution 960x640 Pre-rendered Background
	if bg_tex:
		draw_texture_rect(bg_tex, Rect2(0, 0, w, h), false)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("fce0a2"))

	var belt_y := h * 0.82
	var press_cx := w * 0.28
	var speed_per_beat := w * 0.235

	# Check for Active Hold under the Press
	var is_holding_now := (session != null and session.is_holding)
	var active_hold_ev := {}
	var active_hold_progress := 0.0
	var events: Array = chart.get("events", [])
	for ev in events:
		var eb := float(ev.get("beat", 0.0))
		var hlen := float(ev.get("hold_len", 0.0))
		var act := str(ev.get("action", "press"))
		if act == "press" and hlen > 0.0:
			if beat >= eb and beat < eb + hlen:
				active_hold_ev = ev
				active_hold_progress = clampf((beat - eb) / hlen, 0.0, 1.0)
				break

	# 2. Worker Catwalk & Character Sprite
	var worker_sz := 160.0 if is_narrow else 210.0
	var worker_x := w * 0.54 - worker_sz * 0.5
	var worker_y := belt_y - 20.0 - worker_sz + bob * 0.5

	# Frame index: 0=Idle, 1=Ready/Lever Pulled, 2=Hit, 3=Miss
	var worker_frame := 0
	if react_ratio > 0.0:
		worker_frame = 3 if last_grade == "Miss" else 2
	elif (not active_hold_ev.is_empty() and is_holding_now):
		# Holding the lever firmly down!
		worker_frame = 1
	elif ant_ratio > 0.20 or counting:
		worker_frame = 1

	if worker_tex:
		var src_worker := Rect2(float(worker_frame) * 512.0, 0.0, 512.0, 512.0)
		draw_texture_rect_region(worker_tex, Rect2(worker_x, worker_y, worker_sz, worker_sz), src_worker)

	# 3. Conveyor Belt Track & Boxes Moving Right -> Left
	_draw_conveyor_boxes(w, belt_y, press_cx, speed_per_beat, beat, counting, is_narrow, is_holding_now)

	# 4. Stamp Press Machine (x = 0.28 * w)
	var press_drop := 0.0
	if not active_hold_ev.is_empty() and is_holding_now:
		# Clamped firmly down on top of the stopped box!
		press_drop = h * 0.23
	elif react_ratio > 0.0 and last_grade != "Miss":
		press_drop = clampf(react_ratio * 1.55, 0.0, 1.0) * (h * 0.23)
	elif ant_ratio > 0.0:
		press_drop = -ant_ratio * 8.0

	var stamp_w := 125.0 if is_narrow else 155.0
	var stamp_h := 125.0 if is_narrow else 155.0
	var stamp_x := press_cx - stamp_w * 0.5
	var stamp_y := h * 0.16 + press_drop

	if press_tex:
		draw_texture_rect(press_tex, Rect2(stamp_x, stamp_y, stamp_w, stamp_h), false)

	# Steam pressure & rising charge effects during hold
	if not active_hold_ev.is_empty() and is_holding_now:
		var steam_alpha := 0.35 + 0.65 * active_hold_progress
		for s_side: float in [-1.0, 1.0]:
			var sx: float = press_cx + s_side * (stamp_w * 0.42)
			var sy: float = stamp_y + stamp_h - 12.0
			draw_circle(Vector2(sx + sin(beat * 24.0) * 3.5, sy - 10.0 * active_hold_progress), 10.0 * (1.0 + active_hold_progress), Color(1.0, 1.0, 1.0, steam_alpha * 0.6))

	# Target Hit Zone Ring under stamp press
	if not counting:
		var ring_alpha := 0.35 + 0.55 * ant_ratio
		draw_arc(Vector2(press_cx, belt_y - 25.0), 38.0 if is_narrow else 48.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, ring_alpha), 3.5, true)

	# 5. Feedback Badge on Hit
	if react_ratio > 0.0:
		var fb_w := 140.0 if is_narrow else 170.0
		var fb_h := 40.0 if is_narrow else 48.0
		var fb_frame := 2 if last_grade == "Miss" else (0 if last_grade == "Perfect" else 1)
		if fb_tex:
			var src_fb := Rect2(float(fb_frame) * 220.0, 0.0, 220.0, 64.0)
			draw_texture_rect_region(fb_tex, Rect2(press_cx - fb_w * 0.5, h * 0.30, fb_w, fb_h), src_fb)

	# 6. Top Stage HUD Bar
	var lit_dots := 0 if (counting or (score_value() == 0 and beat < 4.0)) else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	CartoonDraw.draw_stage_hud_banner(self, w, "Beat Factory", beat, score_value(), combo_value(), lit_dots, Color.WHITE)

func _draw_conveyor_boxes(w: float, belt_y: float, press_cx: float, speed_per_beat: float, beat: float, counting: bool, is_narrow: bool, is_holding_now: bool) -> void:
	var box_w := 80.0 if is_narrow else 105.0
	var box_h := 66.0 if is_narrow else 88.0

	if counting:
		# Staging idle boxes waiting at right conveyor
		_draw_box_sprite(Vector2(w * 0.75, belt_y), box_w, box_h, 0)
		_draw_box_sprite(Vector2(w * 0.95, belt_y), box_w, box_h, 0)
		return

	var events: Array = chart.get("events", [])
	for i in range(events.size()):
		var ev: Dictionary = events[i]
		var action := str(ev.get("action", "press"))
		var hold_len := float(ev.get("hold_len", 0.0))

		# CRITICAL: "release" event is the conclusion of the hold, NOT a second box!
		if action == "release":
			continue

		var eb := float(ev.get("beat", 0.0))
		var ev_g := event_grade(i)
		var is_stamped := (ev_g == "Perfect" or ev_g == "Good")
		var is_missed := (ev_g == "Miss")
		var bx := press_cx
		var is_active_hold := false

		if hold_len > 0.0:
			var rel_beat := eb + hold_len
			if beat < eb:
				var diff := eb - beat
				if diff > 3.8:
					continue
				bx = press_cx + diff * speed_per_beat
			elif beat < rel_beat:
				# STOPPED FIRMLY UNDER THE PRESS!
				bx = press_cx
				is_active_hold = true
			else:
				var diff := rel_beat - beat
				if diff < -1.4:
					continue
				bx = press_cx + diff * speed_per_beat
		else:
			var diff := eb - beat
			if diff < -1.4 or diff > 3.8:
				continue
			bx = press_cx + diff * speed_per_beat

		# Box frame:
		# 0=normal, 1=stamped happy, 2=crushed miss, 3=hold charge box (blue valve), 4=gold stamped
		var frame_idx := 0
		if hold_len > 0.0:
			var rel_beat := eb + hold_len
			if beat >= rel_beat:
				var rel_grade := event_grade(i + 1)
				if rel_grade == "Perfect" or rel_grade == "Good":
					frame_idx = 4
				elif rel_grade == "Miss":
					frame_idx = 2
				else:
					frame_idx = 4 if is_stamped else 3
			else:
				frame_idx = 2 if is_missed else 3
		else:
			if beat >= eb:
				frame_idx = 1 if is_stamped else (2 if is_missed else 1)
			else:
				frame_idx = 0

		# Squash & vibration
		var squash := 1.0
		var shake := 0.0
		if is_active_hold and is_holding_now:
			squash = 0.88
			shake = sin(beat * 45.0) * 1.5
		elif is_stamped and (beat - eb) >= 0.0 and (beat - eb) <= 0.25:
			squash = 0.82

		_draw_box_sprite(Vector2(bx, belt_y + shake), box_w, box_h * squash, frame_idx)

func _draw_box_sprite(bottom_center: Vector2, bw: float, bh: float, frame_idx: int) -> void:
	var rect := Rect2(bottom_center.x - bw * 0.5, bottom_center.y - bh, bw, bh)
	if boxes_tex:
		var frame_clamped := mini(frame_idx, 2)
		var src_box := Rect2(float(frame_clamped) * 512.0, 0.0, 512.0, 512.0)
		draw_texture_rect_region(boxes_tex, rect, src_box)
	else:
		draw_rect(rect, Color("f6c26b"))
