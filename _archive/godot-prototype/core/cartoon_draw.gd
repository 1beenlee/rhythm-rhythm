extends RefCounted
class_name CartoonDraw

# =============================================================================
# RHYTHM RHYTHM v0.3 — STUDIO CEL-SHADED 2D VECTOR & SPRITE ART ENGINE
# Uses stroke-behind-fill ("paint-order: stroke fill") with round vertex joins
# so polygon corners NEVER produce miter spikes or internal seam lines in WebGL/OpenGL,
# and 100% pure ASCII text + vector icons so Web builds never show [25B6] tofu boxes.
# =============================================================================

const INK := Color("181624")
const PAPER := Color("fffdf7")
const CREAM := Color("fdf5e2")
const GOLD := Color("ffd524")
const HOT_PINK := Color("ff477e")
const SKY_BLUE := Color("4cc9f0")
const MINT := Color("5cd6b3")
const CORAL := Color("ff5c5c")
const SKIN := Color("ffe3c4")
const SKIN_BLUSH := Color("ff9eb5")

static var _tex_cache: Dictionary = {}

static func load_png_texture(res_path: String) -> Texture2D:
	if _tex_cache.has(res_path):
		return _tex_cache[res_path]
	if ResourceLoader.exists(res_path):
		var loaded := ResourceLoader.load(res_path)
		if loaded is Texture2D:
			_tex_cache[res_path] = loaded
			return loaded
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_tex_cache[res_path] = tex
			return tex
	return null

# -----------------------------------------------------------------------------
# 1. Core Cel-Shaded Primitives (Stroke-Behind-Fill + Round Vertex Joins!)
# -----------------------------------------------------------------------------
static func draw_round_stroke_loop(canvas: CanvasItem, points: PackedVector2Array, stroke_color: Color, stroke_width: float) -> void:
	if stroke_width <= 0.0 or points.size() < 2 or stroke_color.a <= 0.001:
		return
	var r := stroke_width * 0.5
	var n := points.size()
	for i in range(n):
		var p0 := points[i]
		var p1 := points[(i + 1) % n]
		canvas.draw_line(p0, p1, stroke_color, stroke_width, true)
		canvas.draw_circle(p0, r, stroke_color)

static func draw_outlined_circle(canvas: CanvasItem, center: Vector2, radius: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	if outline_width > 0.0 and outline_color.a > 0.001:
		canvas.draw_circle(center, radius + outline_width * 0.5, outline_color)
	canvas.draw_circle(center, maxf(0.5, radius - outline_width * 0.35), fill_color)

static func draw_outlined_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, rot: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0, steps: int = 36) -> void:
	var cr := cos(rot)
	var sr := sin(rot)
	if outline_width > 0.0 and outline_color.a > 0.001:
		var out_pts := PackedVector2Array()
		var orx := rx + outline_width * 0.55
		var ory := ry + outline_width * 0.55
		for i in range(steps):
			var a := TAU * float(i) / float(steps)
			var lx := cos(a) * orx
			var ly := sin(a) * ory
			out_pts.append(center + Vector2(lx * cr - ly * sr, lx * sr + ly * cr))
		canvas.draw_colored_polygon(out_pts, outline_color)
	var in_pts := PackedVector2Array()
	var irx := maxf(1.0, rx - outline_width * 0.25)
	var iry := maxf(1.0, ry - outline_width * 0.25)
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		var lx := cos(a) * irx
		var ly := sin(a) * iry
		in_pts.append(center + Vector2(lx * cr - ly * sr, lx * sr + ly * cr))
	canvas.draw_colored_polygon(in_pts, fill_color)

static func draw_outlined_polygon(canvas: CanvasItem, points: PackedVector2Array, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	if points.size() < 3:
		return
	# Paint-order: stroke FIRST (with round circle joins at every vertex), fill SECOND!
	if outline_width > 0.0 and outline_color.a > 0.001:
		draw_round_stroke_loop(canvas, points, outline_color, outline_width * 1.85)
	canvas.draw_colored_polygon(points, fill_color)

static func draw_outlined_box(canvas: CanvasItem, rect: Rect2, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0, corner_radius: float = 12.0, shadow_offset: Vector2 = Vector2.ZERO) -> void:
	var r := int(round(clampf(corner_radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)))
	if shadow_offset != Vector2.ZERO:
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0.06, 0.05, 0.12, 0.22)
		sh.corner_radius_top_left = r
		sh.corner_radius_top_right = r
		sh.corner_radius_bottom_left = r
		sh.corner_radius_bottom_right = r
		canvas.draw_style_box(sh, Rect2(rect.position + shadow_offset, rect.size))
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill_color
	sb.border_color = outline_color
	var bw := int(round(outline_width))
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	canvas.draw_style_box(sb, rect)

static func draw_limb(canvas: CanvasItem, from_pt: Vector2, to_pt: Vector2, radius: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	var r_out := radius + outline_width * 0.5
	var r_in := maxf(1.0, radius - outline_width * 0.35)
	if outline_width > 0.0 and outline_color.a > 0.001:
		canvas.draw_circle(from_pt, r_out, outline_color)
		canvas.draw_circle(to_pt, r_out, outline_color)
		canvas.draw_line(from_pt, to_pt, outline_color, r_out * 2.0, true)
	canvas.draw_circle(from_pt, r_in, fill_color)
	canvas.draw_circle(to_pt, r_in, fill_color)
	canvas.draw_line(from_pt, to_pt, fill_color, r_in * 2.0, true)

static func draw_star(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, num_points: int = 5, rot: float = -PI * 0.5, fill_color: Color = GOLD, outline_color: Color = INK, outline_width: float = 3.5) -> void:
	var pts := PackedVector2Array()
	var total := num_points * 2
	for i in range(total):
		var r := outer_r if (i % 2 == 0) else inner_r
		var a := rot + TAU * float(i) / float(total)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_music_note(canvas: CanvasItem, center: Vector2, scale_val: float, fill_color: Color = GOLD, outline_color: Color = INK) -> void:
	var s := scale_val
	var head_c := center + Vector2(-4.0 * s, 9.0 * s)
	var stem_bottom := head_c + Vector2(6.5 * s, -1.0 * s)
	var stem_top := head_c + Vector2(6.5 * s, -23.0 * s)
	var flag_end := stem_top + Vector2(11.0 * s, 6.5 * s)
	# Layer 1: Black outer silhouette
	canvas.draw_circle(head_c, 11.0 * s, outline_color)
	canvas.draw_line(stem_bottom, stem_top, outline_color, 9.5 * s, true)
	canvas.draw_circle(stem_top, 4.7 * s, outline_color)
	canvas.draw_line(stem_top, flag_end, outline_color, 9.5 * s, true)
	canvas.draw_circle(flag_end, 4.7 * s, outline_color)
	# Layer 2: Colored interior fill
	canvas.draw_circle(head_c, 7.2 * s, fill_color)
	canvas.draw_line(stem_bottom, stem_top, fill_color, 4.2 * s, true)
	canvas.draw_circle(stem_top, 2.1 * s, fill_color)
	canvas.draw_line(stem_top, flag_end, fill_color, 4.2 * s, true)
	canvas.draw_circle(flag_end, 2.1 * s, fill_color)

static func draw_jagged_burst_box(canvas: CanvasItem, center: Vector2, rx: float, ry: float, spikes: int = 14, fill_color: Color = PAPER, inner_color: Color = Color("fff0a8"), outline_color: Color = INK, outline_width: float = 4.5) -> void:
	var pts := PackedVector2Array()
	var in_pts := PackedVector2Array()
	var total := spikes * 2
	for i in range(total):
		var a := TAU * float(i) / float(total) - 0.18
		var is_outer := (i % 2 == 0)
		var mult_x := (1.16 if (i % 4 == 0) else 1.04) if is_outer else 0.76
		var mult_y := (1.18 if (i % 4 == 2) else 1.02) if is_outer else 0.72
		pts.append(center + Vector2(cos(a) * rx * mult_x, sin(a) * ry * mult_y))
		in_pts.append(center + Vector2(cos(a) * rx * mult_x * 0.84, sin(a) * ry * mult_y * 0.84))
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)
	canvas.draw_colored_polygon(in_pts, inner_color)

