extends RhythmVisual

const WALL_LIGHT := Color("fce0a2")
const WALL_WARM := Color("f7cf86")
const PILLAR_COL := Color("d6b272")
const PIPE_BLUE := Color("486387")
const PIPE_GREY := Color("8892a8")
const PISTON_SILVER := Color("b0b8c9")
const BELT_DARK := Color("63697a")
const BELT_MID := Color("8b93a6")
const ROLLER_SILVER := Color("cdd4e3")
const BOX_TAN := Color("f6c26b")
const BOX_STAMPED := Color("ffe082")
const BOX_TAPE := Color("bd7b38")

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

	# 1. Background Layer: Warm Factory Wall, Vertical Pillars, Right Blueprint & Feeder Dispenser
	draw_rect(Rect2(0, 0, w, h), WALL_LIGHT)
	draw_rect(Rect2(0, 0, w * 0.25, h), WALL_WARM)
	var beam_x := w * 0.71
	draw_rect(Rect2(beam_x - 8.0, 0, 16.0, h * 0.84), PILLAR_COL)
	draw_line(Vector2(beam_x - 8.0, 0), Vector2(beam_x - 8.0, h * 0.84), CartoonDraw.INK, 3.5, true)
	draw_line(Vector2(beam_x + 8.0, 0), Vector2(beam_x + 8.0, h * 0.84), CartoonDraw.INK, 3.5, true)

	# Upper-right framed box blueprint poster (Panels 03 & 04)
	var post_rect := Rect2(w * 0.85, h * 0.14, w * 0.13, h * 0.22)
	CartoonDraw.draw_outlined_box(self, post_rect, Color("8d9eb8"), CartoonDraw.INK, 3.5, 4.0)
	CartoonDraw.draw_outlined_box(self, post_rect.grow(-7.0), Color("dff0fa"), CartoonDraw.INK, 2.5, 2.0)
	var pc := post_rect.get_center()
	CartoonDraw.draw_outlined_box(self, Rect2(pc.x - 18.0, pc.y - 14.0, 36.0, 28.0), Color("bde0f5"), Color("4a6b8c"), 2.5, 3.0)
	draw_line(pc + Vector2(-18.0, -14.0), pc + Vector2(0, -22.0), Color("4a6b8c"), 2.5, true)
	draw_line(pc + Vector2(18.0, -14.0), pc + Vector2(0, -22.0), Color("4a6b8c"), 2.5, true)

	# Lower-right grey box feeder cabinet with red indicator lamp (Panels 03 & 04)
	var cab_rect := Rect2(w * 0.82, h * 0.56, w * 0.16, h * 0.26)
	var lamp_col := Color("ff3b30") if (int(floorf(maxf(0.0, beat) * 2.0)) % 2 == 0) else Color("ff7b6b")
	CartoonDraw.draw_outlined_box(self, Rect2(cab_rect.get_center().x - 10.0, cab_rect.position.y - 14.0, 20.0, 14.0), lamp_col, CartoonDraw.INK, 3.0, 5.0)
	CartoonDraw.draw_outlined_box(self, cab_rect, Color("9ba6be"), CartoonDraw.INK, 3.8, 6.0)
	CartoonDraw.draw_outlined_box(self, Rect2(cab_rect.position.x + 12.0, cab_rect.position.y + 14.0, 28.0, 28.0), Color("79859e"), CartoonDraw.INK, 2.8, 3.0)
	CartoonDraw.draw_outlined_box(self, Rect2(cab_rect.position.x + 48.0, cab_rect.position.y + 14.0, 28.0, 28.0), Color("79859e"), CartoonDraw.INK, 2.8, 3.0)

	var belt_y := h * 0.82
	var press_cx := w * 0.28

	# 2. Midground Operator Platform: Factory Worker & Red Lever (Panels 03, 04, 10)
	# Raised catwalk above box height so boxes travelling along the belt pass UNDER her, never over her face
	var booth_y := belt_y - ((56.0 if is_narrow else 72.0) + 14.0)
	var deck := Rect2(w * 0.455, booth_y - 4.0, w * 0.20, 16.0)
	for leg_x in [deck.position.x + 14.0, deck.end.x - 14.0]:
		CartoonDraw.draw_outlined_box(self, Rect2(leg_x - 5.0, booth_y + 8.0, 10.0, belt_y - booth_y - 8.0), Color("79859e"), CartoonDraw.INK, 3.0, 2.0)
	CartoonDraw.draw_outlined_box(self, deck, Color("8892a8"), CartoonDraw.INK, 3.5, 4.0)
	var worker_pos := Vector2(w * 0.55, booth_y - 2.0 + bob * 0.5)
	var worker_s := (0.78 if is_narrow else 0.94)
	var worker_pose := "idle"
	var worker_face := 0
	if react_ratio > 0.0:
		if last_grade == "Miss":
			worker_pose = "idle"
			worker_face = 5
		else:
			worker_pose = "hit"
			worker_face = 3
	elif counting or ant_ratio > 0.15 or beat < 4.5:
		worker_pose = "ready"
		worker_face = 4 if counting else 0

	CartoonDraw.draw_factory_worker(self, worker_pos, worker_s, worker_pose, worker_face, true)

	# Speech Bubble "READY..." / "STAMP!" in Idle/Ready state (Panel 03) or Comic "PERFECT!" Burst on Hit (Panel 04)
	if react_ratio > 0.0:
		paint_feedback(Vector2(w * (0.65 if is_narrow else 0.67), h * 0.35), false)
	else:
		var bub_w := 175.0 if is_narrow else 245.0
		var bub_h := 66.0 if is_narrow else 82.0
		var bub_rect := Rect2(w * 0.45, h * 0.30, bub_w, bub_h)
		var cue_txt := "STAMP!" if ant_ratio > 0.45 else "READY..."
		var bub_fill := Color("fff5c0") if ant_ratio > 0.45 else CartoonDraw.PAPER
		CartoonDraw.draw_speech_bubble(self, bub_rect, worker_pos + Vector2(8.0, -96.0 * worker_s), cue_txt, bub_fill, CartoonDraw.INK, 24 if is_narrow else 34)

	# 3. Target Stamp Zone Indicator on the Conveyor Belt under press_cx (w * 0.28)
	var target_w := 84.0 if is_narrow else 110.0
	var target_glow := clampf(ant_ratio * 1.2, 0.0, 1.0)
	if not counting:
		# Subtle vertical guide ticks between stamp head and target pad so player sees exact hit line
		var guide_col := Color(1.0, 0.78, 0.15, 0.30 + target_glow * 0.45)
		draw_line(Vector2(press_cx, h * 0.50), Vector2(press_cx, belt_y - 4.0), guide_col, 3.0, true)
		var ring_r := (42.0 if is_narrow else 54.0) * (1.35 - 0.35 * target_glow)
		if ant_ratio > 0.05:
			draw_arc(Vector2(press_cx, belt_y - 34.0), ring_r, 0.0, TAU, 32, Color(1.0, 0.84, 0.18, 0.45 + 0.45 * target_glow), 4.0, true)

	# 4. Cardboard Boxes Moving Continuously Right -> Left Along the Conveyor Belt
	_draw_conveyor_boxes(w, belt_y, press_cx, is_narrow, beat, counting, react_ratio)

	# 5. Midground Overhead Stamp Press Machine (x = 0.28 * w, Panels 03 & 04)
	# Drawn after boxes so the stamp pad physically presses down onto the top of the box!
	var press_drop := 0.0
	if react_ratio > 0.0 and last_grade != "Miss":
		press_drop = clampf(react_ratio * 1.55, 0.0, 1.0) * (h * 0.22)
	elif ant_ratio > 0.0:
		press_drop = -ant_ratio * 10.0

	CartoonDraw.draw_limb(self, Vector2(press_cx - 72.0, h * 0.10), Vector2(press_cx - 72.0, h * 0.25), 11.0, PIPE_GREY, CartoonDraw.INK, 4.0)
	CartoonDraw.draw_limb(self, Vector2(press_cx - 72.0, h * 0.25), Vector2(press_cx, h * 0.25), 11.0, PIPE_GREY, CartoonDraw.INK, 4.0)
	CartoonDraw.draw_limb(self, Vector2(press_cx + 88.0, h * 0.10), Vector2(press_cx + 88.0, h * 0.25), 10.0, PIPE_GREY, CartoonDraw.INK, 4.0)
	CartoonDraw.draw_limb(self, Vector2(press_cx + 88.0, h * 0.25), Vector2(press_cx, h * 0.25), 10.0, PIPE_GREY, CartoonDraw.INK, 4.0)
	CartoonDraw.draw_outlined_box(self, Rect2(press_cx - 26.0, h * 0.14, 52.0, h * 0.16), PIPE_BLUE, CartoonDraw.INK, 4.2, 8.0)

	var piston_top := h * 0.29
	var piston_h := h * 0.11 + press_drop
	CartoonDraw.draw_outlined_box(self, Rect2(press_cx - 24.0, piston_top, 48.0, maxf(24.0, piston_h)), PISTON_SILVER, CartoonDraw.INK, 4.2, 4.0)

	var head_y := piston_top + maxf(24.0, piston_h) - 2.0
	var head_w_top := 68.0 if is_narrow else 86.0
	var head_w_bot := 108.0 if is_narrow else 138.0
	var head_h := 48.0 if is_narrow else 58.0
	var trap_pts := PackedVector2Array([
		Vector2(press_cx - head_w_top * 0.5, head_y),
		Vector2(press_cx + head_w_top * 0.5, head_y),
		Vector2(press_cx + head_w_bot * 0.5, head_y + head_h),
		Vector2(press_cx - head_w_bot * 0.5, head_y + head_h),
	])
	CartoonDraw.draw_outlined_polygon(self, trap_pts, Color("ffd524"), CartoonDraw.INK, 4.5)
	var stripe_a := PackedVector2Array([
		Vector2(press_cx - head_w_top * 0.20, head_y + 3.0),
		Vector2(press_cx + head_w_top * 0.08, head_y + 3.0),
		Vector2(press_cx - head_w_bot * 0.10, head_y + head_h - 14.0),
		Vector2(press_cx - head_w_bot * 0.34, head_y + head_h - 14.0),
	])
	var stripe_b := PackedVector2Array([
		Vector2(press_cx + head_w_top * 0.24, head_y + 3.0),
		Vector2(press_cx + head_w_top * 0.44, head_y + 3.0),
		Vector2(press_cx + head_w_bot * 0.34, head_y + head_h - 14.0),
		Vector2(press_cx + head_w_bot * 0.08, head_y + head_h - 14.0),
	])
	draw_colored_polygon(stripe_a, Color("2b2b38"))
	draw_colored_polygon(stripe_b, Color("2b2b38"))
	var base_pad := Rect2(press_cx - head_w_bot * 0.5, head_y + head_h - 16.0, head_w_bot, 18.0)
	CartoonDraw.draw_outlined_box(self, base_pad, Color("e86832"), CartoonDraw.INK, 4.2, 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(press_cx - head_w_bot * 0.25, head_y + head_h - 16.0),
		Vector2(press_cx + head_w_bot * 0.22, head_y + head_h - 16.0),
		Vector2(press_cx + head_w_bot * 0.28, head_y + head_h + 2.0),
		Vector2(press_cx - head_w_bot * 0.30, head_y + head_h + 2.0),
	]), Color("383745"))
	if react_ratio > 0.0 and last_grade != "Miss":
		var pad_cy := base_pad.get_center().y
		var lw1 := PackedVector2Array([Vector2(base_pad.position.x - 6.0, pad_cy - 4.0), Vector2(base_pad.position.x - 42.0, pad_cy - 22.0), Vector2(base_pad.position.x - 34.0, pad_cy - 2.0)])
		var lw2 := PackedVector2Array([Vector2(base_pad.position.x - 6.0, pad_cy + 4.0), Vector2(base_pad.position.x - 44.0, pad_cy + 18.0), Vector2(base_pad.position.x - 32.0, pad_cy + 2.0)])
		var rw1 := PackedVector2Array([Vector2(base_pad.end.x + 6.0, pad_cy - 4.0), Vector2(base_pad.end.x + 42.0, pad_cy - 22.0), Vector2(base_pad.end.x + 34.0, pad_cy - 2.0)])
		var rw2 := PackedVector2Array([Vector2(base_pad.end.x + 6.0, pad_cy + 4.0), Vector2(base_pad.end.x + 44.0, pad_cy + 18.0), Vector2(base_pad.end.x + 32.0, pad_cy + 2.0)])
		for wpoly in [lw1, lw2, rw1, rw2]:
			CartoonDraw.draw_outlined_polygon(self, wpoly, CartoonDraw.GOLD, CartoonDraw.INK, 3.0)

	# Left Midground: Grey Industrial Pressure-Gauge Tower (drawn over left exit so outgoing boxes slide cleanly inside!)
	var tower_w := w * (0.14 if is_narrow else 0.11)
	CartoonDraw.draw_outlined_box(self, Rect2(18.0, h * 0.10, 26.0, h * 0.30), PIPE_GREY, CartoonDraw.INK, 3.8, 4.0)
	var tower_rect := Rect2(4.0, h * 0.36, tower_w, h * 0.48)
	CartoonDraw.draw_outlined_box(self, tower_rect, Color("a6b0c6"), CartoonDraw.INK, 4.0, 6.0)
	var dial_c := Vector2(tower_rect.get_center().x - 4.0, h * 0.52)
	var dial_r := minf(tower_w * 0.44, 34.0)
	CartoonDraw.draw_outlined_circle(self, dial_c, dial_r, CartoonDraw.PAPER, CartoonDraw.INK, 3.8)
	var needle_ang := -PI * 0.72 + (0.0 if reduced_motion else sin(beat * TAU) * 0.35) + (0.55 if react_ratio > 0.0 else 0.0)
	draw_line(dial_c, dial_c + Vector2(cos(needle_ang), sin(needle_ang)) * (dial_r * 0.72), Color("e63946"), 3.5, true)
	draw_circle(dial_c, 4.0, Color("e63946"))

	# 6. Foreground Layer: Conveyor Belt Track, Target Anvil Plate & 4 Rotating Silver Rollers (Panels 03 & 04)
	CartoonDraw.draw_outlined_box(self, Rect2(-6.0, belt_y, w + 12.0, 18.0), Color("b8c0d2"), CartoonDraw.INK, 4.2, 2.0)
	# Highlighted target anvil plate directly under press_cx on the belt rail
	var anvil_col := Color("ffd524") if target_glow > 0.25 else Color("e86832")
	CartoonDraw.draw_outlined_box(self, Rect2(press_cx - target_w * 0.5, belt_y - 3.0, target_w, 12.0), anvil_col, CartoonDraw.INK, 3.2, 3.0)
	CartoonDraw.draw_outlined_box(self, Rect2(-6.0, belt_y + 16.0, w + 12.0, h - belt_y), BELT_DARK, CartoonDraw.INK, 4.2, 2.0)
	var roller_xs := [w * 0.17, w * 0.39, w * 0.61, w * 0.83]
	var roller_r := 22.0 if is_narrow else 28.0
	var roller_y := belt_y + 18.0 + (h - belt_y - 18.0) * 0.52
	for rx in roller_xs:
		CartoonDraw.draw_outlined_circle(self, Vector2(rx, roller_y), roller_r, ROLLER_SILVER, CartoonDraw.INK, 4.2)
		CartoonDraw.draw_outlined_circle(self, Vector2(rx, roller_y), roller_r * 0.32, Color("2e3242"), CartoonDraw.INK, 3.0)
		var spoke_a := 0.0 if reduced_motion else -beat * 2.8
		draw_line(Vector2(rx, roller_y) + Vector2(cos(spoke_a), sin(spoke_a)) * (roller_r * 0.35), Vector2(rx, roller_y) + Vector2(cos(spoke_a), sin(spoke_a)) * (roller_r * 0.88), CartoonDraw.INK, 2.8, true)

	# 7. Top Stage HUD Bar (Panels 03 & 04)
	var lit_dots := 0 if (counting or (score_value() == 0 and beat < 4.0)) else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	CartoonDraw.draw_stage_hud_banner(self, w, "Beat Factory", beat, score_value(), combo_value(), lit_dots, Color.WHITE)

