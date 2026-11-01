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
var bg_title_tex: Texture2D
var bg_results_tex: Texture2D
var bg_select_tex: Texture2D
var trio_celebration_tex: Texture2D
var worker_tex: Texture2D
var alien_tex: Texture2D
var chef_tex: Texture2D

func _init() -> void:
	bg_title_tex = load("res://assets/sprites/bg_title.png")
	bg_results_tex = load("res://assets/sprites/bg_results.png")
	bg_select_tex = load("res://assets/sprites/bg_select.png")
	trio_celebration_tex = load("res://assets/sprites/results/trio_celebration.png")
	worker_tex = load("res://assets/sprites/beat_factory/worker.png")
	alien_tex = load("res://assets/sprites/echo_planet/alien.png")
	chef_tex = load("res://assets/sprites/rhythm_kitchen/chef.png")

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
func _draw_title_screen_art(w: float, h: float, _beat: float, bob: float) -> void:
	if bg_title_tex:
		draw_texture_rect(bg_title_tex, Rect2(0, 0, w, h), false)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("ffe359"))

	# Cast characters standing cutely on stage floor
	var floor_y := h * 0.86
	var is_narrow := w < 520.0
	var s := 0.70 if is_narrow else 0.95
	var csz := 140.0 * s

	if worker_tex:
		draw_texture_rect_region(worker_tex, Rect2(w * 0.22 - csz * 0.5, floor_y - csz + bob * 0.4, csz, csz), Rect2(0.0, 0.0, 512.0, 512.0))
	if alien_tex:
		draw_texture_rect_region(alien_tex, Rect2(w * 0.38 - csz * 0.5, floor_y - csz - bob * 0.5, csz, csz), Rect2(0.0, 0.0, 512.0, 512.0))
	if chef_tex:
		draw_texture_rect_region(chef_tex, Rect2(w * 0.62 - csz * 0.5, floor_y - csz + bob * 0.4, csz, csz), Rect2(0.0, 0.0, 512.0, 512.0))

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

	var s := minf(w / 240.0, h / 320.0)
	if is_narrow:
		s = minf(w / 280.0, h / 110.0)
	var bottom_limit := outer_rect.end.y - 6.0
	var csz := 170.0 * s
	if game_id == "beat_factory":
		if worker_tex:
			var src := Rect2(512.0, 0.0, 512.0, 512.0) # Ready / Pull frame
			draw_texture_rect_region(worker_tex, Rect2(w * 0.50 - csz * 0.5, bottom_limit - csz + bob * 0.2, csz, csz), src)
	elif game_id == "echo_planet":
		var space_c := Vector2(w * 0.50, h * 0.64)
		CartoonDraw.draw_outlined_ellipse(self, space_c, w * 0.38, h * 0.22, -0.1, Color("2e2466"), Color("4a3b8c"), 3.0)
		if alien_tex:
			var src := Rect2(0.0, 0.0, 512.0, 512.0) # Idle frame
			draw_texture_rect_region(alien_tex, Rect2(w * 0.50 - csz * 0.5, bottom_limit - csz + bob * 0.2, csz, csz), src)
	else:
		if chef_tex:
			var src := Rect2(0.0, 0.0, 512.0, 512.0) # Idle frame
			draw_texture_rect_region(chef_tex, Rect2(w * 0.50 - csz * 0.5, bottom_limit - csz + bob * 0.2, csz, csz), src)

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
			draw_line(fc + Vector2(0, -24.0 * fs_head), fc + Vector2(0, -38.0 * fs_head), CartoonDraw.INK, 3.5 * fs_head, true)
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
	var spot_pts := PackedVector2Array([
		Vector2(w * 0.50, -20.0),
		Vector2(w * 0.18, h),
		Vector2(w * 0.82, h),
	])
	draw_colored_polygon(spot_pts, Color(1.0, 0.92, 0.55, 0.12))
	var s := 0.85 if w < 520.0 else 1.15
	var csz := 180.0 * s
	var crect := Rect2(w * 0.50 - csz * 0.5, h * 0.66 - csz + bob * 0.3, csz, csz)
	var f_idx := 2 if grade_tier == "SUPERB" else 0 # Frame 2 is Perfect/Cheer, Frame 0 is Idle

	if game_id == "beat_factory" and worker_tex:
		draw_texture_rect_region(worker_tex, crect, Rect2(float(f_idx) * 512.0, 0.0, 512.0, 512.0))
	elif game_id == "echo_planet" and alien_tex:
		draw_texture_rect_region(alien_tex, crect, Rect2(float(f_idx) * 512.0, 0.0, 512.0, 512.0))
	elif chef_tex:
		var c_frame := 3 if grade_tier == "SUPERB" else 0
		draw_texture_rect_region(chef_tex, crect, Rect2(float(c_frame) * 512.0, 0.0, 512.0, 512.0))

