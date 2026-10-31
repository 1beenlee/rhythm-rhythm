extends RhythmVisual

const TILE_CREAM := Color("fde6a8")
const TILE_WARM := Color("f7d488")
const TILE_LINE := Color("e6be70")
const PAN_DARK := Color("6c687a")
const PAN_MID := Color("918d9e")
const HOOD_COL := Color("b4aec6")
const BOWL_YELLOW := Color("ffe045")
const LETTUCE_GREEN := Color("78d639")
const LETTUCE_LIGHT := Color("b4f065")
const TOMATO_RED := Color("f23838")
const WOOD_TOP := Color("e3a268")
const WOOD_FRONT := Color("b8753e")

func _draw() -> void:
	var w := size.x
	var h := size.y
	var is_narrow := w < 520.0
	var counting := is_counting_down()
	var beat := 0.0 if counting else current_beat()
	var diff_l := next_event_diff("left")
	var diff_r := next_event_diff("right")
	var ant_l := clampf(1.0 - (diff_l / 0.65), 0.0, 1.0) if (diff_l >= 0.0 and diff_l <= 0.65) else 0.0
	var ant_r := clampf(1.0 - (diff_r / 0.65), 0.0, 1.0) if (diff_r >= 0.0 and diff_r <= 0.65) else 0.0
	var react_ratio := clampf(reaction_timer / 0.48, 0.0, 1.0)
	var bob := 0.0 if (reduced_motion or counting) else absf(sin(beat * PI)) * 5.0

	# 1. Background Layer: Warm Tiled Kitchen Wall, Upper-Left Hanging Skillets & Upper-Right Hood (Panels 07 & 08)
	draw_rect(Rect2(0, 0, w, h), TILE_CREAM)
	var cols := 6 if is_narrow else 9
	var rows := 5
	var tw := w / float(cols)
	var th := (h * 0.85) / float(rows)
	for r in range(rows):
		for c in range(cols):
			if (r + c) % 2 == 1:
				draw_rect(Rect2(c * tw, r * th, tw, th), Color(TILE_WARM.r, TILE_WARM.g, TILE_WARM.b, 0.45))
			draw_rect(Rect2(c * tw, r * th, tw, th), TILE_LINE, false, 2.0)

	# Two Hanging Round Grey Skillets on Upper-Left Wall (Panels 07 & 08)
	var pan_xs := [w * 0.12, w * 0.26]
	var pan_r := 36.0 if is_narrow else 48.0
	var pan_y := h * 0.34
	for px in pan_xs:
		CartoonDraw.draw_outlined_box(self, Rect2(px - 6.0, h * 0.10, 12.0, pan_y - pan_r - h * 0.10 + 6.0), PAN_MID, CartoonDraw.INK, 3.5, 2.0)
		CartoonDraw.draw_outlined_circle(self, Vector2(px, pan_y), pan_r, PAN_MID, CartoonDraw.INK, 4.0)
		CartoonDraw.draw_outlined_circle(self, Vector2(px, pan_y), pan_r * 0.78, Color("7e7a8c"), Color("5c5869"), 2.5)

	# Upper-Right Range Hood & Hanging Orange Utensil Rack (Panels 07 & 08)
	var hood_pts := PackedVector2Array([
		Vector2(w * 0.67, h * 0.12),
		Vector2(w + 8.0, h * 0.12),
		Vector2(w + 8.0, h * 0.28),
		Vector2(w * 0.65, h * 0.28),
	])
	CartoonDraw.draw_outlined_polygon(self, hood_pts, HOOD_COL, CartoonDraw.INK, 3.8)
	# Warm orange hanging rack below hood
	var rack_y := h * 0.38
	draw_line(Vector2(w * 0.75, h * 0.28), Vector2(w * 0.75, rack_y), Color("e08a3c"), 6.0)
	draw_line(Vector2(w * 0.88, h * 0.28), Vector2(w * 0.88, rack_y), Color("e08a3c"), 6.0)
	draw_line(Vector2(w * 0.68, rack_y), Vector2(w * 0.95, rack_y), Color("e08a3c"), 6.0)
	CartoonDraw.draw_outlined_box(self, Rect2(w * 0.71, rack_y, 56.0, 42.0), Color("f5aa58"), Color("d98234"), 2.5, 8.0)
	CartoonDraw.draw_outlined_box(self, Rect2(w * 0.84, rack_y, 56.0, 42.0), Color("f5aa58"), Color("d98234"), 2.5, 8.0)

	# Pinkish kitchen counter back-ledge behind bowls
	var counter_y := h * 0.86
	draw_rect(Rect2(0, counter_y - 46.0, w, 48.0), Color("f7c4ab"))
	draw_line(Vector2(0, counter_y - 46.0), Vector2(w, counter_y - 46.0), Color("e3a082"), 3.0)

	# 2. Center Character: The Chef (Panels 07, 08, 12)
	var chef_pos := Vector2(w * 0.50, counter_y + 2.0 + bob * 0.4)
	var chef_s := 0.88 if is_narrow else 1.12
	var is_hit_state := (react_ratio > 0.0 and last_grade != "Miss")
	var chef_pose := "idle"
	var chef_face := 0
	if react_ratio > 0.0:
		if last_grade == "Miss":
			chef_pose = "idle"
			chef_face = 5 # Sweat drop miss face from Panel 12!
		else:
			chef_pose = "both"
			chef_face = 3 # Big '> <' laughing face from Panel 08!
	elif ant_l > 0.25 or ant_r > 0.25:
		chef_pose = "left" if ant_l >= ant_r else "right"
		chef_face = 2 # Surprised 'o' cue face from Panel 12!

	CartoonDraw.draw_kitchen_chef(self, chef_pos, chef_s, chef_pose, chef_face, false)

	# 3. Left & Right Cooking Stations:
	# - In Idle/Cue (Panel 07): Yellow Bowls with Lettuce (Left) and Tomatoes (Right) + "◀ A" and "L ▶" Oval Badges!
	# - In Hit/Perfect (Panel 08): Dark Skillets Tossing Flying Lettuce & Sliced Tomatoes + Steam Puffs + "PERFECT!" Banner!
	var left_cx := w * 0.21
	var right_cx := w * 0.79
	if is_hit_state:
		_draw_tossing_skillet_left(Vector2(left_cx, counter_y - 12.0), is_narrow, react_ratio)
		_draw_tossing_skillet_right(Vector2(right_cx, counter_y - 12.0), is_narrow, react_ratio)
		paint_feedback(Vector2(w * (0.72 if is_narrow else 0.76), h * 0.34), false)
	else:
		_draw_idle_lettuce_bowl(Vector2(left_cx, counter_y - 6.0), is_narrow, ant_l)
		_draw_idle_tomato_bowl(Vector2(right_cx, counter_y - 6.0), is_narrow, ant_r)
		# Crisp White Oval Input Badges "◀ A" and "L ▶" from Panel 07!
		var badge_w := 115.0 if is_narrow else 155.0
		var badge_h := 56.0 if is_narrow else 74.0
		var badge_y := h * 0.56
		var l_col := CartoonDraw.GOLD if ant_l > 0.2 else CartoonDraw.PAPER
		var r_col := CartoonDraw.GOLD if ant_r > 0.2 else CartoonDraw.PAPER
		CartoonDraw.draw_outlined_ellipse(self, Vector2(left_cx, badge_y), badge_w * 0.5, badge_h * 0.5, 0.0, l_col, CartoonDraw.INK, 4.5)
		CartoonDraw.draw_outlined_text(self, Vector2(left_cx - badge_w * 0.5, badge_y + (11.0 if is_narrow else 14.0)), "◀ A", int(badge_w), 28 if is_narrow else 38, CartoonDraw.INK, l_col, 0.0)
		CartoonDraw.draw_outlined_ellipse(self, Vector2(right_cx, badge_y), badge_w * 0.5, badge_h * 0.5, 0.0, r_col, CartoonDraw.INK, 4.5)
		CartoonDraw.draw_outlined_text(self, Vector2(right_cx - badge_w * 0.5, badge_y + (11.0 if is_narrow else 14.0)), "L ▶", int(badge_w), 28 if is_narrow else 38, CartoonDraw.INK, r_col, 0.0)
		if react_ratio > 0.0:
			paint_feedback(Vector2(w * 0.74, h * 0.34), false)

	# 4. Foreground Layer: Warm Wooden Butcher-Block Countertop (Panels 07 & 08)
	CartoonDraw.draw_outlined_box(self, Rect2(-6.0, counter_y, w + 12.0, 26.0), WOOD_TOP, CartoonDraw.INK, 4.2, 2.0)
	CartoonDraw.draw_outlined_box(self, Rect2(-6.0, counter_y + 24.0, w + 12.0, h - counter_y), WOOD_FRONT, CartoonDraw.INK, 4.2, 2.0)

	# 5. Top Stage HUD Bar (Panels 07 & 08)
	var lit_dots := 2 if (counting or score_value() == 0) else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	CartoonDraw.draw_stage_hud_banner(self, w, "Rhythm Kitchen", beat, score_value(), combo_value(), lit_dots, Color.WHITE)

