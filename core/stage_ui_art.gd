extends Control
class_name StageUIArt

var mode := "home_banner"
var game_id := "beat_factory"
var grade_tier := "SUPERB"
var t_anim := 0.0
var rehearsal_flash := 0.0
var rehearsal_grade := "Perfect"
var reduced_motion := false
var card_selected := false
var summary_data: Dictionary = {}

func setup(p_mode: String, p_game_id: String = "beat_factory", p_tier: String = "SUPERB", p_reduced: bool = false) -> StageUIArt:
	mode = p_mode
	game_id = p_game_id
	grade_tier = p_tier
	reduced_motion = p_reduced
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	return self

func trigger_rehearsal_hit(grade_str: String = "Perfect") -> void:
	rehearsal_grade = grade_str
	rehearsal_flash = 0.45
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion:
		t_anim += delta
	if rehearsal_flash > 0.0:
		rehearsal_flash = maxf(0.0, rehearsal_flash - delta)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 4.0 or h <= 4.0:
		return
	var beat := t_anim * 1.85
	var bob := 0.0 if reduced_motion else absf(sin(beat * PI)) * 5.0

	match mode:
		"home_banner":
			_draw_title_screen_art(w, h, beat, bob)
		"select_header":
			_draw_select_header_banner(w, h)
		"poster_card":
			_draw_poster_card(w, h, bob)
		"rehearsal_stage":
			_draw_rehearsal_stage(w, h, bob)
		"eval_screen":
			_draw_eval_screen(w, h, bob)
		"result_vignette":
			_draw_results_award_art(w, h, beat, bob)
		"char_sheet":
			_draw_character_sheet(w, h)