static func draw_sweat_drop(canvas: CanvasItem, top_pos: Vector2, s: float = 1.0) -> void:
	var drop_c := top_pos + Vector2(0.0, 12.0 * s)
	var pts := PackedVector2Array([
		top_pos,
		drop_c + Vector2(7.0 * s, -2.0 * s),
		drop_c + Vector2(5.5 * s, 5.5 * s),
		drop_c + Vector2(0.0, 8.0 * s),
		drop_c + Vector2(-5.5 * s, 5.5 * s),
		drop_c + Vector2(-7.0 * s, -2.0 * s),
	])
	draw_outlined_polygon(canvas, pts, Color("5ce1e6"), INK, 3.0 * s)
	canvas.draw_circle(drop_c + Vector2(-1.8 * s, 1.5 * s), 2.0 * s, Color.WHITE)

# -----------------------------------------------------------------------------
# 2. Vector Icons for Buttons (Eliminates ALL Unicode [25B6] Tofu Boxes on Web!)
# -----------------------------------------------------------------------------
static func attach_button_icon(btn: Button, icon_kind: String, icon_color: Color = INK) -> void:
	btn.draw.connect(func():
		var cy := btn.size.y * 0.5
		var cx := 26.0
		if icon_kind == "play":
			var tri := PackedVector2Array([
				Vector2(cx - 6.0, cy - 8.0),
				Vector2(cx - 6.0, cy + 8.0),
				Vector2(cx + 8.0, cy),
			])
			canvas_triangle(btn, tri, icon_color)
		elif icon_kind == "back":
			var tri := PackedVector2Array([
				Vector2(cx + 6.0, cy - 7.0),
				Vector2(cx + 6.0, cy + 7.0),
				Vector2(cx - 7.0, cy),
			])
			canvas_triangle(btn, tri, icon_color)
		elif icon_kind == "arrows_lr":
			var t_left := PackedVector2Array([
				Vector2(cx - 2.0, cy - 6.5),
				Vector2(cx - 2.0, cy + 6.5),
				Vector2(cx - 12.0, cy),
			])
			var t_right := PackedVector2Array([
				Vector2(cx + 4.0, cy - 6.5),
				Vector2(cx + 4.0, cy + 6.5),
				Vector2(cx + 14.0, cy),
			])
			canvas_triangle(btn, t_left, icon_color)
			canvas_triangle(btn, t_right, icon_color)
		elif icon_kind == "gear":
			btn.draw_circle(Vector2(cx, cy), 7.5, Color("7b68ee"))
			for i in range(6):
				var a := TAU * float(i) / 6.0
				btn.draw_circle(Vector2(cx + cos(a) * 7.5, cy + sin(a) * 7.5), 2.4, Color("7b68ee"))
			btn.draw_circle(Vector2(cx, cy), 3.2, PAPER)
		elif icon_kind == "plane":
			var p_pts := PackedVector2Array([
				Vector2(cx - 8.0, cy + 2.0),
				Vector2(cx + 8.0, cy - 6.0),
				Vector2(cx + 2.0, cy + 7.0),
				Vector2(cx - 1.0, cy + 2.0),
			])
			btn.draw_colored_polygon(p_pts, Color("3b82f6"))
		elif icon_kind == "music":
			draw_music_note(btn, Vector2(cx, cy + 2.0), 0.58, GOLD, INK)
		elif icon_kind == "star":
			draw_star(btn, Vector2(cx, cy), 9.0, 4.2, 5, -PI * 0.5, GOLD, INK, 2.0)
		elif icon_kind == "restart":
			btn.draw_arc(Vector2(cx, cy), 7.5, -PI * 0.35, PI * 1.45, 20, icon_color, 3.0, true)
			var tip := Vector2(cx + cos(-PI * 0.35) * 7.5, cy + sin(-PI * 0.35) * 7.5)
			canvas_triangle(btn, PackedVector2Array([tip + Vector2(-5.0, -3.0), tip + Vector2(4.0, -5.0), tip + Vector2(2.0, 4.0)]), icon_color)
	)

static func canvas_triangle(canvas: CanvasItem, tri: PackedVector2Array, col: Color) -> void:
	draw_round_stroke_loop(canvas, tri, col, 2.0)
	canvas.draw_colored_polygon(tri, col)

static func draw_arrow_triangle(canvas: CanvasItem, center: Vector2, dir_x: float, radius: float, fill_col: Color = INK) -> void:
	var d := 1.0 if dir_x >= 0.0 else -1.0
	var tri := PackedVector2Array([
		center + Vector2(-d * radius * 0.75, -radius * 0.85),
		center + Vector2(-d * radius * 0.75, radius * 0.85),
		center + Vector2(d * radius * 0.95, 0.0),
	])
	draw_round_stroke_loop(canvas, tri, fill_col, 2.5)
	canvas.draw_colored_polygon(tri, fill_col)