func _draw_idle_lettuce_bowl(pos: Vector2, is_narrow: bool, ant: float) -> void:
	var s := (0.78 if is_narrow else 1.0) * (1.0 + ant * 0.08)
	# Fluffy green lettuce leaves inside bowl (Panel 07)
	var leaf_offsets := [Vector2(-38.0, -38.0), Vector2(0.0, -44.0), Vector2(36.0, -36.0), Vector2(-18.0, -28.0), Vector2(20.0, -28.0)]
	for lo in leaf_offsets:
		CartoonDraw.draw_outlined_circle(self, pos + lo * s, 26.0 * s, LETTUCE_GREEN, CartoonDraw.INK, 3.8 * s)
	# Yellow bowl front
	var bowl_pts := PackedVector2Array([
		pos + Vector2(-82.0 * s, -28.0 * s),
		pos + Vector2(82.0 * s, -28.0 * s),
		pos + Vector2(54.0 * s, 10.0 * s),
		pos + Vector2(-54.0 * s, 10.0 * s),
	])
	CartoonDraw.draw_outlined_polygon(self, bowl_pts, BOWL_YELLOW, CartoonDraw.INK, 4.2 * s)

func _draw_idle_tomato_bowl(pos: Vector2, is_narrow: bool, ant: float) -> void:
	var s := (0.78 if is_narrow else 1.0) * (1.0 + ant * 0.08)
	# Two plump red tomatoes with green star stems (Panel 07)
	for tx in [-28.0 * s, 28.0 * s]:
		var tc := pos + Vector2(tx, -34.0 * s)
		CartoonDraw.draw_cel_circle(self, tc, 28.0 * s, TOMATO_RED, CartoonDraw.INK, 4.0 * s)
		CartoonDraw.draw_star(self, tc + Vector2(0, -24.0 * s), 11.0 * s, 4.5 * s, 5, 0.0, Color("2e8b3c"), CartoonDraw.INK, 2.5 * s)
	# Yellow bowl front
	var bowl_pts := PackedVector2Array([
		pos + Vector2(-82.0 * s, -26.0 * s),
		pos + Vector2(82.0 * s, -26.0 * s),
		pos + Vector2(54.0 * s, 10.0 * s),
		pos + Vector2(-54.0 * s, 10.0 * s),
	])
	CartoonDraw.draw_outlined_polygon(self, bowl_pts, BOWL_YELLOW, CartoonDraw.INK, 4.2 * s)