func _draw_conveyor_boxes(w: float, belt_y: float, press_cx: float, is_narrow: bool, beat: float, counting: bool, _react_ratio: float) -> void:
	var box_w := 68.0 if is_narrow else 90.0
	var box_h := 56.0 if is_narrow else 72.0

	if counting:
		# Pre-roll idle staging (Panel 03 composition: boxes waiting at right side of conveyor)
		_draw_single_box(Vector2(w * 0.755, belt_y), box_w, box_h, false, false)
		_draw_single_box(Vector2(w * 0.985, belt_y), box_w, box_h, false, false)
		return

	# Constant conveyor speed: boxes enter at the far right (0.985 * w) 3.0 beats before hit time
	# and reach the Stamp Press (press_cx = 0.28 * w) at diff == 0.0 (speed = 0.235 * w per beat)
	var speed_per_beat := w * 0.235
	var events: Array = chart.get("events", [])
	for i in range(events.size()):
		var eb := float(events[i].get("beat", 0.0))
		var diff := eb - beat
		if diff < -1.15 or diff > 3.35:
			continue
		var bx := press_cx + diff * speed_per_beat
		var ev_g := event_grade(i)
		var is_stamped := (ev_g == "Perfect" or ev_g == "Good")
		var is_missed := (ev_g == "Miss") or (diff < -0.28 and not is_stamped)
		var squash := 1.0
		if is_stamped and diff <= 0.15 and diff >= -0.35:
			squash = 0.82 + 0.18 * clampf(absf(diff) / 0.35, 0.0, 1.0)
		_draw_single_box(Vector2(bx, belt_y), box_w, box_h * squash, is_stamped, is_missed)