# -----------------------------------------------------------------------------
# 3. Expressive Cartoon Eyes & Mouths (Panels 10, 11, 12 Face Sheets)
# -----------------------------------------------------------------------------
static func draw_eyes(canvas: CanvasItem, center: Vector2, spacing: float, radius: float, style: String = "normal") -> void:
	for side in [-1.0, 1.0]:
		var ep := center + Vector2(side * spacing * 0.5, 0.0)
		if style == "happy" or style == "squint":
			# Clean '> <' or '^ ^' comic joy eyes using round-capped lines
			var p_top := ep + Vector2(-side * radius * 1.15, -radius * 0.75)
			var p_mid := ep + Vector2(side * radius * 0.95, 0.0)
			var p_bot := ep + Vector2(-side * radius * 1.15, radius * 0.75)
			if style == "happy":
				p_top = ep + Vector2(-radius * 1.15, radius * 0.35)
				p_mid = ep + Vector2(0.0, -radius * 0.75)
				p_bot = ep + Vector2(radius * 1.15, radius * 0.35)
			canvas.draw_line(p_top, p_mid, INK, 3.8, true)
			canvas.draw_line(p_mid, p_bot, INK, 3.8, true)
			canvas.draw_circle(p_top, 1.9, INK)
			canvas.draw_circle(p_mid, 1.9, INK)
			canvas.draw_circle(p_bot, 1.9, INK)
		elif style == "closed_u":
			var p_l := ep + Vector2(-radius * 1.1, -radius * 0.2)
			var p_m := ep + Vector2(0.0, radius * 0.55)
			var p_r := ep + Vector2(radius * 1.1, -radius * 0.2)
			canvas.draw_line(p_l, p_m, INK, 3.6, true)
			canvas.draw_line(p_m, p_r, INK, 3.6, true)
			canvas.draw_circle(p_m, 1.8, INK)
		elif style == "focused":
			canvas.draw_circle(ep, radius, INK)
			canvas.draw_circle(ep + Vector2(-radius * 0.28, -radius * 0.30), radius * 0.34, Color.WHITE)
			canvas.draw_line(ep + Vector2(-radius * 1.3, -radius * 1.65 - side * 1.5), ep + Vector2(radius * 1.2, -radius * 1.15 + side * 2.0), INK, 3.6, true)
		elif style == "surprised":
			canvas.draw_circle(ep, radius * 0.95, INK)
			canvas.draw_circle(ep + Vector2(-radius * 0.25, -radius * 0.28), radius * 0.34, Color.WHITE)
			canvas.draw_arc(ep + Vector2(0.0, -radius * 1.3), radius * 1.1, PI * 1.15, PI * 1.85, 10, INK, 3.2, true)
		elif style == "wide":
			draw_outlined_circle(canvas, ep, radius * 1.65, Color.WHITE, INK, 3.0)
			canvas.draw_circle(ep, radius * 0.65, INK)
		elif style == "dizzy":
			var r := radius * 1.15
			canvas.draw_line(ep + Vector2(-r, -r), ep + Vector2(r, r), INK, 3.6, true)
			canvas.draw_line(ep + Vector2(r, -r), ep + Vector2(-r, r), INK, 3.6, true)
		else:
			canvas.draw_circle(ep, radius, INK)
			canvas.draw_circle(ep + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.36, Color.WHITE)

static func draw_mouth(canvas: CanvasItem, center: Vector2, width: float, height: float, style: String = "smile") -> void:
	if style == "open_d" or style == "sing_tall":
		var mw := width * (0.48 if style == "sing_tall" else 0.85)
		var mh := height * (1.55 if style == "sing_tall" else 1.05)
		var pts := PackedVector2Array([
			center + Vector2(-mw * 0.5, -mh * 0.25),
			center + Vector2(mw * 0.5, -mh * 0.25),
			center + Vector2(mw * 0.42, mh * 0.52),
			center + Vector2(0.0, mh * 0.82),
			center + Vector2(-mw * 0.42, mh * 0.52),
		])
		draw_outlined_polygon(canvas, pts, Color("8a1c36"), INK, 3.4)
		var tongue := PackedVector2Array([
			center + Vector2(-mw * 0.30, mh * 0.32),
			center + Vector2(mw * 0.30, mh * 0.32),
			center + Vector2(0.0, mh * 0.72),
		])
		canvas.draw_colored_polygon(tongue, Color("ff6b8b"))
	elif style == "open_o":
		draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.15), width * 0.28, height * 0.48, 0.0, Color("8a1c36"), INK, 3.2)
		canvas.draw_circle(center + Vector2(0.0, height * 0.28), width * 0.15, Color("ff6b8b"))
	elif style == "flat":
		canvas.draw_line(center + Vector2(-width * 0.35, 0.0), center + Vector2(width * 0.35, 0.0), INK, 3.6, true)
	elif style == "frown":
		canvas.draw_arc(center + Vector2(0.0, height * 0.55), width * 0.38, PI * 1.18, PI * 1.82, 14, INK, 3.6, true)
	else:
		canvas.draw_arc(center + Vector2(0.0, -height * 0.10), width * 0.38, PI * 0.15, PI * 0.85, 14, INK, 3.6, true)

