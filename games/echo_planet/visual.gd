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
const BUBBLE_CYAN := Color("eefaff")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var cycle_beat := fposmod(maxf(0.0, beat), 8.0)
	var is_response_turn := (not counting) and (cycle_beat >= 3.85 and cycle_beat < 8.0) and beat < 48.0
	var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# Check if alien is actively singing a call note right now
	var singing_now := false
	if not counting and cycle_beat < 4.0:
		for c_item in chart.get("calls", []):
			var d := beat - float(c_item.get("beat", -99.0))
			if d >= -0.08 and d <= 0.38:
				singing_now = true
				break

	# 1. Background Layer: Deep Cosmic Violet Sky, Nebula & Twinkling 4-Point Stars (Panels 05 & 06)
	draw_rect(Rect2(0, 0, w, h), SKY_MID)
	draw_rect(Rect2(0, 0, w, h * 0.50), SKY_TOP)
	draw_rect(Rect2(0, h * 0.65, w, h * 0.35), SKY_LOW)
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.76, h * 0.56), w * 0.22, h * 0.14, -0.15, Color(0.55, 0.34, 0.82, 0.45), Color.TRANSPARENT, 0.0)
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.38, h * 0.66), w * 0.26, h * 0.12, 0.10, Color(0.62, 0.40, 0.88, 0.38), Color.TRANSPARENT, 0.0)

	var star_pts := [
		Vector2(0.08, 0.20), Vector2(0.06, 0.34), Vector2(0.11, 0.44),
		Vector2(0.92, 0.20), Vector2(0.94, 0.35), Vector2(0.89, 0.46),
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
	var alien_s := 1.02 if is_narrow else 1.34
	var alien_pose := "sing"
	var alien_face := 1
	if react_ratio > 0.0:
		if last_grade == "Miss":
			alien_pose = "idle"
			alien_face = 5
		else:
			alien_pose = "success"
			alien_face = 3
	elif is_response_turn:
		alien_pose = "listen"
		alien_face = 2
	elif counting:
		alien_pose = "idle"
		alien_face = 0
	elif singing_now:
		alien_pose = "sing"
		alien_face = 1
	else:
		alien_pose = "idle"
		alien_face = 0

	CartoonDraw.draw_echo_alien(self, alien_pos, alien_s, alien_pose, alien_face, false)

	# 4. Right Characters: The Two Astronaut Kids in White Spacesuits (Panels 05 & 06)
	var astro_pose := "cheer" if (react_ratio > 0.0 and last_grade != "Miss") else ("miss" if (react_ratio > 0.0 and last_grade == "Miss") else "listen")
	var astro_s := 0.84 if is_narrow else 1.06
	CartoonDraw.draw_echo_astronaut(self, Vector2(w * 0.72, h * 0.99 + bob * 0.5), astro_s, astro_pose)
	CartoonDraw.draw_echo_astronaut(self, Vector2(w * 0.89, h * 0.99 + bob * 0.4), astro_s * 0.96, astro_pose)

	# 5. Unified Dual Sender (Call) + Receiver (Echo Response) Lanes in the Sky!
	# Both Sender and Receiver marks stay simultaneously visible on screen without EVER flickering on click!
	_draw_dual_call_response_display(w, h, is_narrow, beat, counting, cycle_beat, is_response_turn, react_ratio)

	# 6. Hit Feedback Banner & Sparkle Stars in Mid-Sky (never hiding or replacing the bubbles!)
	if react_ratio > 0.0:
		if last_grade != "Miss":
			CartoonDraw.draw_star(self, Vector2(w * 0.11, h * 0.55), 20.0, 9.0, 5, -PI * 0.5, Color.WHITE, CartoonDraw.HOT_PINK, 4.0)
			CartoonDraw.draw_star(self, Vector2(w * 0.34, h * 0.53), 22.0, 10.0, 5, -PI * 0.5, Color.WHITE, CartoonDraw.GOLD, 4.0)
		paint_feedback(Vector2(w * 0.53, h * 0.58), true)

	# 7. Top Stage HUD Bar (Panels 05 & 06)
	var phrase_lit := 0 if counting else (int(floorf(fposmod(maxf(0.0, beat), 4.0))) + 1)
	var hud_col := CartoonDraw.HOT_PINK if is_response_turn else CartoonDraw.GOLD
	CartoonDraw.draw_stage_hud_banner(self, w, "Echo Planet", beat, score_value(), combo_value(), phrase_lit, hud_col)

func _draw_dual_call_response_display(
	w: float,
	h: float,
	is_narrow: bool,
	beat: float,
	counting: bool,
	cycle_beat: float,
	is_response_turn: bool,
	_react_ratio: float
) -> void:
	var cycle_start := floorf(maxf(0.0, beat) / 8.0) * 8.0
	if cycle_start >= 48.0:
		cycle_start = 40.0

	var bub_x := w * (0.08 if is_narrow else 0.15)
	var bub_w := w * (0.84 if is_narrow else 0.70)
	var row_h := h * 0.145
	var call_rect := Rect2(bub_x, h * 0.135, bub_w, row_h)
	var resp_rect := Rect2(bub_x, h * 0.310, bub_w, row_h)

	# Active turn border highlight so player immediately knows whether it's LISTEN or ECHO turn
	var call_bg := BUBBLE_PINK if not is_response_turn else Color(0.95, 0.90, 0.96, 0.88)
	var resp_bg := BUBBLE_CYAN if is_response_turn else Color(0.90, 0.95, 1.0, 0.88)

	# Top Bubble: Sender (Alien Call) with tail pointing down-left toward the Alien
	CartoonDraw.draw_speech_bubble(self, call_rect, Vector2(w * 0.23, h * 0.46), "", call_bg, CartoonDraw.INK, 18)
	# Bottom Bubble: Receiver (Your Echo) with tail pointing down-right toward the Astronauts
	CartoonDraw.draw_speech_bubble(self, resp_rect, Vector2(w * 0.77, h * 0.49), "", resp_bg, CartoonDraw.INK, 18)

	# Left role badges inside each bubble
	var label_w := 74.0 if is_narrow else 108.0
	var call_tag := Rect2(call_rect.position.x + 10.0, call_rect.position.y + 10.0, label_w, call_rect.size.y - 20.0)
	var resp_tag := Rect2(resp_rect.position.x + 10.0, resp_rect.position.y + 10.0, label_w, resp_rect.size.y - 20.0)
	var call_tag_col := CartoonDraw.GOLD if not is_response_turn else Color("d8cfe8")
	var resp_tag_col := CartoonDraw.HOT_PINK if is_response_turn else Color("c9d8eb")
	CartoonDraw.draw_outlined_box(self, call_tag, call_tag_col, CartoonDraw.INK, 3.0, 10.0)
	CartoonDraw.draw_outlined_box(self, resp_tag, resp_tag_col, CartoonDraw.INK, 3.0, 10.0)
	CartoonDraw.draw_outlined_text(self, Vector2(call_tag.position.x, call_tag.get_center().y + 6.0), "LISTEN", call_tag.size.x, 13 if is_narrow else 16, CartoonDraw.INK, Color.WHITE, 2)
	CartoonDraw.draw_outlined_text(self, Vector2(resp_tag.position.x, resp_tag.get_center().y + 6.0), "ECHO!", resp_tag.size.x, 14 if is_narrow else 17, Color.WHITE if is_response_turn else CartoonDraw.INK, CartoonDraw.INK if is_response_turn else Color.WHITE, 2)

	# Shared 4-beat timeline X-coordinate mapping (rel_b in 0.0 .. 3.0+)
	var track_left := call_rect.position.x + label_w + (34.0 if is_narrow else 56.0)
	var track_right := call_rect.end.x - (28.0 if is_narrow else 48.0)
	var track_span := maxf(80.0, track_right - track_left)
	var call_cy := call_rect.get_center().y + 2.0
	var resp_cy := resp_rect.get_center().y + 2.0

	# Draw 4 steady quarter-beat grid ticks + connecting vertical alignment lines across both bubbles
	for bi in range(4):
		var gx := track_left + (float(bi) / 3.2) * track_span
		draw_line(Vector2(gx, call_cy), Vector2(gx, resp_cy), Color(0.25, 0.20, 0.42, 0.16), 2.0, true)
		draw_circle(Vector2(gx, call_cy), 4.0, Color(0.20, 0.16, 0.35, 0.28))
		draw_circle(Vector2(gx, resp_cy), 4.0, Color(0.20, 0.16, 0.35, 0.28))

	# Sweeping Beat Playhead Cursor so player sees exact real-time rhythm position in both turns!
	if not counting and beat < 48.0:
		if cycle_beat < 4.0:
			var play_x := track_left + clampf(cycle_beat / 3.2, 0.0, 1.05) * track_span
			draw_line(Vector2(play_x, call_rect.position.y + 8.0), Vector2(play_x, call_rect.end.y - 8.0), Color(1.0, 0.78, 0.12, 0.65), 4.0, true)
		else:
			var resp_rel := cycle_beat - 4.0
			var play_x := track_left + clampf(resp_rel / 3.2, 0.0, 1.05) * track_span
			draw_line(Vector2(play_x, resp_rect.position.y + 8.0), Vector2(play_x, resp_rect.end.y - 8.0), Color(1.0, 0.30, 0.60, 0.75), 4.0, true)

	# 1) Draw Sender (Call) Musical Notes (♪) in Top Bubble from chart["calls"]
	var calls: Array = chart.get("calls", [])
	for ci in range(calls.size()):
		var cb := float(calls[ci].get("beat", -99.0))
		if cb < cycle_start - 0.05 or cb >= cycle_start + 4.0:
			continue
		var rel_b := cb - cycle_start
		var nx := track_left + (rel_b / 3.2) * track_span
		var is_active_note := (not counting) and absf(beat - cb) <= 0.26
		var is_sung := counting or (beat >= cb - 0.06)
		var n_scale := (1.42 if is_active_note else 1.15) * (0.80 if is_narrow else 1.0)
		if is_active_note:
			draw_arc(Vector2(nx, call_cy), 22.0, 0.0, TAU, 24, CartoonDraw.GOLD, 3.5, true)
		var n_col := CartoonDraw.GOLD if is_active_note else (CartoonDraw.MINT if (ci == 0 and is_sung) else (CartoonDraw.INK if is_sung else Color(0.35, 0.30, 0.50, 0.42)))
		CartoonDraw.draw_music_note(self, Vector2(nx, call_cy - (5.0 if is_active_note else 0.0)), n_scale, n_col, CartoonDraw.INK)

	# 2) Draw Receiver (Player Response) Star Marks (☆ -> ★) in Bottom Bubble from chart["events"]
	var events: Array = chart.get("events", [])
	for ei in range(events.size()):
		var eb := float(events[ei].get("beat", -99.0))
		if eb < cycle_start + 3.95 or eb >= cycle_start + 8.0:
			continue
		var rel_b := eb - (cycle_start + 4.0)
		var ex := track_left + (rel_b / 3.2) * track_span
		var ev_g := event_grade(ei)
		var diff := eb - beat
		var is_hit := (ev_g == "Perfect" or ev_g == "Good")
		var is_missed := (ev_g == "Miss") or ((not counting) and diff < -0.22 and not is_hit)

		# Shrinking timing ring as the beat cursor approaches this star slot!
		if not counting and not is_hit and not is_missed and diff >= -0.10 and diff <= 0.85:
			var ring_t := clampf(diff / 0.85, 0.0, 1.0)
			var ring_r := 16.0 + ring_t * (18.0 if is_narrow else 24.0)
			draw_arc(Vector2(ex, resp_cy), ring_r, 0.0, TAU, 24, Color(1.0, 0.78, 0.12, 0.85 - ring_t * 0.55), 3.2, true)

		var star_r := (16.0 if is_narrow else 21.0) * (1.22 if (is_hit and absf(diff) < 0.30) else 1.0)
		if is_hit:
			var border_c := CartoonDraw.HOT_PINK if ev_g == "Perfect" else CartoonDraw.SKY_BLUE
			var fill_c := CartoonDraw.GOLD if ev_g == "Perfect" else Color.WHITE
			CartoonDraw.draw_star(self, Vector2(ex, resp_cy), star_r, star_r * 0.45, 5, -PI * 0.5, fill_c, border_c, 4.0)
			CartoonDraw.draw_star(self, Vector2(ex, resp_cy), star_r * 0.72, star_r * 0.32, 5, -PI * 0.5, Color.WHITE, CartoonDraw.INK, 2.5)
		elif is_missed:
			CartoonDraw.draw_outlined_circle(self, Vector2(ex, resp_cy), star_r * 0.68, Color("ffd6de"), CartoonDraw.CORAL, 3.0)
			var cr := star_r * 0.35
			draw_line(Vector2(ex - cr, resp_cy - cr), Vector2(ex + cr, resp_cy + cr), CartoonDraw.CORAL, 3.5, true)
			draw_line(Vector2(ex + cr, resp_cy - cr), Vector2(ex - cr, resp_cy + cr), CartoonDraw.CORAL, 3.5, true)
		else:
			# Pending target star slot aligned directly underneath the corresponding Call note!
			var slot_fill := Color("fff6cc") if (not counting and absf(diff) <= 0.20) else Color("dce8f7")
			CartoonDraw.draw_star(self, Vector2(ex, resp_cy), star_r * 0.78, star_r * 0.36, 5, -PI * 0.5, slot_fill, CartoonDraw.INK, 3.0)