func _draw_single_box(bottom_center: Vector2, bw: float, bh: float, stamped_happy: bool, missed: bool) -> void:
	var rect := Rect2(bottom_center.x - bw * 0.5, bottom_center.y - bh, bw, bh)
	var fill_col := BOX_STAMPED if stamped_happy else BOX_TAN
	CartoonDraw.draw_outlined_box(self, rect, fill_col, CartoonDraw.INK, 4.2, 4.0)
	var tape_w := bw * 0.16
	var tape_col := Color("e63946") if stamped_happy else BOX_TAPE
	CartoonDraw.draw_outlined_box(self, Rect2(bottom_center.x - tape_w * 0.5, rect.position.y + 2.0, tape_w, bh * 0.18), tape_col, CartoonDraw.INK, 2.8, 1.0)
	var fc := rect.get_center() + Vector2(0, 4.0)
	if missed:
		CartoonDraw.draw_eyes(self, fc + Vector2(0, -4.0), bw * 0.36, 5.0, "dizzy")
		CartoonDraw.draw_mouth(self, fc + Vector2(0, 10.0), 14.0, 7.0, "frown")
	elif stamped_happy:
		CartoonDraw.draw_eyes(self, fc + Vector2(0, -4.0), bw * 0.34, 5.2, "normal")
		CartoonDraw.draw_mouth(self, fc + Vector2(0, 8.0), 14.0, 8.0, "smile")
		CartoonDraw.draw_star(self, rect.position + Vector2(bw - 14.0, 14.0), 8.0, 3.8, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.2)
	else:
		CartoonDraw.draw_eyes(self, fc + Vector2(0, -4.0), bw * 0.36, 5.2, "normal")
		draw_line(fc + Vector2(-bw * 0.18, -7.0), fc + Vector2(bw * 0.18, -7.0), CartoonDraw.INK, 3.8, true)
		CartoonDraw.draw_mouth(self, fc + Vector2(0, 8.0), 14.0, 8.0, "smile")