# -----------------------------------------------------------------------------
# 4. Outlined Text, Sticker Text, Seamless Speech Bubbles & Top Stage HUD Bar
# -----------------------------------------------------------------------------
static func draw_outlined_text(canvas: CanvasItem, pos: Vector2, text: String, width: int, font_size: int, fill_color: Color = PAPER, outline_color: Color = INK, outline_px: float = 4.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	if outline_px > 0.0 and outline_color.a > 0.001:
		var offsets: Array[Vector2] = [
			Vector2(-outline_px, 0.0), Vector2(outline_px, 0.0),
			Vector2(0.0, -outline_px), Vector2(0.0, outline_px),
			Vector2(-outline_px * 0.72, -outline_px * 0.72), Vector2(outline_px * 0.72, -outline_px * 0.72),
			Vector2(-outline_px * 0.72, outline_px * 0.72), Vector2(outline_px * 0.72, outline_px * 0.72),
		]
		for off: Vector2 in offsets:
			canvas.draw_string(font, pos + off, text, align, width, font_size, outline_color)
	canvas.draw_string(font, pos, text, align, width, font_size, fill_color)

static func draw_sticker_text(canvas: CanvasItem, pos: Vector2, text: String, width: int, font_size: int, fill_color: Color, inner_outline: Color = INK, sticker_color: Color = Color.WHITE, inner_px: float = 3.5, sticker_px: float = 7.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	for step_r: float in [sticker_px, inner_px]:
		var col := sticker_color if step_r == sticker_px else inner_outline
		for i in range(12):
			var a := TAU * float(i) / 12.0
			var off: Vector2 = Vector2(cos(a), sin(a)) * step_r
			canvas.draw_string(font, pos + off, text, align, width, font_size, col)
	canvas.draw_string(font, pos, text, align, width, font_size, fill_color)

static func draw_speech_bubble(canvas: CanvasItem, rect: Rect2, tail_target: Vector2, text: String, bg_color: Color = PAPER, text_color: Color = INK, font_size: int = 20) -> void:
	# 100% seamless two-pass speech bubble: Outline pass FIRST, Fill pass SECOND!
	var bw := 4.2
	var r := minf(rect.size.y * 0.45, 24.0)
	var center := rect.get_center()
	var base_x := clampf(tail_target.x, rect.position.x + 28.0, rect.end.x - 28.0)
	var is_bottom := tail_target.y >= center.y
	var edge_y := rect.end.y if is_bottom else rect.position.y
	var inside_y := edge_y - 8.0 if is_bottom else edge_y + 8.0

	var tri_inner := PackedVector2Array([
		Vector2(base_x - 13.0, inside_y),
		Vector2(base_x + 13.0, inside_y),
		tail_target,
	])

	# Pass 1: Black outer outline of box + tail (with round tip circle!)
	var sb_out := StyleBoxFlat.new()
	sb_out.bg_color = INK
	var r_out := int(round(r + bw))
	sb_out.corner_radius_top_left = r_out
	sb_out.corner_radius_top_right = r_out
	sb_out.corner_radius_bottom_left = r_out
	sb_out.corner_radius_bottom_right = r_out
	canvas.draw_style_box(sb_out, rect.grow(bw))
	draw_round_stroke_loop(canvas, tri_inner, INK, bw * 2.0)
	canvas.draw_colored_polygon(tri_inner, INK)

	# Pass 2: Inner clean fill of box + tail (completely eliminates the tail seam!)
	var sb_in := StyleBoxFlat.new()
	sb_in.bg_color = bg_color
	var r_in := int(round(r))
	sb_in.corner_radius_top_left = r_in
	sb_in.corner_radius_top_right = r_in
	sb_in.corner_radius_bottom_left = r_in
	sb_in.corner_radius_bottom_right = r_in
	canvas.draw_style_box(sb_in, rect)
	canvas.draw_colored_polygon(tri_inner, bg_color)

	if text != "":
		draw_outlined_text(canvas, Vector2(rect.position.x + 8.0, rect.position.y + rect.size.y * 0.5 + float(font_size) * 0.35), text, int(rect.size.x - 16.0), font_size, text_color, PAPER, 0.0)

static func draw_stage_hud_banner(canvas: CanvasItem, w: float, stage_title: String, _beat: float, score_val: int, combo_val: int, active_dots: int = 0, dot_color: Color = Color.WHITE) -> void:
	var is_narrow := w < 520.0
	var bar_h := 48.0 if is_narrow else 56.0
	var bar_rect := Rect2(8.0, 6.0, w - 16.0, bar_h)
	draw_outlined_box(canvas, bar_rect, Color("1a2138"), INK, 4.0, 14.0)
	canvas.draw_line(Vector2(bar_rect.position.x + 12.0, bar_rect.end.y - 4.0), Vector2(bar_rect.end.x - 12.0, bar_rect.end.y - 4.0), Color("2b3556"), 2.0)

	var cy := bar_rect.get_center().y
	draw_music_note(canvas, Vector2(bar_rect.position.x + 26.0, cy + 2.0), 0.72 if is_narrow else 0.88, GOLD, INK)
	var title_fs := 16 if is_narrow else 22
	draw_outlined_text(canvas, Vector2(bar_rect.position.x + (46.0 if is_narrow else 54.0), cy + float(title_fs) * 0.36), stage_title, 240, title_fs, PAPER, INK, 3.0, HORIZONTAL_ALIGNMENT_LEFT)

	var dot_spacing := 16.0 if is_narrow else 22.0
	var dots_x0 := w * 0.50 - dot_spacing * 1.5
	canvas.draw_line(Vector2(dots_x0, cy), Vector2(dots_x0 + dot_spacing * 3.0, cy), Color("5b6582"), 3.0)
	for i in range(4):
		var dx := dots_x0 + float(i) * dot_spacing
		var is_lit := (i < active_dots)
		var dc := dot_color if is_lit else Color("687394")
		draw_outlined_circle(canvas, Vector2(dx, cy), 6.5 if is_narrow else 8.0, dc, INK, 2.5)

	var right_x := bar_rect.end.x - (86.0 if is_narrow else 108.0)
	var score_fs := 13 if is_narrow else 16
	var combo_fs := 11 if is_narrow else 14
	var score_str := "SCORE %06d" % score_val
	var combo_str := "COMBO %d" % combo_val
	draw_outlined_text(canvas, Vector2(right_x - 190.0, cy - 2.0), score_str, 185, score_fs, PAPER, INK, 2.5, HORIZONTAL_ALIGNMENT_RIGHT)
	var combo_col := GOLD if combo_val > 0 else Color("b5bfd9")
	draw_outlined_text(canvas, Vector2(right_x - 190.0, cy + 16.0), combo_str, 185, combo_fs, combo_col, INK, 2.5, HORIZONTAL_ALIGNMENT_RIGHT)

# =============================================================================
# 5. CANONICAL v0.3 CHARACTER RIGS (Stroke-Behind-Fill Cel Shading!)
# =============================================================================

static func draw_factory_worker(canvas: CanvasItem, base_pos: Vector2, s: float, pose: String = "idle", face_idx: int = 0, show_lever: bool = true) -> void:
	var head_c := base_pos + Vector2(0.0, -52.0 * s)
	var torso_rect := Rect2(base_pos.x - 21.0 * s, base_pos.y - 26.0 * s, 42.0 * s, 42.0 * s)

	# 1. Legs & Shoes (visible in character sheet & full-body views)
	draw_outlined_box(canvas, Rect2(base_pos.x - 18.0 * s, base_pos.y + 8.0 * s, 15.0 * s, 22.0 * s), Color("1d4e89"), INK, 3.6 * s, 4.0 * s)
	draw_outlined_box(canvas, Rect2(base_pos.x + 3.0 * s, base_pos.y + 8.0 * s, 15.0 * s, 22.0 * s), Color("1d4e89"), INK, 3.6 * s, 4.0 * s)
	draw_outlined_ellipse(canvas, base_pos + Vector2(-11.0 * s, 30.0 * s), 10.0 * s, 6.0 * s, 0.0, INK, INK, 2.0 * s)
	draw_outlined_ellipse(canvas, base_pos + Vector2(11.0 * s, 30.0 * s), 10.0 * s, 6.0 * s, 0.0, INK, INK, 2.0 * s)

	# 2. Left/Right Arms Behind Lever
	var sh_l := base_pos + Vector2(-19.0 * s, -18.0 * s)
	var sh_r := base_pos + Vector2(19.0 * s, -18.0 * s)
	var hand_l := base_pos + Vector2(-24.0 * s, 4.0 * s)
	var hand_r := base_pos + Vector2(24.0 * s, 4.0 * s)

	if pose == "ready":
		hand_r = base_pos + Vector2(36.0 * s, -16.0 * s)
	elif pose == "hit":
		hand_l = base_pos + Vector2(-34.0 * s, 2.0 * s)
		hand_r = base_pos + Vector2(22.0 * s, 6.0 * s)
		var w1 := PackedVector2Array([base_pos + Vector2(-22.0 * s, -14.0 * s), base_pos + Vector2(-50.0 * s, -26.0 * s), base_pos + Vector2(-42.0 * s, -8.0 * s)])
		var w2 := PackedVector2Array([base_pos + Vector2(-18.0 * s, -22.0 * s), base_pos + Vector2(-38.0 * s, -42.0 * s), base_pos + Vector2(-26.0 * s, -28.0 * s)])
		draw_outlined_polygon(canvas, w1, GOLD, INK, 3.0 * s)
		draw_outlined_polygon(canvas, w2, GOLD, INK, 3.0 * s)
	elif pose == "cheer":
		hand_l = base_pos + Vector2(-38.0 * s, -42.0 * s)
		hand_r = base_pos + Vector2(38.0 * s, -42.0 * s)

	draw_limb(canvas, sh_l, hand_l, 6.5 * s, Color.WHITE, INK, 3.6 * s)
	draw_outlined_circle(canvas, hand_l, 7.2 * s, SKIN, INK, 3.2 * s)
	if not show_lever:
		draw_limb(canvas, sh_r, hand_r, 6.5 * s, Color.WHITE, INK, 3.6 * s)
		draw_outlined_circle(canvas, hand_r, 7.2 * s, SKIN, INK, 3.2 * s)

	# 3. Torso: White Shirt + Blue Overalls + Yellow Buttons
	draw_outlined_box(canvas, torso_rect, Color.WHITE, INK, 3.8 * s, 8.0 * s)
	var bib_rect := Rect2(base_pos.x - 18.0 * s, base_pos.y - 16.0 * s, 36.0 * s, 32.0 * s)
	draw_outlined_box(canvas, bib_rect, Color("1f5aa6"), INK, 3.6 * s, 6.0 * s)
	draw_outlined_box(canvas, Rect2(base_pos.x - 15.0 * s, base_pos.y - 26.0 * s, 8.0 * s, 14.0 * s), Color("1f5aa6"), INK, 3.0 * s, 2.0 * s)
	draw_outlined_box(canvas, Rect2(base_pos.x + 7.0 * s, base_pos.y - 26.0 * s, 8.0 * s, 14.0 * s), Color("1f5aa6"), INK, 3.0 * s, 2.0 * s)
	draw_outlined_circle(canvas, base_pos + Vector2(-11.0 * s, -12.0 * s), 3.6 * s, GOLD, INK, 2.2 * s)
	draw_outlined_circle(canvas, base_pos + Vector2(11.0 * s, -12.0 * s), 3.6 * s, GOLD, INK, 2.2 * s)

	if show_lever:
		draw_limb(canvas, sh_r, hand_r, 6.5 * s, Color.WHITE, INK, 3.6 * s)
		draw_outlined_circle(canvas, hand_r, 7.2 * s, SKIN, INK, 3.2 * s)

	# 4. Head: Brown Side Bun + Round Peach Face + Yellow Hard Hat
	draw_outlined_circle(canvas, head_c + Vector2(-26.0 * s, -2.0 * s), 13.0 * s, Color("5c3c24"), INK, 3.8 * s)
	draw_outlined_circle(canvas, head_c, 28.0 * s, SKIN, INK, 4.0 * s)
	canvas.draw_arc(head_c + Vector2(0.0, -4.0 * s), 25.0 * s, PI * 0.92, PI * 1.38, 12, Color("5c3c24"), 7.0 * s, true)

	_draw_worker_face(canvas, head_c + Vector2(2.0 * s, 4.0 * s), s, face_idx)

	# Yellow Hard Hat (Two-pass dome + brim + red front stripe)
	var hat_rot := -0.04 if pose == "hit" else 0.0
	var dome_c := head_c + Vector2(0.0, -14.0 * s)
	var dome_pts := PackedVector2Array()
	for i in range(19):
		var a := PI + PI * float(i) / 18.0 + hat_rot
		dome_pts.append(dome_c + Vector2(cos(a) * 31.0 * s, sin(a) * 24.0 * s))
	draw_outlined_polygon(canvas, dome_pts, Color("ffd524"), INK, 4.0 * s)
	canvas.draw_line(dome_c + Vector2(-12.0 * s, -11.0 * s), dome_c + Vector2(14.0 * s, -12.0 * s), Color("e63946"), 4.2 * s, true)
	var brim_pts := PackedVector2Array([
		dome_c + Vector2(-35.0 * s, -2.0 * s),
		dome_c + Vector2(36.0 * s, -4.0 * s),
		dome_c + Vector2(34.0 * s, 3.0 * s),
		dome_c + Vector2(-34.0 * s, 5.0 * s),
	])
	draw_outlined_polygon(canvas, brim_pts, Color("f4c418"), INK, 3.8 * s)

	# Sweat drop drawn ON TOP of cheek/temple so it is never clipped under the hat brim!
	if face_idx == 5:
		draw_sweat_drop(canvas, head_c + Vector2(24.0 * s, -4.0 * s), 0.85 * s)

	if pose == "ready":
		for i in [-1, 0, 1]:
			var ang := -PI * 0.5 + float(i) * 0.28
			var p0 := head_c + Vector2(cos(ang), sin(ang)) * 42.0 * s
			var p1 := head_c + Vector2(cos(ang), sin(ang)) * 54.0 * s
			canvas.draw_line(p0, p1, Color("ff8c1a"), 4.2 * s, true)

	# 5. Foreground Red-Knob Industrial Lever
	if show_lever:
		var lev_base := base_pos + Vector2(44.0 * s, 16.0 * s)
		var pulled := (pose == "hit")
		var shaft_bottom := lev_base + Vector2(0.0, -14.0 * s)
		var knob_pos := lev_base + (Vector2(18.0 * s, -22.0 * s) if pulled else Vector2(-4.0 * s, -36.0 * s))
		draw_limb(canvas, shaft_bottom, knob_pos, 4.8 * s, Color("8d99ae"), INK, 3.6 * s)
		var base_trap := PackedVector2Array([
			lev_base + Vector2(-22.0 * s, 0.0),
			lev_base + Vector2(-15.0 * s, -18.0 * s),
			lev_base + Vector2(15.0 * s, -18.0 * s),
			lev_base + Vector2(22.0 * s, 0.0),
		])
		draw_outlined_polygon(canvas, base_trap, Color("5c6478"), INK, 3.8 * s)
		draw_outlined_circle(canvas, knob_pos, 11.5 * s, Color("e63946"), INK, 3.8 * s)
		canvas.draw_circle(knob_pos + Vector2(-3.0 * s, -3.5 * s), 3.2 * s, Color("ff99a0"))

static func _draw_worker_face(canvas: CanvasItem, fc: Vector2, s: float, face_idx: int) -> void:
	canvas.draw_circle(fc + Vector2(-15.0 * s, 3.0 * s), 4.8 * s, SKIN_BLUSH)
	canvas.draw_circle(fc + Vector2(15.0 * s, 3.0 * s), 4.8 * s, SKIN_BLUSH)
	match face_idx:
		1:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 3.8 * s, "focused")
			draw_mouth(canvas, fc + Vector2(0.0, 8.0 * s), 12.0 * s, 6.0 * s, "flat")
		2:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 3.8 * s, "surprised")
			draw_mouth(canvas, fc + Vector2(0.0, 8.0 * s), 12.0 * s, 9.0 * s, "open_o")
		3:
			draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 18.0 * s, 4.2 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 16.0 * s, 11.0 * s, "open_d")
		4:
			draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 17.0 * s, 4.0 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 16.0 * s, 11.0 * s, "open_d")
		5:
			draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 17.0 * s, 3.8 * s, "dizzy")
			draw_mouth(canvas, fc + Vector2(0.0, 9.0 * s), 14.0 * s, 7.0 * s, "frown")
		_:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 4.0 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 12.0 * s, 7.0 * s, "smile")