# =============================================================================
# PANEL 01: TITLE SCREEN ART (01_title.png)
# =============================================================================
func _draw_title_screen_art(w: float, h: float, beat: float, bob: float) -> void:
	var is_narrow := w < 520.0
	# 1. Warm Golden-Yellow Sunburst Background (#FFE156 / #FFD034)
	draw_rect(Rect2(0, 0, w, h), Color("ffe359"))
	var center := Vector2(w * 0.50, h * 0.36)
	var max_r := maxf(w, h) * 1.25
	for i in range(18):
		if i % 2 == 0:
			var a0 := float(i) * TAU / 18.0 + (0.0 if reduced_motion else t_anim * 0.08)
			var a1 := float(i + 1) * TAU / 18.0 + (0.0 if reduced_motion else t_anim * 0.08)
			draw_colored_polygon(PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * max_r, center + Vector2(cos(a1), sin(a1)) * max_r]), Color("ffd034"))

	# 2. Scalloped Black Cloud Logo with Thick White Sticker Border (Panel 01!)
	var cloud_c := Vector2(w * 0.50, h * 0.31)
	var cs := 0.72 if is_narrow else 1.0
	var lobes := [
		Vector2(-155.0, 12.0), Vector2(-115.0, -45.0), Vector2(-38.0, -68.0),
		Vector2(45.0, -82.0), Vector2(125.0, -42.0), Vector2(162.0, 14.0),
		Vector2(115.0, 62.0), Vector2(0.0, 72.0), Vector2(-115.0, 62.0),
	]
	var lobe_r := [56.0, 62.0, 68.0, 74.0, 62.0, 56.0, 56.0, 64.0, 56.0]
	# White outer sticker halo
	for li in range(lobes.size()):
		draw_circle(cloud_c + lobes[li] * cs, (lobe_r[li] + 10.0) * cs, Color.WHITE)
	draw_circle(cloud_c, 108.0 * cs, Color.WHITE)
	# Dark navy-black cloud interior
	for li in range(lobes.size()):
		draw_circle(cloud_c + lobes[li] * cs, lobe_r[li] * cs, Color("151423"))
	draw_circle(cloud_c, 98.0 * cs, Color("151423"))

	# "RHYTHM" (white) + "RHYTHM" (hot-pink) inside the cloud!
	var fs_main := int(round(52.0 * cs))
	CartoonDraw.draw_outlined_text(self, cloud_c + Vector2(-210.0 * cs, -14.0 * cs), "RHYTHM", int(420.0 * cs), fs_main, Color.WHITE, Color("151423"), 4.0)
	CartoonDraw.draw_outlined_text(self, cloud_c + Vector2(-210.0 * cs, 44.0 * cs), "RHYTHM", int(420.0 * cs), fs_main, Color("ff5588"), Color("151423"), 4.0)

	# Purple Pill Sub-Banner: "★ GROOVE SHOW ★" (Panel 01!)
	var pill_w := 320.0 * cs
	var pill_h := 48.0 * cs
	var pill_rect := Rect2(cloud_c.x - pill_w * 0.5, cloud_c.y + 62.0 * cs, pill_w, pill_h)
	CartoonDraw.draw_outlined_box(self, pill_rect.grow(5.0 * cs), Color.WHITE, Color.WHITE, 0.0, 26.0 * cs)
	CartoonDraw.draw_outlined_box(self, pill_rect, Color("8e44ec"), CartoonDraw.INK, 4.2 * cs, 22.0 * cs)
	CartoonDraw.draw_outlined_text(self, pill_rect.position + Vector2(0, pill_h * 0.70), "★ GROOVE SHOW ★", int(pill_w), int(round(24.0 * cs)), Color.WHITE, Color("4a1c8c"), 2.5)

	# Floating Colorful Musical Notes (Pink left, Sky-Blue top-right, Purple mid-right)
	CartoonDraw.draw_music_note(self, Vector2(w * 0.11, h * 0.25 - bob * 0.5), 1.35 * cs, Color("ff5d9e"), CartoonDraw.INK)
	CartoonDraw.draw_music_note(self, Vector2(w * 0.89, h * 0.17 + bob * 0.5), 1.45 * cs, Color("38b6ff"), CartoonDraw.INK)
	CartoonDraw.draw_music_note(self, Vector2(w * 0.88, h * 0.53 - bob * 0.4), 1.35 * cs, Color("c84bff"), CartoonDraw.INK)

	# 3. Dark Crowd Silhouettes Along the Bottom + The 4 Cast Characters (Panel 01!)
	var char_s := 0.78 if is_narrow else 1.05
	# Crowd heads in back
	for ci in range(11):
		var cx := w * (0.24 + float(ci) * 0.072)
		draw_circle(Vector2(cx, h * 0.94), 26.0 * char_s, Color("19172b"))

	# (1) Left: Pink Top-Hat & Tuxedo Show Host
	CartoonDraw.draw_title_host(self, Vector2(w * 0.19, h * 0.96), char_s * 1.12, -bob * 0.5)
	# (2) Center-Left: Orange Square TV/Robot Buddy
	CartoonDraw.draw_orange_tv_buddy(self, Vector2(w * 0.49, h * 0.83 - bob * 0.4), char_s * 1.02)
	# (3) Center-Right: Echo Planet Sky-Cyan Alien
	CartoonDraw.draw_echo_alien(self, Vector2(w * 0.68, h * 0.99 - bob * 0.5), char_s * 0.92, "idle", 0, false)
	# (4) Far Right: Rhythm Kitchen Chef
	CartoonDraw.draw_kitchen_chef(self, Vector2(w * 0.84, h * 0.97 - bob * 0.4), char_s * 0.95, "idle", 0, false)

	# Foreground crowd silhouette heads along bottom border
	for fi in range(12):
		var fx := w * (0.04 + float(fi) * 0.088)
		var fy := h * (0.97 if (fi >= 3 and fi <= 8) else 0.94)
		draw_circle(Vector2(fx, fy), 24.0 * char_s, Color("161529"))

# =============================================================================
# PANEL 02: STAGE SELECT HEADER & PORTRAIT CARDS (02_stage_select.png)
# =============================================================================
func _draw_select_header_banner(w: float, h: float) -> void:
	var is_narrow := w < 520.0
	var bw := minf(w * 0.88, 680.0)
	var bh := minf(h * 0.88, 74.0)
	var rect := Rect2((w - bw) * 0.5, (h - bh) * 0.5, bw, bh)
	CartoonDraw.draw_outlined_box(self, rect, Color("f9ebc8"), CartoonDraw.INK, 4.5, 22.0)
	var fs := 24 if is_narrow else 36
	CartoonDraw.draw_outlined_text(self, Vector2(rect.position.x, rect.get_center().y + float(fs) * 0.36), "CHOOSE A GAME!", int(bw), fs, CartoonDraw.INK, Color.WHITE, 2.0)