func _draw_tossing_skillet_left(pos: Vector2, is_narrow: bool, _react_ratio: float) -> void:
	var s := 0.78 if is_narrow else 1.0
	# Dark grey skillet pan (Panel 08 Left)
	var pan_pts := PackedVector2Array([
		pos + Vector2(-86.0 * s, -22.0 * s),
		pos + Vector2(86.0 * s, -22.0 * s),
		pos + Vector2(64.0 * s, 12.0 * s),
		pos + Vector2(-64.0 * s, 12.0 * s),
	])
	CartoonDraw.draw_outlined_polygon(self, pan_pts, PAN_DARK, CartoonDraw.INK, 4.2 * s)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(0, -22.0 * s), 84.0 * s, 14.0 * s, 0.0, Color("423d4f"), CartoonDraw.INK, 3.8 * s)
	# Tossed large green cabbage/lettuce leaf + smaller flying leaf + white steam puff (Panel 08!)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(4.0 * s, -54.0 * s), 44.0 * s, 28.0 * s, -0.35, LETTUCE_GREEN, CartoonDraw.INK, 4.0 * s)
	draw_line(pos + Vector2(-18.0 * s, -42.0 * s), pos + Vector2(20.0 * s, -62.0 * s), LETTUCE_LIGHT, 5.0 * s, true)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(-2.0 * s, -118.0 * s), 20.0 * s, 12.0 * s, -0.6, LETTUCE_GREEN, CartoonDraw.INK, 3.5 * s)
	# White steam puff on far left
	_draw_steam_puff(pos + Vector2(-78.0 * s, -84.0 * s), 0.95 * s)