static func draw_echo_alien(canvas: CanvasItem, base_pos: Vector2, s: float, pose: String = "idle", face_idx: int = 0, show_feet: bool = false) -> void:
	var body_blue := Color("76c8e8")
	var belly_mint := Color("bcebf5")
	var head_c := base_pos + Vector2(0.0, -56.0 * s)

	if show_feet:
		draw_limb(canvas, base_pos + Vector2(-9.0 * s, -4.0 * s), base_pos + Vector2(-9.0 * s, 14.0 * s), 7.5 * s, belly_mint, INK, 3.8 * s)
		draw_limb(canvas, base_pos + Vector2(9.0 * s, -4.0 * s), base_pos + Vector2(9.0 * s, 14.0 * s), 7.5 * s, belly_mint, INK, 3.8 * s)

	var sh_l := base_pos + Vector2(-15.0 * s, -26.0 * s)
	var sh_r := base_pos + Vector2(15.0 * s, -26.0 * s)
	var hand_l := base_pos + Vector2(-28.0 * s, -8.0 * s)
	var hand_r := base_pos + Vector2(28.0 * s, -8.0 * s)
	if pose == "sing":
		hand_l = base_pos + Vector2(-34.0 * s, -24.0 * s)
		hand_r = base_pos + Vector2(36.0 * s, -30.0 * s)
	elif pose == "success" or pose == "cheer":
		hand_l = base_pos + Vector2(-36.0 * s, -44.0 * s)
		hand_r = base_pos + Vector2(36.0 * s, -44.0 * s)

	draw_limb(canvas, sh_l, hand_l, 6.2 * s, body_blue, INK, 3.8 * s)
	draw_limb(canvas, sh_r, hand_r, 6.2 * s, body_blue, INK, 3.8 * s)

	var torso_pts := PackedVector2Array([
		base_pos + Vector2(-15.0 * s, -34.0 * s),
		base_pos + Vector2(15.0 * s, -34.0 * s),
		base_pos + Vector2(18.0 * s, 0.0),
		base_pos + Vector2(-18.0 * s, 0.0),
	])
	draw_outlined_polygon(canvas, torso_pts, body_blue, INK, 4.0 * s)
	draw_outlined_circle(canvas, base_pos + Vector2(0.0, -14.0 * s), 11.5 * s, belly_mint, Color.TRANSPARENT, 0.0)

	var ant_top := head_c + Vector2(-3.0 * s, -42.0 * s)
	canvas.draw_line(head_c + Vector2(-1.0 * s, -24.0 * s), ant_top, INK, 4.2 * s, true)
	var orb_lit := (pose == "sing" or pose == "success" or pose == "cheer" or face_idx == 1 or face_idx == 3)
	var orb_col := GOLD if orb_lit else Color("5ce1e6")
	draw_outlined_circle(canvas, ant_top, 9.0 * s, orb_col, INK, 3.4 * s)

	draw_outlined_ellipse(canvas, head_c, 35.0 * s, 28.0 * s, 0.0, body_blue, INK, 4.2 * s)
	draw_outlined_ellipse(canvas, head_c + Vector2(-12.0 * s, -10.0 * s), 12.0 * s, 7.0 * s, -0.3, Color("a3e2f7"), Color.TRANSPARENT, 0.0)

	_draw_alien_face(canvas, head_c + Vector2(0.0, 2.0 * s), s, face_idx, pose)

	if pose == "sing":
		var wave_origin := head_c + Vector2(36.0 * s, 2.0 * s)
		for wi in range(3):
			var wr := (16.0 + float(wi) * 11.0) * s
			canvas.draw_arc(wave_origin, wr, -0.52, 0.52, 14, GOLD, 4.2 * s, true)
	elif pose == "success" or pose == "cheer":
		var ray_base := head_c + Vector2(38.0 * s, -16.0 * s)
		for ri in [-1, 0, 1]:
			var a := -0.2 + float(ri) * 0.28
			canvas.draw_line(ray_base + Vector2(cos(a), sin(a)) * 6.0 * s, ray_base + Vector2(cos(a), sin(a)) * 22.0 * s, GOLD, 4.0 * s, true)