func _draw_poster_card(w: float, h: float, bob: float) -> void:
	var is_narrow := w < 180.0 or h < 140.0
	var pad := 6.0
	var outer_rect := Rect2(pad, pad, w - pad * 2.0, h - pad * 2.0)

	# Focused/Selected card gets the bright red outer highlight frame + white inner border (Panel 02 Card 1!)
	if card_selected:
		CartoonDraw.draw_outlined_box(self, outer_rect.grow(3.0), Color.WHITE, Color("e63946"), 5.0, 24.0)

	var bg_col := Color("ffb347")
	var line1 := "Beat"
	var line2 := "Factory"
	if game_id == "echo_planet":
		bg_col = Color("c594ff")
		line1 = "Echo"
		line2 = "Planet"
	elif game_id == "rhythm_kitchen":
		bg_col = Color("6ae3c4")
		line1 = "Rhythm"
		line2 = "Kitchen"

	CartoonDraw.draw_outlined_box(self, outer_rect, bg_col, CartoonDraw.INK, 4.2, 20.0)

	var title_fs := 20 if is_narrow else 32
	if not is_narrow:
		CartoonDraw.draw_sticker_text(self, Vector2(outer_rect.position.x + 8.0, outer_rect.position.y + 44.0), line1, int(outer_rect.size.x - 16.0), title_fs, CartoonDraw.INK, Color.WHITE, Color.WHITE, 4.0, 6.0)
		CartoonDraw.draw_sticker_text(self, Vector2(outer_rect.position.x + 8.0, outer_rect.position.y + 82.0), line2, int(outer_rect.size.x - 16.0), title_fs, CartoonDraw.INK, Color.WHITE, Color.WHITE, 4.0, 6.0)

	# Character & Prop Illustration inside each Card (Panel 02!)
	var s := minf(w / 240.0, h / 320.0)
	if is_narrow:
		s = minf(w / 280.0, h / 110.0)
	if game_id == "beat_factory":
		# Floating 3D isometric cube box on upper-right of card + Worker with red-knob lever on bottom-left!
		var box_c := Vector2(w * 0.68, h * 0.56)
		CartoonDraw.draw_outlined_box(self, Rect2(box_c.x - 28.0 * s, box_c.y - 22.0 * s, 56.0 * s, 44.0 * s), Color("f5b968"), CartoonDraw.INK, 3.8 * s, 4.0)
		draw_circle(box_c + Vector2(-10.0 * s, 2.0 * s), 3.0 * s, CartoonDraw.INK)
		draw_circle(box_c + Vector2(10.0 * s, 2.0 * s), 3.0 * s, CartoonDraw.INK)
		CartoonDraw.draw_factory_worker(self, Vector2(w * 0.38, h - 10.0 + bob * 0.3), 1.05 * s, "ready", 0, true)
	elif game_id == "echo_planet":
		# Dark indigo starry cosmic blob + Sky-Cyan Alien with glowing yellow antenna!
		var space_c := Vector2(w * 0.50, h * 0.70)
		CartoonDraw.draw_outlined_ellipse(self, space_c, w * 0.40, h * 0.24, -0.1, Color("2e2466"), Color("4a3b8c"), 3.0)
		CartoonDraw.draw_star(self, space_c + Vector2(-46.0 * s, -28.0 * s), 11.0 * s, 4.5 * s, 4, 0.0, CartoonDraw.GOLD, Color.TRANSPARENT, 0.0)
		CartoonDraw.draw_star(self, space_c + Vector2(-12.0 * s, -48.0 * s), 9.0 * s, 3.8 * s, 4, 0.0, CartoonDraw.GOLD, Color.TRANSPARENT, 0.0)
		CartoonDraw.draw_echo_alien(self, Vector2(w * 0.54, h + 12.0 + bob * 0.3), 1.12 * s, "idle", 0, false)
	else:
		# Rhythm Kitchen Chef holding dark skillet on left & raising hand!
		var chef_base := Vector2(w * 0.54, h - 8.0 + bob * 0.3)
		CartoonDraw.draw_kitchen_chef(self, chef_base, 1.05 * s, "left", 0, false)
		CartoonDraw.draw_outlined_ellipse(self, Vector2(w * 0.24, h * 0.78), 32.0 * s, 14.0 * s, 0.2, Color("5c586b"), CartoonDraw.INK, 3.8 * s)