func _draw_tossing_skillet_right(pos: Vector2, is_narrow: bool, _react_ratio: float) -> void:
	var s := 0.78 if is_narrow else 1.0
	# Dark grey skillet pan (Panel 08 Right)
	var pan_pts := PackedVector2Array([
		pos + Vector2(-86.0 * s, -22.0 * s),
		pos + Vector2(86.0 * s, -22.0 * s),
		pos + Vector2(64.0 * s, 12.0 * s),
		pos + Vector2(-64.0 * s, 12.0 * s),
	])
	CartoonDraw.draw_outlined_polygon(self, pan_pts, PAN_DARK, CartoonDraw.INK, 4.2 * s)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(0, -22.0 * s), 84.0 * s, 14.0 * s, 0.0, Color("4b3344"), CartoonDraw.INK, 3.8 * s)
	# Tossed red tomato slices, white slice, and green leaf (Panel 08 Right!)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(18.0 * s, -48.0 * s), 28.0 * s, 18.0 * s, -0.8, TOMATO_RED, CartoonDraw.INK, 3.8 * s)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(-28.0 * s, -58.0 * s), 26.0 * s, 16.0 * s, -0.2, Color.WHITE, CartoonDraw.INK, 3.8 * s)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(22.0 * s, -94.0 * s), 16.0 * s, 11.0 * s, 1.1, TOMATO_RED, CartoonDraw.INK, 3.5 * s)
	CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(-52.0 * s, -112.0 * s), 18.0 * s, 11.0 * s, 0.6, LETTUCE_GREEN, CartoonDraw.INK, 3.5 * s)
	# White steam puff on far right
	_draw_steam_puff(pos + Vector2(82.0 * s, -96.0 * s), 0.95 * s)

func _draw_steam_puff(c: Vector2, s: float) -> void:
	for off in [Vector2(-10.0, 0.0), Vector2(10.0, 0.0), Vector2(0.0, -10.0)]:
		canvas_item_circle_outline(c + off * s, 14.0 * s, CartoonDraw.INK)
	for off in [Vector2(-10.0, 0.0), Vector2(10.0, 0.0), Vector2(0.0, -10.0)]:
		draw_circle(c + off * s, 11.0 * s, Color.WHITE)

func canvas_item_circle_outline(p: Vector2, r: float, col: Color) -> void:
	draw_circle(p, r, col)