static func _draw_alien_face(canvas: CanvasItem, fc: Vector2, s: float, face_idx: int, pose: String) -> void:
	if pose == "sing" or face_idx == 1:
		draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 16.0 * s, 4.2 * s, "closed_u")
		draw_mouth(canvas, fc + Vector2(0.0, 9.0 * s), 15.0 * s, 14.0 * s, "sing_tall")
	elif pose == "listen" or face_idx == 2:
		draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 4.2 * s, "closed_u")
		draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 10.0 * s, 6.0 * s, "smile")
	elif pose == "success" or pose == "cheer" or face_idx == 3:
		draw_eyes(canvas, fc + Vector2(0.0, -4.0 * s), 17.0 * s, 4.2 * s, "happy")
		draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 16.0 * s, 11.0 * s, "open_d")
	elif face_idx == 4:
		draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 18.0 * s, 3.8 * s, "wide")
		draw_mouth(canvas, fc + Vector2(0.0, 8.0 * s), 14.0 * s, 9.0 * s, "open_d")
	elif face_idx == 5:
		draw_eyes(canvas, fc + Vector2(0.0, -3.0 * s), 18.0 * s, 3.8 * s, "wide")
		draw_mouth(canvas, fc + Vector2(0.0, 8.0 * s), 12.0 * s, 9.0 * s, "open_o")
	else:
		draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 15.0 * s, 4.0 * s, "normal")
		draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 10.0 * s, 6.0 * s, "smile")

static func draw_echo_astronaut(canvas: CanvasItem, base_pos: Vector2, s: float, pose: String = "listen") -> void:
	var head_c := base_pos + Vector2(0.0, -46.0 * s)
	var sh_l := base_pos + Vector2(-13.0 * s, -20.0 * s)
	var sh_r := base_pos + Vector2(13.0 * s, -20.0 * s)
	var hand_l := base_pos + Vector2(-24.0 * s, -28.0 * s if pose == "listen" else -38.0 * s)
	var hand_r := base_pos + Vector2(24.0 * s, -8.0 * s if pose == "listen" else -38.0 * s)
	draw_limb(canvas, sh_l, hand_l, 5.2 * s, Color.WHITE, INK, 3.4 * s)
	draw_limb(canvas, sh_r, hand_r, 5.2 * s, Color.WHITE, INK, 3.4 * s)

	var body_rect := Rect2(base_pos.x - 14.0 * s, base_pos.y - 26.0 * s, 28.0 * s, 30.0 * s)
	draw_outlined_box(canvas, body_rect, Color.WHITE, INK, 3.6 * s, 6.0 * s)
	canvas.draw_line(Vector2(body_rect.position.x + 2.0 * s, base_pos.y - 10.0 * s), Vector2(body_rect.end.x - 2.0 * s, base_pos.y - 10.0 * s), INK, 3.0 * s)
	draw_outlined_box(canvas, Rect2(base_pos.x - 6.0 * s, base_pos.y - 22.0 * s, 12.0 * s, 8.0 * s), Color("c4d4e8"), INK, 2.5 * s, 2.0 * s)

	draw_outlined_circle(canvas, head_c, 25.0 * s, Color.WHITE, INK, 3.8 * s)
	draw_outlined_circle(canvas, head_c + Vector2(0.0, 2.0 * s), 18.0 * s, SKIN, INK, 3.2 * s)
	canvas.draw_arc(head_c + Vector2(0.0, -2.0 * s), 14.0 * s, PI * 1.08, PI * 1.92, 12, Color("3c2f59"), 7.0 * s, true)

	var fc := head_c + Vector2(0.0, 4.0 * s)
	canvas.draw_circle(fc + Vector2(-10.0 * s, 3.0 * s), 3.2 * s, SKIN_BLUSH)
	canvas.draw_circle(fc + Vector2(10.0 * s, 3.0 * s), 3.2 * s, SKIN_BLUSH)
	if pose == "cheer":
		draw_eyes(canvas, fc + Vector2(0.0, -1.0 * s), 11.0 * s, 3.0 * s, "happy")
		draw_mouth(canvas, fc + Vector2(0.0, 6.0 * s), 10.0 * s, 7.5 * s, "open_d")
	elif pose == "miss":
		draw_eyes(canvas, fc + Vector2(0.0, -1.0 * s), 11.0 * s, 3.0 * s, "dizzy")
		draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 8.0 * s, 5.0 * s, "frown")
	else:
		draw_eyes(canvas, fc + Vector2(0.0, -1.0 * s), 11.0 * s, 3.0 * s, "normal")
		draw_mouth(canvas, fc + Vector2(0.0, 6.0 * s), 8.0 * s, 5.0 * s, "smile")