# =============================================================================
# REHEARSAL STAGE & CHARACTER SHEET PREVIEW (Panels 10, 11, 12)
# =============================================================================
func _draw_rehearsal_stage(w: float, h: float, _bob: float) -> void:
	_draw_character_sheet(w, h)
	if rehearsal_flash > 0.0:
		var badge_c := Vector2(w * 0.80, h * 0.24)
		CartoonDraw.draw_jagged_burst_box(self, badge_c, 96.0, 42.0, 12, CartoonDraw.PAPER, CartoonDraw.GOLD, CartoonDraw.INK, 4.0)
		CartoonDraw.draw_sticker_text(self, badge_c + Vector2(-95.0, 12.0), "PERFECT!", 190, 28, CartoonDraw.HOT_PINK, CartoonDraw.INK, Color.WHITE, 3.5, 6.0)

func _draw_character_sheet(w: float, h: float) -> void:
	# Renders the exact 4 Action Poses + 6 Face Expressions sheet from Panels 10, 11, 12!
	var card_rect := Rect2(4.0, 4.0, w - 8.0, h - 8.0)
	CartoonDraw.draw_outlined_box(self, card_rect, Color("fdf5df"), CartoonDraw.INK, 4.2, 16.0)
	var div_y := h * 0.64
	draw_line(Vector2(24.0, div_y), Vector2(w - 24.0, div_y), Color("e3cfa6"), 2.5)

	var is_narrow := w < 520.0
	var s := (0.48 if is_narrow else 0.70) * minf(w / 680.0, h / 360.0) * 1.25
	var pose_y := div_y - (44.0 if is_narrow else 62.0)
	var labels := ["Idle", "Ready", "Hit", "Cheer"]
	if game_id == "echo_planet":
		labels = ["Idle", "Sing (Call)", "Listen", "Success"]
	elif game_id == "rhythm_kitchen":
		labels = ["Idle", "Left (A)", "Right (L)", "Cheer"]

	for pi in range(4):
		var px := w * (0.14 + float(pi) * 0.24)
		if game_id == "beat_factory":
			var p_names := ["idle", "ready", "hit", "cheer"]
			var f_indices := [0, 0, 4, 4]
			CartoonDraw.draw_factory_worker(self, Vector2(px, pose_y), s, p_names[pi], f_indices[pi], pi == 1 or pi == 2)
		elif game_id == "echo_planet":
			var p_names := ["idle", "sing", "listen", "success"]
			var f_indices := [0, 1, 2, 2]
			CartoonDraw.draw_echo_alien(self, Vector2(px, pose_y), s, p_names[pi], f_indices[pi], true)
		else:
			var p_names := ["idle", "left", "right", "cheer"]
			var f_indices := [0, 1, 1, 1]
			CartoonDraw.draw_kitchen_chef(self, Vector2(px, pose_y), s, p_names[pi], f_indices[pi], true)
			if pi == 1:
				CartoonDraw.draw_outlined_ellipse(self, Vector2(px + 38.0 * s, pose_y - 24.0 * s), 26.0 * s, 12.0 * s, -0.1, Color("5a5668"), CartoonDraw.INK, 3.2 * s)
				CartoonDraw.draw_outlined_circle(self, Vector2(px + 42.0 * s, pose_y - 38.0 * s), 15.0 * s, Color("78d639"), CartoonDraw.INK, 3.0 * s)
			elif pi == 2:
				CartoonDraw.draw_outlined_ellipse(self, Vector2(px + 18.0 * s, pose_y - 22.0 * s), 26.0 * s, 12.0 * s, 0.1, Color("5a5668"), CartoonDraw.INK, 3.2 * s)
				CartoonDraw.draw_outlined_circle(self, Vector2(px + 44.0 * s, pose_y - 34.0 * s), 11.0 * s, Color("f23838"), CartoonDraw.INK, 3.0 * s)

		CartoonDraw.draw_outlined_text(self, Vector2(px - 70.0, div_y - 8.0), labels[pi], 140, 14 if is_narrow else 18, CartoonDraw.INK, Color.WHITE, 0.0)

	# Bottom Section: "Face Expressions" + 6 Expression Heads (Panels 10, 11, 12!)
	CartoonDraw.draw_outlined_text(self, Vector2(28.0, div_y + 24.0), "Face Expressions", 240, 14 if is_narrow else 18, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	var face_y := div_y + (h - div_y) * 0.62
	var fs_head := s * 0.85
	for fi in range(6):
		var fx := w * (0.13 + float(fi) * 0.148)
		var fc := Vector2(fx, face_y)
		if game_id == "beat_factory":
			CartoonDraw.draw_outlined_circle(self, fc, 30.0 * fs_head, CartoonDraw.SKIN, CartoonDraw.INK, 3.8 * fs_head)
			CartoonDraw._draw_worker_face(self, fc + Vector2(0, 2.0 * fs_head), fs_head * 0.9, fi)
		elif game_id == "echo_planet":
			var ant_col := CartoonDraw.GOLD if fi == 5 else Color("5ce1e6")
			draw_line(fc + Vector2(0, -24.0 * fs_head), fc + Vector2(0, -38.0 * fs_head), CartoonDraw.INK, 3.5 * fs_head)
			CartoonDraw.draw_outlined_circle(self, fc + Vector2(0, -40.0 * fs_head), 7.5 * fs_head, ant_col, CartoonDraw.INK, 3.0 * fs_head)
			CartoonDraw.draw_outlined_ellipse(self, fc, 32.0 * fs_head, 26.0 * fs_head, 0.0, Color("82cfe6"), CartoonDraw.INK, 3.8 * fs_head)
			CartoonDraw.draw_eyes(self, fc + Vector2(0, -2.0 * fs_head), 16.0 * fs_head, 4.0 * fs_head, "squint" if fi == 3 else ("normal" if fi == 4 else "wide"))
			CartoonDraw.draw_mouth(self, fc + Vector2(0, 8.0 * fs_head), 12.0 * fs_head, 9.0 * fs_head, "open_o" if fi == 4 else ("open_d" if (fi == 2 or fi == 3) else "smile"))
		else:
			CartoonDraw.draw_outlined_circle(self, fc, 28.0 * fs_head, CartoonDraw.SKIN, CartoonDraw.INK, 3.8 * fs_head)
			CartoonDraw.draw_outlined_box(self, Rect2(fc.x - 22.0 * fs_head, fc.y - 34.0 * fs_head, 44.0 * fs_head, 16.0 * fs_head), Color.WHITE, CartoonDraw.INK, 3.2 * fs_head, 6.0)
			var e_st := "happy" if fi == 1 else ("surprised" if fi == 2 else ("squint" if (fi == 3 or fi == 4) else "normal"))
			var m_st := "open_o" if fi == 2 else ("open_d" if fi >= 3 else "smile")
			CartoonDraw.draw_eyes(self, fc + Vector2(0, -1.0 * fs_head), 15.0 * fs_head, 3.8 * fs_head, e_st)
			CartoonDraw.draw_mouth(self, fc + Vector2(0, 8.0 * fs_head), 13.0 * fs_head, 9.0 * fs_head, m_st)
			if fi >= 4:
				CartoonDraw.draw_sweat_drop(self, fc + Vector2(20.0 * fs_head, -18.0 * fs_head), 0.75 * fs_head)

# =============================================================================
# POST-STAGE EVALUATION REVEAL ("검정화면 > 평가 > 시상")
# =============================================================================
func _draw_eval_screen(w: float, h: float, bob: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("0d0b14"))
	# Spotlight cone in center
	var spot_pts := PackedVector2Array([
		Vector2(w * 0.50, -20.0),
		Vector2(w * 0.18, h),
		Vector2(w * 0.82, h),
	])
	draw_colored_polygon(spot_pts, Color(1.0, 0.92, 0.55, 0.12))
	var s := 0.85 if w < 520.0 else 1.15
	var cpos := Vector2(w * 0.50, h * 0.66 + bob * 0.3)
	if game_id == "beat_factory":
		CartoonDraw.draw_factory_worker(self, cpos, s, "cheer" if grade_tier == "SUPERB" else "idle", 4 if grade_tier == "SUPERB" else 0, false)
	elif game_id == "echo_planet":
		CartoonDraw.draw_echo_alien(self, cpos, s, "success" if grade_tier == "SUPERB" else "idle", 3 if grade_tier == "SUPERB" else 0, true)
	else:
		CartoonDraw.draw_kitchen_chef(self, cpos, s, "cheer" if grade_tier == "SUPERB" else "idle", 3 if grade_tier == "SUPERB" else 0, true)

# =============================================================================
# PANEL 09: RESULTS / AWARD SCREEN (09_results_superb.png)
# =============================================================================
func _draw_results_award_art(w: float, h: float, _beat: float, bob: float) -> void:
	var is_narrow := w < 520.0
	# 1. Festive Pink & Gold Radial Stage Spotlight Background (Panel 09!)
	var bg_base := Color("ffa3bf") if grade_tier == "SUPERB" else (Color("9be0d4") if grade_tier == "OK" else Color("b0b5cf"))
	draw_rect(Rect2(0, 0, w, h), bg_base)
	# Corner yellow spotlight beams
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.28, 0), Vector2(w * 0.42, h * 0.45), Vector2(0, h * 0.30)]), Color(1.0, 0.90, 0.32, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w * 0.72, 0), Vector2(w * 0.58, h * 0.45), Vector2(w, h * 0.30)]), Color(1.0, 0.90, 0.32, 0.55))
	# Soft golden floor glow under characters
	CartoonDraw.draw_outlined_ellipse(self, Vector2(w * (0.50 if is_narrow else 0.28), h * 0.88), w * (0.44 if is_narrow else 0.28), h * 0.16, 0.0, Color("ffe270"), Color.TRANSPARENT, 0.0)

	# 2. Top Center Giant Sticker Banner: "SUPERB!" / "OK!" / "TRY AGAIN!" (Panel 09!)
	var banner_txt := grade_tier + "!"
	var banner_col := CartoonDraw.GOLD if grade_tier == "SUPERB" else (CartoonDraw.MINT if grade_tier == "OK" else CartoonDraw.CORAL)
	var banner_fs := 40 if is_narrow else 64
	var banner_y := h * (0.14 if is_narrow else 0.20)
	# Draw 3D crimson drop-extrusion + white sticker border
	CartoonDraw.draw_sticker_text(self, Vector2(0, banner_y + 5.0), banner_txt, int(w), banner_fs, Color("d92658"), CartoonDraw.INK, Color.WHITE, 5.0, 10.0)
	CartoonDraw.draw_sticker_text(self, Vector2(0, banner_y), banner_txt, int(w), banner_fs, banner_col, CartoonDraw.INK, Color.WHITE, 4.5, 9.0)

	# 3. Left Half: The 3 Main Characters Cheering Together! (Panel 09!)
	var trio_cx := w * (0.50 if is_narrow else 0.28)
	var trio_y := h * (0.48 if is_narrow else 0.78)
	var ts := (0.62 if is_narrow else 0.96)
	var pose_w := "cheer" if grade_tier != "TRY AGAIN" else "idle"
	var face_w := 4 if grade_tier == "SUPERB" else (0 if grade_tier == "OK" else 5)
	var pose_a := "success" if grade_tier != "TRY AGAIN" else "idle"
	var face_a := 3 if grade_tier == "SUPERB" else (0 if grade_tier == "OK" else 5)
	var pose_c := "cheer" if grade_tier != "TRY AGAIN" else "idle"
	var face_c := 1 if grade_tier == "SUPERB" else (0 if grade_tier == "OK" else 5)

	# Center back: Blue Alien
	CartoonDraw.draw_echo_alien(self, Vector2(trio_cx, trio_y - 36.0 * ts - bob * 0.5), ts * 0.95, pose_a, face_a, true)
	# Left front: Factory Worker
	CartoonDraw.draw_factory_worker(self, Vector2(trio_cx - 92.0 * ts, trio_y + 18.0 * ts - bob * 0.4), ts * 0.95, pose_w, face_w, false)
	# Right front: Kitchen Chef
	CartoonDraw.draw_kitchen_chef(self, Vector2(trio_cx + 92.0 * ts, trio_y + 22.0 * ts - bob * 0.4), ts * 0.95, pose_c, face_c, false)

	# Black comic excitement lines above the cheering trio (Panel 09!)
	if grade_tier == "SUPERB":
		for li in range(3):
			var lx := trio_cx - 110.0 * ts + float(li) * 22.0 * ts
			draw_line(Vector2(lx, trio_y - 140.0 * ts), Vector2(lx - 10.0 * ts, trio_y - 170.0 * ts), CartoonDraw.INK, 4.5 * ts, true)
			var rx := trio_cx + 68.0 * ts + float(li) * 22.0 * ts
			draw_line(Vector2(rx, trio_y - 140.0 * ts), Vector2(rx + 10.0 * ts, trio_y - 170.0 * ts), CartoonDraw.INK, 4.5 * ts, true)

	# 4. Right Half: Cream Scoreboard Card (Panel 09!)
	var card_rect := Rect2(w * 0.54, h * 0.21, w * 0.42, h * 0.64)
	if is_narrow:
		card_rect = Rect2(w * 0.08, h * 0.52, w * 0.84, h * 0.37)
	CartoonDraw.draw_outlined_box(self, card_rect, Color("fff8e7"), Color("f0a868"), 4.0, 20.0)

	var st_title := str(summary_data.get("stage_name", "Rhythm Kitchen"))
	var sc_val := int(summary_data.get("score", 52400))
	var best_val := int(summary_data.get("best", 52400))
	var mc_val := int(summary_data.get("max_combo", 28))
	var counts: Dictionary = summary_data.get("counts", {"Perfect": 26, "Good": 3, "Miss": 1})

	var cx0 := card_rect.position.x + 18.0
	var cw := int(card_rect.size.x - 36.0)
	var row_h := card_rect.size.y / 7.2
	var ry := card_rect.position.y + row_h * 0.85
	var h_fs := 18 if is_narrow else 26
	var r_fs := 14 if is_narrow else 20

	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), st_title, cw, h_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(cx0, ry + 8.0), Vector2(cx0 + cw, ry + 8.0), Color("f2cfa0"), 2.0)

	# SCORE
	ry += row_h
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "SCORE", cw, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "%06d" % sc_val, cw, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw, ry + 6.0), Color("f5dec0"), 1.5)

	# BEST with Crown Icon
	ry += row_h
	CartoonDraw.draw_star(self, Vector2(cx0 + 12.0, ry - 6.0), 10.0, 5.0, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.5)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0 + 28.0, ry), "BEST", cw - 28, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "%06d" % best_val, cw, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw, ry + 6.0), Color("f5dec0"), 1.5)

	# MAX COMBO
	ry += row_h
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "MAX COMBO", cw, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), str(mc_val), cw, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw, ry + 6.0), Color("f5dec0"), 1.5)

	# PERFECT / GOOD / MISS with colored circles (Panel 09!)
	var stat_rows := [
		["PERFECT", int(counts.get("Perfect", 0)), CartoonDraw.GOLD, CartoonDraw.INK],
		["GOOD", int(counts.get("Good", 0)), CartoonDraw.SKY_BLUE, CartoonDraw.INK],
		["MISS", int(counts.get("Miss", 0)), CartoonDraw.HOT_PINK, Color("d92648")],
	]
	for srow in stat_rows:
		ry += row_h * 0.92
		CartoonDraw.draw_outlined_circle(self, Vector2(cx0 + 10.0, ry - 6.0), 7.5, srow[2], CartoonDraw.INK, 2.2)
		CartoonDraw.draw_outlined_text(self, Vector2(cx0 + 26.0, ry), str(srow[0]), cw - 26, r_fs - 2, srow[3], Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
		CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), str(srow[1]), cw, r_fs - 1, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
