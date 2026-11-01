extends RhythmVisual

var bg_tex: Texture2D
var alien_tex: Texture2D
var astro_tex: Texture2D
var stars_tex: Texture2D
var fb_tex: Texture2D

func _ready() -> void:
	bg_tex = load("res://assets/sprites/bg_cosmos.png")
	alien_tex = load("res://assets/sprites/echo_planet/alien.png")
	astro_tex = load("res://assets/sprites/echo_planet/astronauts.png")
	stars_tex = load("res://assets/sprites/common/stars_notes.png")
	fb_tex = load("res://assets/sprites/common/feedback.png")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var cycle_beat := fposmod(maxf(0.0, beat), 8.0)
	var is_response_turn := (not counting) and (cycle_beat >= 3.85 and cycle_beat < 8.0)
	var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# Check if alien is actively singing right now
	var singing_now := false
	if not counting and cycle_beat < 4.0:
		for c_item in chart.get("calls", []):
			var d := beat - float(c_item.get("beat", -99.0))
			if d >= -0.05 and d <= 0.35:
				singing_now = true
				break

	# 1. Full-Resolution Cosmic Landscape Background (960x640)
	if bg_tex:
		draw_texture_rect(bg_tex, Rect2(0, 0, w, h), false)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("4f2f96"))

	# 2. Alien Character on Left Podium
	# Frames: 0=Idle, 1=Sing, 2=Cheer, 3=Miss
	var alien_frame := 0
	if react_ratio > 0.0:
		alien_frame = 3 if last_grade == "Miss" else 2
	elif singing_now:
		alien_frame = 1
	elif is_response_turn:
		alien_frame = 0

	var alien_w := 125.0 if is_narrow else 155.0
	var alien_h := 165.0 if is_narrow else 205.0
	var alien_x := w * 0.18 - alien_w * 0.5
	var alien_y := h * 0.88 - alien_h + bob * 0.4

	if alien_tex:
		var src_alien := Rect2(float(alien_frame) * 150.0, 0.0, 150.0, 200.0)
		draw_texture_rect_region(alien_tex, Rect2(alien_x, alien_y, alien_w, alien_h), src_alien)

	# 3. Astronaut Kids on Right
	# Frames: 0=Listen, 1=Cheer, 2=Miss
	var astro_frame := 0
	if react_ratio > 0.0:
		astro_frame = 2 if last_grade == "Miss" else 1
	elif is_response_turn:
		astro_frame = 0

	var astro_w := 115.0 if is_narrow else 145.0
	var astro_h := 140.0 if is_narrow else 175.0
	var astro_x := w * 0.78 - astro_w * 0.5
	var astro_y := h * 0.90 - astro_h + bob * 0.3

	if astro_tex:
		var src_astro := Rect2(float(astro_frame) * 130.0, 0.0, 130.0, 160.0)
		draw_texture_rect_region(astro_tex, Rect2(astro_x, astro_y, astro_w, astro_h), src_astro)

	# 4. Dual Call & Response Rhythm Cue Display (Caller + Receiver together on one screen!)
	_draw_dual_rhythm_display(w, h, is_narrow, beat, cycle_beat, counting, react_ratio)

	# 5. Feedback Badge on Hit
	if react_ratio > 0.0:
		var fb_w := 130.0 if is_narrow else 160.0
		var fb_h := 38.0 if is_narrow else 46.0
		var fb_frame := 2 if last_grade == "Miss" else (0 if last_grade == "Perfect" else 1)
		if fb_tex:
			var src_fb := Rect2(float(fb_frame) * 220.0, 0.0, 220.0, 64.0)
			draw_texture_rect_region(fb_tex, Rect2(astro_x + astro_w * 0.5 - fb_w * 0.5, h * 0.52, fb_w, fb_h), src_fb)

	# 6. Top Stage HUD Bar
	var lit_dots := 0 if (counting or (score_value() == 0 and beat < 4.0)) else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	CartoonDraw.draw_stage_hud_banner(self, w, "Echo Planet", beat, score_value(), combo_value(), lit_dots, Color.WHITE)