static func draw_kitchen_chef(canvas: CanvasItem, base_pos: Vector2, s: float, pose: String = "idle", face_idx: int = 0, show_legs: bool = false) -> void:
	var head_c := base_pos + Vector2(0.0, -52.0 * s)

	if show_legs:
		draw_outlined_box(canvas, Rect2(base_pos.x - 16.0 * s, base_pos.y + 4.0 * s, 32.0 * s, 22.0 * s), Color("1f4e8c"), INK, 3.6 * s, 4.0 * s)
		draw_outlined_ellipse(canvas, base_pos + Vector2(-8.0 * s, 28.0 * s), 8.5 * s, 5.0 * s, 0.0, INK, INK, 2.0 * s)
		draw_outlined_ellipse(canvas, base_pos + Vector2(8.0 * s, 28.0 * s), 8.5 * s, 5.0 * s, 0.0, INK, INK, 2.0 * s)

	var sh_l := base_pos + Vector2(-17.0 * s, -18.0 * s)
	var sh_r := base_pos + Vector2(17.0 * s, -18.0 * s)
	var hand_l := base_pos + Vector2(-32.0 * s, -2.0 * s)
	var hand_r := base_pos + Vector2(32.0 * s, -2.0 * s)
	if pose == "left":
		hand_l = base_pos + Vector2(-36.0 * s, -8.0 * s)
		hand_r = base_pos + Vector2(32.0 * s, -14.0 * s)
	elif pose == "right":
		hand_l = base_pos + Vector2(-28.0 * s, -6.0 * s)
		hand_r = base_pos + Vector2(38.0 * s, -14.0 * s)
	elif pose == "cheer":
		hand_l = base_pos + Vector2(-34.0 * s, -44.0 * s)
		hand_r = base_pos + Vector2(34.0 * s, -44.0 * s)

	draw_limb(canvas, sh_l, hand_l, 6.2 * s, Color.WHITE, INK, 3.6 * s)
	draw_limb(canvas, sh_r, hand_r, 6.2 * s, Color.WHITE, INK, 3.6 * s)
	draw_outlined_circle(canvas, hand_l, 6.8 * s, SKIN, INK, 3.2 * s)
	draw_outlined_circle(canvas, hand_r, 6.8 * s, SKIN, INK, 3.2 * s)

	var coat_pts := PackedVector2Array([
		base_pos + Vector2(-18.0 * s, -24.0 * s),
		base_pos + Vector2(18.0 * s, -24.0 * s),
		base_pos + Vector2(21.0 * s, 6.0 * s),
		base_pos + Vector2(-21.0 * s, 6.0 * s),
	])
	draw_outlined_polygon(canvas, coat_pts, Color.WHITE, INK, 3.8 * s)

	# Red neckerchief bow
	var tie_c := base_pos + Vector2(0.0, -20.0 * s)
	draw_outlined_ellipse(canvas, tie_c + Vector2(-6.0 * s, 5.0 * s), 7.5 * s, 4.8 * s, -0.5, Color("e62e3d"), INK, 2.8 * s)
	draw_outlined_ellipse(canvas, tie_c + Vector2(6.0 * s, 5.0 * s), 7.5 * s, 4.8 * s, 0.5, Color("e62e3d"), INK, 2.8 * s)
	draw_outlined_circle(canvas, tie_c + Vector2(0.0, 2.0 * s), 4.2 * s, Color("ff4757"), INK, 2.6 * s)

	# Brown Hair Buns & Top Hair Back-Layer (NO sharp triangle across forehead!)
	var hair_col := Color("593822")
	draw_outlined_circle(canvas, head_c + Vector2(-27.0 * s, -2.0 * s), 13.5 * s, hair_col, INK, 3.8 * s)
	draw_outlined_circle(canvas, head_c + Vector2(27.0 * s, -2.0 * s), 13.5 * s, hair_col, INK, 3.8 * s)
	draw_outlined_circle(canvas, head_c + Vector2(0.0, -4.0 * s), 29.0 * s, hair_col, INK, 3.8 * s)

	# Round Peach Head + Smooth Parted Bangs
	draw_outlined_circle(canvas, head_c, 27.0 * s, SKIN, INK, 3.8 * s)
	# Smooth parted bangs framing the left & right temple
	draw_outlined_ellipse(canvas, head_c + Vector2(-16.0 * s, -17.0 * s), 14.0 * s, 7.5 * s, -0.42, hair_col, INK, 3.0 * s)
	draw_outlined_ellipse(canvas, head_c + Vector2(16.0 * s, -17.0 * s), 14.0 * s, 7.5 * s, 0.42, hair_col, INK, 3.0 * s)

	# Seamless Two-Pass Puffy White Chef Toque Hat (Outline Pass -> Fill Pass -> Detail Pass!)
	var hat_y := head_c.y - 25.0 * s
	var puff_l := Vector2(head_c.x - 16.0 * s, hat_y - 16.0 * s)
	var puff_r := Vector2(head_c.x + 16.0 * s, hat_y - 16.0 * s)
	var puff_m := Vector2(head_c.x, hat_y - 21.0 * s)
	var band_rect := Rect2(head_c.x - 23.0 * s, hat_y - 10.0 * s, 46.0 * s, 15.0 * s)
	var hw := 3.8 * s
	# Pass 1: Black outer silhouette of toque
	canvas.draw_circle(puff_l, 15.0 * s + hw, INK)
	canvas.draw_circle(puff_r, 15.0 * s + hw, INK)
	canvas.draw_circle(puff_m, 18.0 * s + hw, INK)
	draw_outlined_box(canvas, band_rect.grow(hw * 0.5), INK, INK, 1.0, 5.0 * s)
	# Pass 2: Seamless white interior fill
	canvas.draw_circle(puff_l, 15.0 * s, Color.WHITE)
	canvas.draw_circle(puff_r, 15.0 * s, Color.WHITE)
	canvas.draw_circle(puff_m, 18.0 * s, Color.WHITE)
	draw_outlined_box(canvas, band_rect, Color.WHITE, Color.TRANSPARENT, 0.0, 4.0 * s)
	canvas.draw_line(Vector2(band_rect.position.x + 3.0 * s, band_rect.end.y), Vector2(band_rect.end.x - 3.0 * s, band_rect.end.y), INK, hw)
	# Pass 3: Subtle pleat ticks inside toque
	canvas.draw_line(Vector2(head_c.x - 6.0 * s, hat_y - 18.0 * s), Vector2(head_c.x - 4.0 * s, hat_y - 8.0 * s), INK, 2.6 * s, true)
	canvas.draw_line(Vector2(head_c.x + 6.0 * s, hat_y - 18.0 * s), Vector2(head_c.x + 4.0 * s, hat_y - 8.0 * s), INK, 2.6 * s, true)

	_draw_chef_face(canvas, head_c + Vector2(0.0, 4.0 * s), s, face_idx)