# =============================================================================
# PANEL 09: RESULTS / AWARD SCREEN (09_results_superb.png)
# =============================================================================
func _draw_results_award_art(w: float, h: float, _beat: float, bob: float) -> void:
	var is_narrow := w < 520.0
	if bg_results_tex:
		draw_texture_rect(bg_results_tex, Rect2(0, 0, w, h), false)
	else:
		var bg_base := Color("ffa3bf") if grade_tier == "SUPERB" else (Color("9be0d4") if grade_tier == "OK" else Color("b0b5cf"))
		draw_rect(Rect2(0, 0, w, h), bg_base)

	var banner_txt := grade_tier + "!"
	var banner_col := CartoonDraw.GOLD if grade_tier == "SUPERB" else (CartoonDraw.MINT if grade_tier == "OK" else CartoonDraw.CORAL)
	var banner_fs := 38 if is_narrow else 58
	var banner_y := h * (0.08 if is_narrow else 0.12)
	CartoonDraw.draw_sticker_text(self, Vector2(0, banner_y), banner_txt, int(w), banner_fs, banner_col, CartoonDraw.INK, Color.WHITE, 4.5, 9.0)

	# High-Resolution Master Cheering Character Trio on Left (Worker, Alien, Chef)
	var trio_cx := w * (0.50 if is_narrow else 0.28)
	var trio_y := h * (0.48 if is_narrow else 0.85)
	var tw := 270.0 if is_narrow else 400.0
	var th := 175.0 if is_narrow else 260.0 # Exact 800:520 ratio

	if trio_celebration_tex:
		draw_texture_rect(trio_celebration_tex, Rect2(trio_cx - tw * 0.5, trio_y - th - bob * 0.3, tw, th), false)
	elif alien_tex and worker_tex and chef_tex:
		var csz_trio := 120.0
		draw_texture_rect_region(alien_tex, Rect2(trio_cx - csz_trio * 0.5, trio_y - csz_trio, csz_trio, csz_trio), Rect2(1024.0, 0.0, 512.0, 512.0))
		draw_texture_rect_region(worker_tex, Rect2(trio_cx - csz_trio * 1.3, trio_y - csz_trio, csz_trio, csz_trio), Rect2(1024.0, 0.0, 512.0, 512.0))
		draw_texture_rect_region(chef_tex, Rect2(trio_cx + csz_trio * 0.3, trio_y - csz_trio, csz_trio, csz_trio), Rect2(1536.0, 0.0, 512.0, 512.0))

	# Scoreboard Card on Right
	var card_rect := Rect2(w * 0.52, h * 0.20, w * 0.44, h * 0.62)
	if is_narrow:
		card_rect = Rect2(w * 0.08, h * 0.52, w * 0.84, h * 0.36)
	CartoonDraw.draw_outlined_box(self, card_rect, Color("fff8e7"), Color("f0a868"), 4.0, 20.0)

	var st_title := str(summary_data.get("stage_name", "Rhythm Kitchen"))
	var sc_val := int(summary_data.get("score", 52400))
	var best_val := int(summary_data.get("best", 52400))
	var mc_val := int(summary_data.get("max_combo", 28))
	var counts: Dictionary = summary_data.get("counts", {"Perfect": 26, "Good": 3, "Miss": 1})

	var cx0 := card_rect.position.x + 18.0
	var cw_card := int(card_rect.size.x - 36.0)
	var row_h := card_rect.size.y / 7.2
	var ry := card_rect.position.y + row_h * 0.85
	var h_fs := 18 if is_narrow else 26
	var r_fs := 14 if is_narrow else 20

	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), st_title, cw_card, h_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	draw_line(Vector2(cx0, ry + 8.0), Vector2(cx0 + cw_card, ry + 8.0), Color("f2cfa0"), 2.0)

	ry += row_h
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "SCORE", cw_card, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "%06d" % sc_val, cw_card, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw_card, ry + 6.0), Color("f5dec0"), 1.5)

	ry += row_h
	CartoonDraw.draw_star(self, Vector2(cx0 + 12.0, ry - 6.0), 10.0, 4.5, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.5)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0 + 28.0, ry), "BEST", cw_card - 28, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "%06d" % best_val, cw_card, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw_card, ry + 6.0), Color("f5dec0"), 1.5)

	ry += row_h
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), "MAX COMBO", cw_card, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), str(mc_val), cw_card, r_fs, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_line(Vector2(cx0, ry + 6.0), Vector2(cx0 + cw_card, ry + 6.0), Color("f5dec0"), 1.5)

	var stat_rows := [
		["PERFECT", int(counts.get("Perfect", 0)), CartoonDraw.GOLD, CartoonDraw.INK],
		["GOOD", int(counts.get("Good", 0)), CartoonDraw.SKY_BLUE, CartoonDraw.INK],
		["MISS", int(counts.get("Miss", 0)), CartoonDraw.HOT_PINK, Color("d92648")],
	]
	for srow in stat_rows:
		ry += row_h * 0.92
		CartoonDraw.draw_outlined_circle(self, Vector2(cx0 + 10.0, ry - 6.0), 7.5, srow[2], CartoonDraw.INK, 2.2)
		CartoonDraw.draw_outlined_text(self, Vector2(cx0 + 26.0, ry), str(srow[0]), cw_card - 26, r_fs - 2, srow[3], Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
		CartoonDraw.draw_outlined_text(self, Vector2(cx0, ry), str(srow[1]), cw_card, r_fs - 1, CartoonDraw.INK, Color.WHITE, 0.0, HORIZONTAL_ALIGNMENT_RIGHT)
