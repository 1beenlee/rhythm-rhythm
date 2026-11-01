extends RhythmVisual

var bg_tex: Texture2D
var chef_tex: Texture2D
var ing_tex: Texture2D
var fb_tex: Texture2D

func _ready() -> void:
	bg_tex = load("res://assets/sprites/bg_kitchen.png")
	chef_tex = load("res://assets/sprites/rhythm_kitchen/chef.png")
	ing_tex = load("res://assets/sprites/rhythm_kitchen/ingredients.png")
	fb_tex = load("res://assets/sprites/common/feedback.png")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var diff_l := next_event_diff("left")
	var diff_r := next_event_diff("right")
	var ant_l := clampf(1.0 - (diff_l / 0.85), 0.0, 1.0) if (diff_l >= 0.0 and diff_l <= 0.85) else 0.0
	var ant_r := clampf(1.0 - (diff_r / 0.85), 0.0, 1.0) if (diff_r >= 0.0 and diff_r <= 0.85) else 0.0
	var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# 1. Full-Resolution Kitchen Interior Background (960x640)
	if bg_tex:
		draw_texture_rect(bg_tex, Rect2(0, 0, w, h), false)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("fde6a8"))

	var counter_y := h * 0.84
	var left_cx := w * 0.22
	var right_cx := w * 0.78

	# 2. Chef Character in Center
	# Frames: 0=Idle, 1=Pan Left, 2=Pan Right, 3=Miss
	var chef_frame := 0
	if react_ratio > 0.0:
		if last_grade == "Miss":
			chef_frame = 3
		else:
			chef_frame = 1 if last_lane == "left" else 2
	elif ant_l > 0.20:
		chef_frame = 1
	elif ant_r > 0.20:
		chef_frame = 2

	var chef_w := 125.0 if is_narrow else 155.0
	var chef_h := 170.0 if is_narrow else 210.0
	var chef_x := w * 0.50 - chef_w * 0.5
	var chef_y := counter_y - chef_h + 12.0 + bob * 0.4

	if chef_tex:
		var src_chef := Rect2(float(chef_frame) * 150.0, 0.0, 150.0, 220.0)
		draw_texture_rect_region(chef_tex, Rect2(chef_x, chef_y, chef_w, chef_h), src_chef)

	# 3. Flying Cooking Ingredients (Tomato / Lettuce / Trio)
	_draw_flying_ingredients(w, h, counter_y, left_cx, right_cx, beat, counting, is_narrow)

	# 4. Clean Control Lane Indicators (Left = A, Right = D; Zero Unicode Tofu!)
	var badge_w := 90.0 if is_narrow else 110.0
	var badge_h := 38.0 if is_narrow else 44.0
	var badge_y := counter_y - 120.0

	# Left input prompt: "< A"
	var l_rect := Rect2(left_cx - badge_w * 0.5, badge_y, badge_w, badge_h)
	draw_rect(l_rect, Color(1, 1, 1, 0.92))
	draw_rect(l_rect, Color("181624"), false, 3.0)
	CartoonDraw.draw_outlined_text(self, l_rect.position + Vector2(0, badge_h * 0.70), "< A", int(badge_w), 20 if is_narrow else 24, Color("181624"), Color.WHITE, 1.5)

	# Right input prompt: "D >"
	var r_rect := Rect2(right_cx - badge_w * 0.5, badge_y, badge_w, badge_h)
	draw_rect(r_rect, Color(1, 1, 1, 0.92))
	draw_rect(r_rect, Color("181624"), false, 3.0)
	CartoonDraw.draw_outlined_text(self, r_rect.position + Vector2(0, badge_h * 0.70), "D >", int(badge_w), 20 if is_narrow else 24, Color("181624"), Color.WHITE, 1.5)

	# 5. Feedback Badge on Catch
	if react_ratio > 0.0:
		var fb_w := 130.0 if is_narrow else 160.0
		var fb_h := 38.0 if is_narrow else 46.0
		var fb_frame := 2 if last_grade == "Miss" else (0 if last_grade == "Perfect" else 1)
		var target_cx := left_cx if last_lane == "left" else right_cx
		if fb_tex:
			var src_fb := Rect2(float(fb_frame) * 220.0, 0.0, 220.0, 64.0)
			draw_texture_rect_region(fb_tex, Rect2(target_cx - fb_w * 0.5, counter_y - 170.0, fb_w, fb_h), src_fb)

	# 6. Top Stage HUD Bar
	var lit_dots := 0 if (counting or (score_value() == 0 and beat < 4.0)) else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	CartoonDraw.draw_stage_hud_banner(self, w, "Rhythm Kitchen", beat, score_value(), combo_value(), lit_dots, Color.WHITE)

func _draw_flying_ingredients(w: float, _h: float, counter_y: float, left_cx: float, right_cx: float, beat: float, counting: bool, is_narrow: bool) -> void:
	if counting:
		return

	var events: Array = chart.get("events", [])
	var item_size := 48.0 if is_narrow else 60.0

	for i in range(events.size()):
		var ev: Dictionary = events[i]
		var eb := float(ev.get("beat", 0.0))
		var diff := eb - beat
		# Ingredient is airborne for 3.0 beats prior to catch downbeat
		if diff < -0.35 or diff > 3.05:
			continue

		var lane := str(ev.get("lane", "left"))
		var pat := str(ev.get("pattern", "single"))
		var target_x := left_cx if lane == "left" else right_cx
		var start_x := -40.0 if lane == "left" else (w + 40.0)

		# Progress: 0.0 (toss) -> 1.0 (catch at pan)
		var prog := clampf(1.0 - (diff / 3.0), 0.0, 1.0)
		var cur_x := lerpf(start_x, target_x, prog)

		# High parabolic arc
		var arc_h := 160.0 if is_narrow else 210.0
		var cur_y := counter_y - 45.0 - (4.0 * arc_h * prog * (1.0 - prog))

		# Frame: 0=tomato, 1=lettuce, 2=trio
		var f_idx := 2 if pat == "triple" else (0 if lane == "right" else 1)

		if ing_tex:
			var src := Rect2(float(f_idx) * 70.0, 0.0, 70.0, 70.0)
			var d_rect := Rect2(cur_x - item_size * 0.5, cur_y - item_size * 0.5, item_size, item_size)
			draw_texture_rect_region(ing_tex, d_rect, src)