static func _draw_chef_face(canvas: CanvasItem, fc: Vector2, s: float, face_idx: int) -> void:
	canvas.draw_circle(fc + Vector2(-14.0 * s, 3.0 * s), 4.8 * s, SKIN_BLUSH)
	canvas.draw_circle(fc + Vector2(14.0 * s, 3.0 * s), 4.8 * s, SKIN_BLUSH)
	match face_idx:
		1:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 16.0 * s, 3.8 * s, "happy")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 14.0 * s, 10.0 * s, "open_d")
		2:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 16.0 * s, 3.8 * s, "surprised")
			draw_mouth(canvas, fc + Vector2(0.0, 8.0 * s), 12.0 * s, 9.0 * s, "open_o")
		3:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 4.0 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 16.0 * s, 11.0 * s, "open_d")
		4:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 17.0 * s, 3.8 * s, "dizzy")
			draw_mouth(canvas, fc + Vector2(0.0, 9.0 * s), 14.0 * s, 7.0 * s, "frown")
			draw_sweat_drop(canvas, fc + Vector2(22.0 * s, -16.0 * s), 0.78 * s)
		5:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 16.0 * s, 3.8 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 14.0 * s, 10.0 * s, "open_d")
			draw_sweat_drop(canvas, fc + Vector2(22.0 * s, -16.0 * s), 0.78 * s)
		_:
			draw_eyes(canvas, fc + Vector2(0.0, -2.0 * s), 16.0 * s, 4.0 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0.0, 7.0 * s), 15.0 * s, 11.0 * s, "open_d")

static func draw_title_host(canvas: CanvasItem, base_pos: Vector2, s: float, bob: float = 0.0) -> void:
	var head_c := base_pos + Vector2(0.0, -58.0 * s - bob * 0.4)
	var sh_l := base_pos + Vector2(-20.0 * s, -22.0 * s)
	var sh_r := base_pos + Vector2(20.0 * s, -22.0 * s)
	draw_limb(canvas, sh_l, base_pos + Vector2(-36.0 * s, 14.0 * s), 7.5 * s, Color("f0487e"), INK, 3.8 * s)
	draw_limb(canvas, sh_r, base_pos + Vector2(54.0 * s, -48.0 * s), 7.5 * s, Color("f0487e"), INK, 3.8 * s)
	draw_outlined_circle(canvas, base_pos + Vector2(-36.0 * s, 16.0 * s), 9.0 * s, Color.WHITE, INK, 3.5 * s)
	draw_outlined_circle(canvas, base_pos + Vector2(58.0 * s, -52.0 * s), 11.5 * s, Color.WHITE, INK, 3.6 * s)

	var suit_pts := PackedVector2Array([
		base_pos + Vector2(-22.0 * s, -30.0 * s),
		base_pos + Vector2(22.0 * s, -30.0 * s),
		base_pos + Vector2(28.0 * s, 20.0 * s),
		base_pos + Vector2(-28.0 * s, 20.0 * s),
	])
	draw_outlined_polygon(canvas, suit_pts, Color("f0487e"), INK, 4.0 * s)
	var shirt_v := PackedVector2Array([
		base_pos + Vector2(-10.0 * s, -28.0 * s),
		base_pos + Vector2(10.0 * s, -28.0 * s),
		base_pos + Vector2(0.0, -4.0 * s),
	])
	draw_outlined_polygon(canvas, shirt_v, Color.WHITE, INK, 3.2 * s)
	var bt_c := base_pos + Vector2(0.0, -24.0 * s)
	draw_outlined_polygon(canvas, PackedVector2Array([bt_c, bt_c + Vector2(-11.0 * s, -6.0 * s), bt_c + Vector2(-11.0 * s, 6.0 * s)]), INK, INK, 2.0 * s)
	draw_outlined_polygon(canvas, PackedVector2Array([bt_c, bt_c + Vector2(11.0 * s, -6.0 * s), bt_c + Vector2(11.0 * s, 6.0 * s)]), INK, INK, 2.0 * s)

	draw_outlined_circle(canvas, head_c, 32.0 * s, Color.WHITE, INK, 4.0 * s)
	draw_eyes(canvas, head_c + Vector2(2.0 * s, -2.0 * s), 16.0 * s, 4.2 * s, "normal")
	draw_mouth(canvas, head_c + Vector2(2.0 * s, 9.0 * s), 18.0 * s, 13.0 * s, "open_d")

	var crown_pts := PackedVector2Array([
		head_c + Vector2(-24.0 * s, -26.0 * s),
		head_c + Vector2(-28.0 * s, -64.0 * s),
		head_c + Vector2(22.0 * s, -68.0 * s),
		head_c + Vector2(22.0 * s, -28.0 * s),
	])
	draw_outlined_polygon(canvas, crown_pts, Color("f0487e"), INK, 4.0 * s)
	canvas.draw_line(head_c + Vector2(-23.0 * s, -32.0 * s), head_c + Vector2(21.0 * s, -35.0 * s), GOLD, 5.0 * s, true)
	draw_outlined_ellipse(canvas, head_c + Vector2(-2.0 * s, -26.0 * s), 36.0 * s, 8.5 * s, -0.08, Color("ff6b9d"), INK, 4.0 * s)

static func draw_orange_tv_buddy(canvas: CanvasItem, center_pos: Vector2, s: float, bob: float = 0.0) -> void:
	var c := center_pos + Vector2(0.0, -bob * 0.5)
	var rect := Rect2(c.x - 28.0 * s, c.y - 22.0 * s, 56.0 * s, 44.0 * s)
	canvas.draw_line(Vector2(c.x, rect.position.y), Vector2(c.x + 5.0 * s, rect.position.y - 14.0 * s), INK, 3.8 * s, true)
	draw_outlined_circle(canvas, Vector2(c.x + 5.0 * s, rect.position.y - 16.0 * s), 6.5 * s, Color("ff5c33"), INK, 3.2 * s)
	draw_outlined_box(canvas, rect, Color("f28b30"), INK, 4.2 * s, 8.0 * s)
	draw_eyes(canvas, c + Vector2(0.0, -1.0 * s), 16.0 * s, 3.6 * s, "normal")
	draw_mouth(canvas, c + Vector2(0.0, 7.0 * s), 10.0 * s, 6.0 * s, "smile")