func _draw_dual_rhythm_display(w: float, h: float, is_narrow: bool, beat: float, cycle_beat: float, counting: bool, _react_ratio: float) -> void:
	if counting:
		return

	# Big Top Cue Bar showing the current 8-beat cycle:
	# Left Half: Alien Call Notes (Beats 0-3)
	# Right Half: Human Response Notes (Beats 4-7)
	var bar_w := w * (0.88 if is_narrow else 0.76)
	var bar_h := 64.0 if is_narrow else 78.0
	var bar_rect := Rect2(w * 0.50 - bar_w * 0.5, h * 0.16, bar_w, bar_h)

	# Semi-transparent dark navy pill with clean rounded border
	draw_rect(bar_rect, Color(0.12, 0.10, 0.28, 0.88))
	draw_rect(bar_rect, Color(0.85, 0.80, 0.98, 0.90), false, 3.5)

	# Center divider between Call (Left) and Response (Right)
	var cx := bar_rect.get_center().x
	draw_line(Vector2(cx, bar_rect.position.y + 8.0), Vector2(cx, bar_rect.end.y - 8.0), Color(0.85, 0.80, 0.98, 0.60), 2.5, true)

	# Labels: "CALL" on left, "RESPONSE" on right
	CartoonDraw.draw_outlined_text(self, Vector2(bar_rect.position.x + 16.0, bar_rect.position.y + 18.0), "ALIEN CALL", int(bar_w * 0.4), 14, Color("ffd524"), Color("181624"), 2.0)
	CartoonDraw.draw_outlined_text(self, Vector2(cx + 16.0, bar_rect.position.y + 18.0), "YOUR TURN", int(bar_w * 0.4), 14, Color("4cc9f0"), Color("181624"), 2.0)

	var cycle_base := floorf(beat / 8.0) * 8.0
	var icon_size := 32.0 if is_narrow else 40.0

	# 1) Draw Call icons (Beats 0-4)
	for call in chart.get("calls", []):
		var cb := float(call.get("beat", 0.0))
		if cb >= cycle_base and cb < cycle_base + 4.0:
			var rel_b := cb - cycle_base
			var ix := bar_rect.position.x + (rel_b / 4.0) * (bar_w * 0.45) + 36.0
			var iy := bar_rect.position.y + bar_h * 0.56
			var is_active := (cycle_beat >= rel_b - 0.15 and cycle_beat <= rel_b + 0.45)
			var scale_mul := 1.25 if is_active else 1.0

			# Star icon from stars_notes.png (0=gold star, 1=pink star)
			var f_idx := 0 if is_active else 1
			if stars_tex:
				var src := Rect2(float(f_idx) * 64.0, 0.0, 64.0, 64.0)
				var d_rect := Rect2(ix - icon_size * 0.5 * scale_mul, iy - icon_size * 0.5 * scale_mul, icon_size * scale_mul, icon_size * scale_mul)
				draw_texture_rect_region(stars_tex, d_rect, src)

	# 2) Draw Response icons (Beats 4-8)
	var events: Array = chart.get("events", [])
	for i in range(events.size()):
		var ev: Dictionary = events[i]
		var eb := float(ev.get("beat", 0.0))
		if eb >= cycle_base + 3.8 and eb < cycle_base + 8.0:
			var rel_b := eb - cycle_base - 4.0
			var ix := cx + (rel_b / 4.0) * (bar_w * 0.45) + 36.0
			var iy := bar_rect.position.y + bar_h * 0.56
			var eg := event_grade(i)
			var is_hit := (eg == "Perfect" or eg == "Good")
			var is_miss := (eg == "Miss")
			var diff := eb - beat
			var is_active := (diff <= 0.20 and diff >= -0.30)
			var scale_mul := 1.28 if (is_active or is_hit) else 1.0

			# 0=gold star (hit), 2=cyan star (target), 3=sparkle
			var f_idx := 0 if is_hit else (2 if not is_miss else 1)
			if stars_tex:
				var src := Rect2(float(f_idx) * 64.0, 0.0, 64.0, 64.0)
				var d_rect := Rect2(ix - icon_size * 0.5 * scale_mul, iy - icon_size * 0.5 * scale_mul, icon_size * scale_mul, icon_size * scale_mul)
				draw_texture_rect_region(stars_tex, d_rect, src)
