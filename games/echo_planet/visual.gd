extends RhythmVisual

const SKY_TOP := Color("2d1e6b")
const SKY_MID := Color("4f2f96")
const SKY_LOW := Color("7648c2")
const MESA_BACK := Color("7244b5")
const MESA_FRONT := Color("9c6ad6")
const PODIUM_TOP := Color("c8bee8")
const PODIUM_SIDE := Color("8476b5")
const PLANET_BLUE := Color("58b8ed")
const PLANET_LIGHT := Color("9be6ff")
const BUBBLE_PINK := Color("fdebf8")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var cycle_beat := fposmod(maxf(0.0, beat), 8.0)
	var is_response_turn := (not counting) and (cycle_beat >= 3.65 and cycle_beat < 8.0) and beat < 48.0
	var react_ratio := clampf(reaction_timer / 0.48, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# Check if alien is actively singing a call note
	var singing_now := false
	if not counting and not is_response_turn:
		for c_item in chart.get("calls", []):
			var d := beat - float(c_item.get("beat", -99.0))
			if d >= -0.08 and d <= 0.48:
				singing_now = true
				break

	# 1. Background Layer: Deep Cosmic Violet Sky, Nebula & Twinkling 4-Point Stars (Panels 05 & 06)
	draw_rect(Rect2(0, 0, w, h), SKY_MID)
	draw_rect(Rect2(0, 0, w, h * 0.50), SKY_TOP)
	draw_rect(Rect2(0, h * 0.65, w, h * 0.35), SKY_LOW)
	# Soft nebula clouds
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.76, h * 0.56), w * 0.22, h * 0.14, -0.15, Color(0.55, 0.34, 0.82, 0.45), Color.TRANSPARENT, 0.0)
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.38, h * 0.66), w * 0.26, h * 0.12, 0.10, Color(0.62, 0.40, 0.88, 0.38), Color.TRANSPARENT, 0.0)

	# 4-point twinkling yellow/white stars across space
	var star_pts := [
		Vector2(0.11, 0.23), Vector2(0.08, 0.32), Vector2(0.16, 0.29),
		Vector2(0.07, 0.45), Vector2(0.67, 0.46), Vector2(0.86, 0.24),
		Vector2(0.94, 0.30), Vector2(0.88, 0.41), Vector2(0.57, 0.43),
	]
	for si in range(star_pts.size()):
		var sp: Vector2 = star_pts[si]
		var sr := 8.0 if (si % 2 == 0) else 5.5
		if not reduced_motion and not counting:
			sr += sin(beat * 2.0 + float(si)) * 1.8
		CartoonDraw.draw_star(self, Vector2(sp.x * w, sp.y * h), sr, sr * 0.35, 4, 0.0, CartoonDraw.GOLD, Color.TRANSPARENT, 0.0)

	# 2. Midground Layer: Giant Icy-Blue Planet on Right + Purple Canyon Mesas (Panels 05 & 06)
	var planet_c := Vector2(w * 0.90, h * 0.70)
	var planet_r := minf(w, h) * 0.25
	CartoonDraw.draw_outlined_circle(self, planet_c, planet_r, PLANET_BLUE, Color("3c6fb0"), 3.5)
	CartoonDraw.draw_outlined_ellipse(self, planet_c + Vector2(-planet_r * 0.22, -planet_r * 0.26), planet_r * 0.55, planet_r * 0.28, -0.35, PLANET_LIGHT, Color.TRANSPARENT, 0.0)
	CartoonDraw.draw_star(self, planet_c + Vector2(planet_r * 0.18, -planet_r * 0.10), 10.0, 4.0, 4, 0.0, Color.WHITE, Color.TRANSPARENT, 0.0)

	# Purple rocky canyon mesas along bottom horizon
	var mesa_pts := PackedVector2Array([
		Vector2(w * 0.40, h),
		Vector2(w * 0.45, h * 0.78),
		Vector2(w * 0.64, h * 0.78),
		Vector2(w * 0.70, h),
	])
	CartoonDraw.draw_outlined_polygon(self, mesa_pts, MESA_FRONT, CartoonDraw.INK, 4.0)

	# Left Foreground Alien Stage Podium (Panels 05 & 06)
	var pod_rect := Rect2(-12.0, h * 0.89, w * 0.55, h * 0.14)
	CartoonDraw.draw_outlined_box(self, pod_rect, PODIUM_SIDE, CartoonDraw.INK, 4.2, 10.0)
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.25, h * 0.89), w * 0.28, 16.0, 0.0, PODIUM_TOP, CartoonDraw.INK, 4.0)

	# 3. Left Character: Sky-Cyan Alien (Panels 05, 06, 11)
	var alien_pos := Vector2(w * 0.21, h * 0.98 + bob * 0.4)
	var alien_s := 1.05 if is_narrow else 1.38
	var alien_pose := "sing"
	var alien_face := 1
	if react_ratio > 0.0:
		if last_grade == "Miss":
			alien_pose = "idle"
			alien_face = 5 # Surprised 'o' mouth from Panel 11!
		else:
			alien_pose = "success"
			alien_face = 3 # Joyful arched eyes + open mouth + raised arms from Panel 06 & 11!
	elif is_response_turn:
		alien_pose = "listen"
		alien_face = 2 # Peaceful closed eyes listening from Panel 11!
	elif counting:
		alien_pose = "idle"
		alien_face = 0
	else:
		alien_pose = "sing"
		alien_face = 1 # Singing with 3 golden soundwave arcs from Panel 05 & 11!

	CartoonDraw.draw_echo_alien(self, alien_pos, alien_s, alien_pose, alien_face, false)

	# 4. Right Characters: The Two Astronaut Kids in White Spacesuits (Panels 05 & 06)
	var astro_pose := "cheer" if (is_response_turn and react_ratio > 0.0 and last_grade != "Miss") else ("miss" if (react_ratio > 0.0 and last_grade == "Miss") else "listen")
	var astro_s := 0.84 if is_narrow else 1.08
	CartoonDraw.draw_echo_astronaut(self, Vector2(w * 0.72, h * 0.99 + bob * 0.5), astro_s, astro_pose)
	CartoonDraw.draw_echo_astronaut(self, Vector2(w * 0.89, h * 0.99 + bob * 0.4), astro_s * 0.96, astro_pose)

	# 5. Upper Sky Presentation:
	# - In Listen (Call) (Panel 05): Big Rounded Pale-Pink Speech Bubble with 4 Eighth-Notes (♪ ♪ ♪ ♪)!
	# - In Response / Success (Panel 06): 3 Glowing Stars above the Alien + Yellow "PERFECT!" Banner + Beat Guide!
	var cycle_start := floorf(maxf(0.0, beat) / 8.0) * 8.0
	if cycle_start >= 48.0:
		cycle_start = 40.0

	if is_response_turn and react_ratio > 0.0 and last_grade != "Miss":
		# Panel 06: 3 glowing 5-point stars above the Alien + Yellow PERFECT! banner on right!
		var star_positions := [
			Vector2(w * 0.14, h * 0.28),
			Vector2(w * 0.31, h * 0.26),
			Vector2(w * 0.43, h * 0.24),
		]
		var star_borders := [CartoonDraw.HOT_PINK, CartoonDraw.GOLD, CartoonDraw.GOLD]
		for si in range(3):
			CartoonDraw.draw_star(self, star_positions[si], 26.0, 12.0, 5, -PI * 0.5, Color.WHITE, star_borders[si], 4.5)
		paint_feedback(Vector2(w * (0.68 if is_narrow else 0.72), h * 0.30), true)
	elif not is_response_turn:
		# Panel 05: Large Pale-Pink Speech Bubble with 4 Musical Eighth-Notes (♪ ♪ ♪ ♪)
		var bub_w := w * (0.68 if is_narrow else 0.58)
		var bub_h := h * 0.22
		var bub_rect := Rect2(w * (0.18 if is_narrow else 0.21), h * 0.18, bub_w, bub_h)
		CartoonDraw.draw_speech_bubble(self, bub_rect, Vector2(w * 0.33, h * 0.46), "", BUBBLE_PINK, CartoonDraw.INK, 20)

		# Draw the 4 eighth-notes inside the speech bubble, lighting up / bouncing on each call beat!
		for ni in range(4):
			var nx := bub_rect.position.x + bub_rect.size.x * (0.18 + float(ni) * 0.21)
			var ny := bub_rect.get_center().y + 4.0
			var target_cb := cycle_start + float(ni)
			var is_active_note := (not counting) and absf(beat - target_cb) <= 0.32
			var is_sung := (not counting) and beat >= target_cb - 0.05
			var n_scale := (1.55 if is_active_note else 1.25) * (0.82 if is_narrow else 1.0)
			var n_col := CartoonDraw.GOLD if is_active_note else (CartoonDraw.INK if is_sung else Color("3b3554"))
			CartoonDraw.draw_music_note(self, Vector2(nx, ny - (6.0 if is_active_note else 0.0)), n_scale, n_col, CartoonDraw.INK)
	else:
		# During Response Turn before/between hits: show the 4-beat Echo Bubble above the Astronauts so player sees exact beat timing!
		var bub_w := w * (0.68 if is_narrow else 0.58)
		var bub_h := h * 0.20
		var bub_rect := Rect2(w * (0.20 if is_narrow else 0.24), h * 0.18, bub_w, bub_h)
		CartoonDraw.draw_speech_bubble(self, bub_rect, Vector2(w * 0.74, h * 0.48), "", Color("eefaff"), CartoonDraw.INK, 20)
		var resp_rel := cycle_beat - 4.0
		for ni in range(4):
			var nx := bub_rect.position.x + bub_rect.size.x * (0.18 + float(ni) * 0.21)
			var ny := bub_rect.get_center().y + 4.0
			var is_now := absf(resp_rel - float(ni)) <= 0.28
			var is_done := resp_rel > float(ni) + 0.20
			if is_now:
				draw_arc(Vector2(nx, ny), 24.0, 0.0, TAU, 20, CartoonDraw.GOLD, 3.5, true)
			var n_col := CartoonDraw.GOLD if is_now else (CartoonDraw.MINT if is_done else CartoonDraw.INK)
			CartoonDraw.draw_music_note(self, Vector2(nx, ny), 1.35 if is_now else 1.15, n_col, CartoonDraw.INK)
		if react_ratio > 0.0:
			paint_feedback(Vector2(w * 0.72, h * 0.30), true)

	# 6. Top Stage HUD Bar (Panels 05 & 06)
	var phrase_lit := 2 if counting else clampi(int(floorf(fposmod(maxf(0.0, beat), 4.0))) + 1, 1, 4)
	if react_ratio > 0.0 and last_grade == "Perfect":
		phrase_lit = 3
	CartoonDraw.draw_stage_hud_banner(self, w, "Echo Planet", beat, score_value(), combo_value(), phrase_lit, CartoonDraw.GOLD)
