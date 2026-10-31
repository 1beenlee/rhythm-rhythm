extends RefCounted
class_name CartoonDraw

const INK := Color("191622")
const PAPER := Color("fffdf6")
const CREAM := Color("fdf2d0")
const GOLD := Color("ffe03d")
const MINT := Color("5ee6c5")
const CORAL := Color("ff5c77")
const SKY_BLUE := Color("68c8ff")
const HOT_PINK := Color("ff3b82")
const PURPLE := Color("8e44ec")
const SKIN := Color("ffe6c4")
const BLUSH := Color(1.0, 0.52, 0.58, 0.42)

static var _tex_cache: Dictionary = {}

static func load_png_texture(res_path: String) -> Texture2D:
	if _tex_cache.has(res_path):
		return _tex_cache[res_path]
	if FileAccess.file_exists(res_path):
		var raw := FileAccess.get_file_as_bytes(res_path)
		if raw.size() > 24:
			var img := Image.new()
			if img.load_png_from_buffer(raw) == OK:
				var tex := ImageTexture.create_from_image(img)
				_tex_cache[res_path] = tex
				return tex
	if ResourceLoader.exists(res_path):
		var loaded := ResourceLoader.load(res_path)
		if loaded is Texture2D:
			_tex_cache[res_path] = loaded
			return loaded
	return null

static func make_ellipse_points(center: Vector2, rx: float, ry: float, rot: float = 0.0, segments: int = 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		var lx := cos(a) * rx
		var ly := sin(a) * ry
		pts.append(center + Vector2(lx * cr - ly * sr, lx * sr + ly * cr))
	return pts

static func make_rounded_rect_points(rect: Rect2, radius: float = 12.0, corner_segs: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.48)
	if r <= 0.5:
		pts.append(rect.position)
		pts.append(Vector2(rect.end.x, rect.position.y))
		pts.append(rect.end)
		pts.append(Vector2(rect.position.x, rect.end.y))
		return pts
	var corners := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var start_angles := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for c_idx in range(4):
		var c: Vector2 = corners[c_idx]
		var sa: float = start_angles[c_idx]
		for s in range(corner_segs + 1):
			var a := sa + (PI * 0.5) * (float(s) / float(corner_segs))
			pts.append(c + Vector2(cos(a) * r, sin(a) * r))
	return pts

static func draw_outlined_polygon(canvas: CanvasItem, points: PackedVector2Array, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	if points.size() < 3:
		return
	canvas.draw_colored_polygon(points, fill_color)
	if outline_width > 0.0:
		var closed := PackedVector2Array(points)
		closed.append(points[0])
		canvas.draw_polyline(closed, outline_color, outline_width, true)

static func draw_outlined_circle(canvas: CanvasItem, center: Vector2, radius: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	if outline_width > 0.0:
		canvas.draw_circle(center, radius + outline_width * 0.5, outline_color)
	canvas.draw_circle(center, radius, fill_color)

static func draw_cel_circle(canvas: CanvasItem, center: Vector2, radius: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.2) -> void:
	if outline_width > 0.0:
		canvas.draw_circle(center, radius + outline_width * 0.5, outline_color)
	canvas.draw_circle(center, radius, fill_color)
	# Soft cel highlight at upper-left
	canvas.draw_circle(center + Vector2(-radius * 0.25, -radius * 0.28), radius * 0.45, Color(1, 1, 1, 0.16))

static func draw_outlined_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, rot: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	var pts := make_ellipse_points(center, rx, ry, rot, 32)
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_outlined_box(canvas: CanvasItem, rect: Rect2, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0, corner_radius: float = 10.0) -> void:
	var pts := make_rounded_rect_points(rect, corner_radius, 6)
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_limb(canvas: CanvasItem, p0: Vector2, p1: Vector2, radius: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	if outline_width > 0.0:
		canvas.draw_line(p0, p1, outline_color, (radius + outline_width) * 2.0, true)
		canvas.draw_circle(p0, radius + outline_width, outline_color)
		canvas.draw_circle(p1, radius + outline_width, outline_color)
	canvas.draw_line(p0, p1, fill_color, radius * 2.0, true)
	canvas.draw_circle(p0, radius, fill_color)
	canvas.draw_circle(p1, radius, fill_color)

static func draw_star(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, points_count: int = 5, rot: float = -PI * 0.5, fill_color: Color = GOLD, outline_color: Color = INK, outline_width: float = 3.5) -> void:
	var pts := PackedVector2Array()
	var total := points_count * 2
	for i in range(total):
		var a := rot + TAU * float(i) / float(total)
		var r := outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_neon_star_outline(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, points_count: int, rot: float, neon_color: Color, width: float = 4.5) -> void:
	var pts := PackedVector2Array()
	var total := points_count * 2
	for i in range(total):
		var a := rot + TAU * float(i) / float(total)
		var r := outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2(cos(a) * r, sin(a) * r))
	pts.append(pts[0])
	canvas.draw_polyline(pts, Color(neon_color.r, neon_color.g, neon_color.b, 0.35), width * 2.2, true)
	canvas.draw_polyline(pts, neon_color, width, true)

static func draw_comic_burst(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, spikes: int = 12, rot: float = 0.0, fill_color: Color = GOLD, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	draw_star(canvas, center, outer_r, inner_r, spikes, rot, fill_color, outline_color, outline_width)

static func draw_jagged_burst_box(canvas: CanvasItem, center: Vector2, rx: float, ry: float, spikes: int = 14, fill_color: Color = PAPER, inner_color: Color = GOLD, outline_color: Color = INK, outline_width: float = 4.5) -> void:
	var pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	var total := spikes * 2
	for i in range(total):
		var a := -0.12 + TAU * float(i) / float(total)
		var mult := 1.08 if (i % 2 == 0) else 0.78
		if i % 4 == 0:
			mult = 1.18
		pts.append(center + Vector2(cos(a) * rx * mult, sin(a) * ry * mult))
		inner_pts.append(center + Vector2(cos(a) * rx * mult * 0.82, sin(a) * ry * mult * 0.82))
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)
	canvas.draw_colored_polygon(inner_pts, Color(inner_color.r, inner_color.g, inner_color.b, 0.45))

static func draw_heart(canvas: CanvasItem, center: Vector2, size_r: float, fill_color: Color = HOT_PINK, outline_color: Color = INK, outline_width: float = 3.0) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(center + Vector2(x, y) * (size_r / 16.0))
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_sweat_drop(canvas: CanvasItem, pos: Vector2, scale_val: float = 1.0, outline_color: Color = INK) -> void:
	var r := 9.0 * scale_val
	var pts := PackedVector2Array([
		pos + Vector2(0, -r * 1.65),
		pos + Vector2(r * 0.92, -r * 0.15),
		pos + Vector2(r, r * 0.55),
		pos + Vector2(0, r * 1.15),
		pos + Vector2(-r, r * 0.55),
		pos + Vector2(-r * 0.92, -r * 0.15),
	])
	draw_outlined_polygon(canvas, pts, Color("58dbff"), outline_color, 3.0 * scale_val)
	canvas.draw_circle(pos + Vector2(-r * 0.25, r * 0.2), r * 0.25, Color.WHITE)

static func draw_music_note(canvas: CanvasItem, pos: Vector2, scale_val: float = 1.0, fill_color: Color = GOLD, outline_color: Color = INK) -> void:
	var s := scale_val
	var head := pos + Vector2(-4.0 * s, 8.0 * s)
	var top := pos + Vector2(3.0 * s, -15.0 * s)
	var flag_end := pos + Vector2(14.0 * s, -8.0 * s)
	canvas.draw_line(head + Vector2(5.0 * s, 0.0), top, outline_color, 7.5 * s, true)
	canvas.draw_line(top, flag_end, outline_color, 7.5 * s, true)
	draw_outlined_ellipse(canvas, head, 8.0 * s, 6.0 * s, -0.35, fill_color, outline_color, 3.2 * s)
	canvas.draw_line(head + Vector2(5.0 * s, 0.0), top, fill_color, 3.6 * s, true)
	canvas.draw_line(top, flag_end, fill_color, 3.6 * s, true)

static func draw_cheeks(canvas: CanvasItem, center: Vector2, spacing: float, rx: float = 7.0, ry: float = 4.5) -> void:
	draw_outlined_ellipse(canvas, center + Vector2(-spacing * 0.5, 0.0), rx, ry, 0.0, BLUSH, Color.TRANSPARENT, 0.0)
	draw_outlined_ellipse(canvas, center + Vector2(spacing * 0.5, 0.0), rx, ry, 0.0, BLUSH, Color.TRANSPARENT, 0.0)

static func draw_eyes(canvas: CanvasItem, center: Vector2, spacing: float, radius: float, style: String = "normal", look_offset: Vector2 = Vector2.ZERO, outline_color: Color = INK) -> void:
	var left_pos := center + Vector2(-spacing * 0.5, 0.0)
	var right_pos := center + Vector2(spacing * 0.5, 0.0)
	for eye_pos in [left_pos, right_pos]:
		var ep: Vector2 = eye_pos
		var is_left := ep.x < center.x
		match style:
			"happy":
				canvas.draw_arc(ep + Vector2(0, radius * 0.35), radius * 1.15, PI * 1.12, PI * 1.88, 14, outline_color, maxf(3.4, radius * 0.55), true)
			"closed_down":
				canvas.draw_arc(ep + Vector2(0, -radius * 0.25), radius * 1.15, PI * 0.12, PI * 0.88, 14, outline_color, maxf(3.4, radius * 0.55), true)
			"squint":
				var dir: float = 1.0 if is_left else -1.0
				canvas.draw_line(ep + Vector2(-radius * 1.1 * dir, -radius * 0.72), ep + Vector2(radius * 0.65 * dir, 0.0), outline_color, maxf(3.4, radius * 0.52), true)
				canvas.draw_line(ep + Vector2(radius * 0.65 * dir, 0.0), ep + Vector2(-radius * 1.1 * dir, radius * 0.72), outline_color, maxf(3.4, radius * 0.52), true)
			"focused":
				canvas.draw_circle(ep + look_offset, radius, outline_color)
				var b_dir := 1.0 if is_left else -1.0
				canvas.draw_line(ep + Vector2(-radius * 1.2, -radius * 1.65 - b_dir * 1.5), ep + Vector2(radius * 1.2, -radius * 1.25 + b_dir * 2.5), outline_color, maxf(3.0, radius * 0.45), true)
			"surprised":
				canvas.draw_circle(ep + look_offset, radius * 0.92, outline_color)
				canvas.draw_arc(ep + Vector2(0, -radius * 1.3), radius * 1.1, PI * 1.15, PI * 1.85, 10, outline_color, maxf(2.8, radius * 0.42), true)
			"dizzy":
				canvas.draw_line(ep + Vector2(-radius, -radius), ep + Vector2(radius, radius), outline_color, maxf(3.2, radius * 0.48), true)
				canvas.draw_line(ep + Vector2(radius, -radius), ep + Vector2(-radius, radius), outline_color, maxf(3.2, radius * 0.48), true)
			"wide":
				draw_outlined_circle(canvas, ep, radius * 1.45, Color.WHITE, outline_color, 3.2)
				canvas.draw_circle(ep + look_offset * 0.5, radius * 0.55, outline_color)
			_:
				draw_outlined_ellipse(canvas, ep + look_offset, radius * 0.92, radius * 1.18, 0.0, outline_color, outline_color, 0.0)
				canvas.draw_circle(ep + look_offset + Vector2(-radius * 0.26, -radius * 0.34), radius * 0.30, Color.WHITE)

static func draw_mouth(canvas: CanvasItem, center: Vector2, width: float, height: float, style: String = "smile", outline_color: Color = INK) -> void:
	match style:
		"big_grin", "open_d":
			var pts := PackedVector2Array([
				center + Vector2(-width * 0.52, -height * 0.18),
				center + Vector2(width * 0.52, -height * 0.18),
				center + Vector2(width * 0.44, height * 0.55),
				center + Vector2(0.0, height * 0.88),
				center + Vector2(-width * 0.44, height * 0.55),
			])
			draw_outlined_polygon(canvas, pts, Color("9e1c34"), outline_color, 3.4)
			var tongue := PackedVector2Array([
				center + Vector2(-width * 0.30, height * 0.42),
				center + Vector2(0.0, height * 0.25),
				center + Vector2(width * 0.30, height * 0.42),
				center + Vector2(0.0, height * 0.80),
			])
			canvas.draw_colored_polygon(tongue, Color("ff758f"))
			draw_outlined_polygon(canvas, pts, Color.TRANSPARENT, outline_color, 3.4)
		"sing_tall":
			var pts := PackedVector2Array([
				center + Vector2(-width * 0.32, -height * 0.55),
				center + Vector2(width * 0.38, -height * 0.58),
				center + Vector2(width * 0.32, height * 0.55),
				center + Vector2(0.0, height * 0.82),
				center + Vector2(-width * 0.32, height * 0.48),
			])
			draw_outlined_polygon(canvas, pts, Color("8a1c36"), outline_color, 3.5)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.34), width * 0.22, height * 0.32, 0.0, Color("ff7a94"), outline_color, 0.0)
			draw_outlined_polygon(canvas, pts, Color.TRANSPARENT, outline_color, 3.5)
		"open_o":
			draw_outlined_ellipse(canvas, center, width * 0.34, height * 0.56, 0.0, Color("9e1c34"), outline_color, 3.4)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.18), width * 0.20, height * 0.22, 0.0, Color("ff758f"), outline_color, 0.0)
		"open_a":
			draw_outlined_ellipse(canvas, center, width * 0.48, height * 0.65, 0.0, Color("9e1c34"), outline_color, 3.5)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.22), width * 0.30, height * 0.26, 0.0, Color("ff758f"), outline_color, 0.0)
		"flat":
			canvas.draw_line(center + Vector2(-width * 0.36, 0.0), center + Vector2(width * 0.36, 0.0), outline_color, 3.5, true)
		"frown":
			canvas.draw_arc(center + Vector2(0.0, height * 0.55), width * 0.44, PI * 1.15, PI * 1.85, 12, outline_color, 3.5, true)
		_:
			canvas.draw_arc(center + Vector2(0.0, -height * 0.18), width * 0.44, 0.18, PI - 0.18, 12, outline_color, 3.5, true)

static func draw_outlined_text(canvas: CanvasItem, pos: Vector2, text: String, width: int, font_size: int, fill_color: Color, outline_color: Color = INK, outline_px: float = 3.2, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	var offsets := [
		Vector2(-outline_px, 0.0), Vector2(outline_px, 0.0),
		Vector2(0.0, -outline_px), Vector2(0.0, outline_px),
		Vector2(-outline_px * 0.72, -outline_px * 0.72), Vector2(outline_px * 0.72, -outline_px * 0.72),
		Vector2(-outline_px * 0.72, outline_px * 0.72), Vector2(outline_px * 0.72, outline_px * 0.72),
	]
	for off in offsets:
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
	var center := rect.get_center()
	var base_x := clampf(tail_target.x, rect.position.x + 26.0, rect.end.x - 26.0)
	var base_y := rect.end.y - 4.0 if tail_target.y >= center.y else rect.position.y + 4.0
	var tri := PackedVector2Array([
		Vector2(base_x - 12.0, base_y),
		Vector2(base_x + 12.0, base_y),
		tail_target,
	])
	draw_outlined_box(canvas, rect, bg_color, INK, 4.2, minf(rect.size.y * 0.46, 26.0))
	draw_outlined_polygon(canvas, tri, bg_color, INK, 4.0)
	# Cover inner seam of speech bubble tail
	canvas.draw_line(Vector2(base_x - 10.0, base_y), Vector2(base_x + 10.0, base_y), bg_color, 5.0)
	if text != "":
		draw_outlined_text(canvas, Vector2(rect.position.x + 6.0, rect.position.y + rect.size.y * 0.5 + float(font_size) * 0.35), text, int(rect.size.x - 12.0), font_size, text_color, PAPER, 0.0)

static func draw_you_badge(canvas: CanvasItem, anchor_pos: Vector2, label_text: String = "YOU", above: bool = true) -> void:
	var box_w := 58.0
	var box_h := 24.0
	var box_pos := anchor_pos + Vector2(-box_w * 0.5, -box_h - 10.0 if above else 10.0)
	draw_outlined_box(canvas, Rect2(box_pos, Vector2(box_w, box_h)), PAPER, INK, 3.2, 8.0)
	draw_outlined_text(canvas, box_pos + Vector2(0.0, 17.5), label_text, int(box_w), 14, INK, PAPER, 0.0)

# =============================================================================
# SHARED STAGE TOP HUD BAR (Panels 03, 04, 05, 06, 07, 08)
# =============================================================================
static func draw_stage_hud_banner(canvas: CanvasItem, w: float, stage_title: String, beat: float, score_val: int, combo_val: int, active_dots: int = -1, dot_color: Color = GOLD) -> void:
	var is_narrow := w < 520.0
	var bar_h := 48.0 if is_narrow else 56.0
	var bar_rect := Rect2(8.0, 6.0, w - 16.0, bar_h)
	draw_outlined_box(canvas, bar_rect, Color("1b1f36"), INK, 4.0, 14.0)
	# Subtle bottom accent line
	canvas.draw_line(Vector2(bar_rect.position.x + 12.0, bar_rect.end.y - 2.0), Vector2(bar_rect.end.x - 12.0, bar_rect.end.y - 2.0), Color(1, 1, 1, 0.16), 2.0)

	# Left: Yellow musical note + Stage Name
	var note_pos := Vector2(bar_rect.position.x + (22.0 if is_narrow else 28.0), bar_rect.get_center().y + 2.0)
	draw_music_note(canvas, note_pos, 0.85 if is_narrow else 1.0, GOLD, INK)
	var title_fs := 16 if is_narrow else 22
	draw_outlined_text(canvas, Vector2(bar_rect.position.x + (40.0 if is_narrow else 52.0), bar_rect.get_center().y + float(title_fs) * 0.36), stage_title, int(w * 0.42), title_fs, PAPER, INK, 2.8, HORIZONTAL_ALIGNMENT_LEFT)

	# Center: 4-Beat Phrase Dots (o-o-o-o) matching Panels 03-08!
	var dot_spacing := 18.0 if is_narrow else 24.0
	var dots_cx := w * (0.48 if is_narrow else 0.53)
	var dots_cy := bar_rect.get_center().y + 4.0
	canvas.draw_line(Vector2(dots_cx - dot_spacing * 1.5, dots_cy), Vector2(dots_cx + dot_spacing * 1.5, dots_cy), Color(1, 1, 1, 0.45), 3.0)
	var lit_count := active_dots if active_dots >= 0 else (int(floorf(maxf(0.0, beat))) % 4 + 1)
	for di in range(4):
		var dx := dots_cx + (float(di) - 1.5) * dot_spacing
		var is_lit := di < lit_count
		var c := dot_color if is_lit else Color("68708f")
		draw_outlined_circle(canvas, Vector2(dx, dots_cy), 6.5 if is_narrow else 8.0, c, INK, 2.8)
		if is_lit:
			canvas.draw_circle(Vector2(dx - 1.5, dots_cy - 1.5), 2.5, Color.WHITE)

	# Right: SCORE 001200 & COMBO 4 (leave 96px on far right for Pause button)
	var right_w := 130 if is_narrow else 175
	var right_x := bar_rect.end.x - float(right_w) - (52.0 if is_narrow else 98.0)
	var s_fs := 13 if is_narrow else 17
	var c_fs := 12 if is_narrow else 15
	draw_outlined_text(canvas, Vector2(right_x, bar_rect.position.y + (20.0 if is_narrow else 23.0)), "SCORE %06d" % score_val, right_w, s_fs, PAPER, INK, 2.5, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_outlined_text(canvas, Vector2(right_x, bar_rect.position.y + (38.0 if is_narrow else 44.0)), "COMBO %d" % combo_val, right_w, c_fs, GOLD if combo_val > 0 else PAPER, INK, 2.5, HORIZONTAL_ALIGNMENT_RIGHT)

# =============================================================================
# 1. BEAT FACTORY WORKER CHARACTER RIG (Panels 02, 03, 04, 09, 10)
# =============================================================================
static func draw_factory_worker(canvas: CanvasItem, base_pos: Vector2, s: float = 1.0, pose: String = "idle", face_idx: int = 0, with_lever: bool = true) -> void:
	# Exact design from Panel 10: Yellow hard hat with red stripe, brown ponytail bun at back-left,
	# round peach head, white long-sleeve shirt, blue denim overalls with 2 yellow buttons, red-knob lever!
	var body_tilt := -0.10 if pose == "hit" else 0.0
	var body_center := base_pos + Vector2(-8.0 * s if pose == "hit" else 0.0, -34.0 * s)

	# Legs (when visible on full-body character sheet / results)
	if not with_lever:
		draw_limb(canvas, base_pos + Vector2(-12.0 * s, -14.0 * s), base_pos + Vector2(-14.0 * s, 4.0 * s), 7.5 * s, Color("245ca6"), INK, 3.8 * s)
		draw_limb(canvas, base_pos + Vector2(12.0 * s, -14.0 * s), base_pos + Vector2(14.0 * s, 4.0 * s), 7.5 * s, Color("245ca6"), INK, 3.8 * s)
		draw_outlined_ellipse(canvas, base_pos + Vector2(-15.0 * s, 8.0 * s), 11.0 * s, 6.0 * s, 0.0, INK, INK, 1.0)
		draw_outlined_ellipse(canvas, base_pos + Vector2(15.0 * s, 8.0 * s), 11.0 * s, 6.0 * s, 0.0, INK, INK, 1.0)

	# Arms behind torso
	var sh_l := body_center + Vector2(-20.0 * s, -18.0 * s)
	var sh_r := body_center + Vector2(20.0 * s, -18.0 * s)
	if pose == "cheer":
		draw_limb(canvas, sh_l, sh_l + Vector2(-26.0 * s, -34.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_l + Vector2(-28.0 * s, -36.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(26.0 * s, -34.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_r + Vector2(28.0 * s, -36.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)
	elif pose == "hit":
		# Left arm slams down with comic yellow speed wedges (Panel 04!)
		var slam_hand := body_center + Vector2(-52.0 * s, 18.0 * s)
		# White impact flash behind arm
		draw_comic_burst(canvas, body_center + Vector2(-38.0 * s, -4.0 * s), 36.0 * s, 20.0 * s, 8, 0.2, Color.WHITE, Color(1, 1, 1, 0.0), 0.0)
		draw_limb(canvas, sh_l, slam_hand, 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, slam_hand, 8.0 * s, SKIN, INK, 3.5 * s)
		# Two bright yellow comic impact wedges from Panel 04
		var w1 := PackedVector2Array([
			body_center + Vector2(-28.0 * s, -4.0 * s),
			body_center + Vector2(-62.0 * s, -18.0 * s),
			body_center + Vector2(-54.0 * s, -30.0 * s),
		])
		var w2 := PackedVector2Array([
			body_center + Vector2(-22.0 * s, -14.0 * s),
			body_center + Vector2(-42.0 * s, -44.0 * s),
			body_center + Vector2(-28.0 * s, -50.0 * s),
		])
		draw_outlined_polygon(canvas, w1, GOLD, INK, 3.5 * s)
		draw_outlined_polygon(canvas, w2, GOLD, INK, 3.5 * s)
		# Right arm down at lever
		draw_limb(canvas, sh_r, body_center + Vector2(26.0 * s, 14.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, body_center + Vector2(26.0 * s, 16.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)
	elif pose == "ready":
		draw_limb(canvas, sh_l, body_center + Vector2(-28.0 * s, 14.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, body_center + Vector2(-28.0 * s, 16.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)
		# Right arm reaching up to hold the red lever knob (Panel 03 & Panel 10 Ready!)
		var grip_pt := base_pos + Vector2(42.0 * s, -54.0 * s)
		draw_limb(canvas, sh_r, grip_pt, 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, grip_pt, 7.5 * s, SKIN, INK, 3.5 * s)
	else:
		draw_limb(canvas, sh_l, body_center + Vector2(-26.0 * s, 12.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, body_center + Vector2(-26.0 * s, 14.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, body_center + Vector2(26.0 * s, 12.0 * s), 6.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, body_center + Vector2(26.0 * s, 14.0 * s), 7.5 * s, SKIN, INK, 3.5 * s)

	# Torso: White shirt collar + Blue denim overalls with 2 yellow buttons
	var torso_rect := Rect2(body_center.x - 22.0 * s, body_center.y - 24.0 * s, 44.0 * s, 48.0 * s)
	draw_outlined_box(canvas, torso_rect, Color.WHITE, INK, 4.0 * s, 10.0 * s)
	var bib_rect := Rect2(body_center.x - 20.0 * s, body_center.y - 12.0 * s, 40.0 * s, 36.0 * s)
	draw_outlined_box(canvas, bib_rect, Color("245ca6"), INK, 3.8 * s, 6.0 * s)
	# Overall straps & yellow buttons
	draw_outlined_box(canvas, Rect2(body_center.x - 16.0 * s, body_center.y - 24.0 * s, 8.0 * s, 16.0 * s), Color("245ca6"), INK, 3.2 * s, 2.0)
	draw_outlined_box(canvas, Rect2(body_center.x + 8.0 * s, body_center.y - 24.0 * s, 8.0 * s, 16.0 * s), Color("245ca6"), INK, 3.2 * s, 2.0)
	draw_outlined_circle(canvas, body_center + Vector2(-12.0 * s, -9.0 * s), 3.6 * s, GOLD, INK, 2.0 * s)
	draw_outlined_circle(canvas, body_center + Vector2(12.0 * s, -9.0 * s), 3.6 * s, GOLD, INK, 2.0 * s)

	# Head + Brown Hair Bun + Yellow Safety Hard Hat
	var head_center := body_center + Vector2(0.0, -56.0 * s)
	# Brown hair bun peeking out on the left-back of helmet (Panels 03, 10)
	draw_outlined_circle(canvas, head_center + Vector2(-34.0 * s, 4.0 * s), 15.0 * s, Color("5a3821"), INK, 4.0 * s)
	# Round peach head
	draw_cel_circle(canvas, head_center, 34.0 * s, SKIN, INK, 4.2 * s)
	# Dark brown side hair framing forehead
	canvas.draw_arc(head_center + Vector2(0, -4.0 * s), 31.0 * s, PI * 0.88, PI * 1.18, 10, Color("3a2314"), 7.0 * s, true)
	draw_cheeks(canvas, head_center + Vector2(2.0 * s, 8.0 * s), 38.0 * s, 6.5 * s, 4.0 * s)

	# Face Expression (0..5 from Panel 10)
	_draw_worker_face(canvas, head_center + Vector2(3.0 * s, 2.0 * s), s, face_idx)

	# Yellow Safety Hard Hat (dome + front brim + red stripe)
	var hat_center := head_center + Vector2(0.0, -16.0 * s)
	var dome_pts := PackedVector2Array()
	for i in range(19):
		var a := PI + PI * float(i) / 18.0 - 0.08 + body_tilt
		dome_pts.append(hat_center + Vector2(cos(a) * 38.0 * s, sin(a) * 28.0 * s))
	draw_outlined_polygon(canvas, dome_pts, Color("ffe033"), INK, 4.2 * s)
	# Red safety stripe on front of helmet
	canvas.draw_line(hat_center + Vector2(-14.0 * s, -8.0 * s), hat_center + Vector2(18.0 * s, -11.0 * s), Color("e84828"), 3.8 * s, true)
	# Helmet brim
	var brim_pts := PackedVector2Array([
		hat_center + Vector2(-42.0 * s, 4.0 * s),
		hat_center + Vector2(44.0 * s, -2.0 * s),
		hat_center + Vector2(42.0 * s, 7.0 * s),
		hat_center + Vector2(-40.0 * s, 11.0 * s),
	])
	draw_outlined_polygon(canvas, brim_pts, Color("ffd21f"), INK, 4.0 * s)

	# Attention rays above helmet in Ready pose (Panel 10 Ready!)
	if pose == "ready":
		for ri in range(3):
			var ra := -PI * 0.55 + float(ri - 1) * 0.28
			var r0 := hat_center + Vector2(cos(ra), sin(ra)) * 36.0 * s
			var r1 := hat_center + Vector2(cos(ra), sin(ra)) * 52.0 * s
			canvas.draw_line(r0, r1, Color("ff8c24"), 4.5 * s, true)

	# Lever Box on the right side of the Worker (Panels 02, 03, 04, 10)
	if with_lever:
		var lbox_x := base_pos.x + 48.0 * s
		var lbox_y := base_pos.y
		var knob_pos := Vector2(lbox_x + 12.0 * s, lbox_y - 68.0 * s) if pose != "hit" else Vector2(lbox_x + 18.0 * s, lbox_y - 42.0 * s)
		if pose == "ready":
			knob_pos = Vector2(lbox_x - 2.0 * s, lbox_y - 66.0 * s)
		# Lever shaft
		draw_limb(canvas, Vector2(lbox_x, lbox_y - 24.0 * s), knob_pos, 5.5 * s, Color("9aa2b4"), INK, 3.8 * s)
		# Red Ball Knob
		draw_cel_circle(canvas, knob_pos, 14.0 * s, Color("eb3442"), INK, 4.0 * s)
		# Grey trapezoid lever housing box
		var housing := PackedVector2Array([
			Vector2(lbox_x - 22.0 * s, lbox_y - 28.0 * s),
			Vector2(lbox_x + 22.0 * s, lbox_y - 28.0 * s),
			Vector2(lbox_x + 30.0 * s, lbox_y),
			Vector2(lbox_x - 30.0 * s, lbox_y),
		])
		draw_outlined_polygon(canvas, housing, Color("666c7e"), INK, 4.2 * s)

static func _draw_worker_face(canvas: CanvasItem, fc: Vector2, s: float, face_idx: int) -> void:
	match face_idx:
		1: # Focused (brows angled, flat mouth)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 18.0 * s, 4.0 * s, "focused")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 14.0 * s, 6.0 * s, "flat")
		2: # Surprised ('o' mouth)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 18.0 * s, 4.0 * s, "surprised")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 14.0 * s, 12.0 * s, "open_o")
		3: # Laughing '> <' + big open D mouth (Panel 04 Perfect!)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 5.5 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0, 9.0 * s), 22.0 * s, 15.0 * s, "open_d")
		4: # Big Cheer smile (dot eyes + open D mouth)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 18.0 * s, 4.2 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0, 9.0 * s), 20.0 * s, 14.0 * s, "open_d")
		5: # Sweat drop miss (Panel 10 Face #6)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 18.0 * s, 4.0 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 16.0 * s, 11.0 * s, "open_d")
			draw_sweat_drop(canvas, fc + Vector2(28.0 * s, -12.0 * s), 0.95 * s)
		_: # Default gentle smile (Panel 10 Face #1)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 18.0 * s, 4.2 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 14.0 * s, 8.0 * s, "smile")

# =============================================================================
# 2. ECHO PLANET ALIEN & ASTRONAUT DUO RIGS (Panels 01, 02, 05, 06, 09, 11)
# =============================================================================
static func draw_echo_alien(canvas: CanvasItem, base_pos: Vector2, s: float = 1.0, pose: String = "idle", face_idx: int = 0, full_body: bool = true) -> void:
	# Exact design from Panels 05, 06, 11: Smooth sky-cyan alien with round head,
	# soft pale cream-mint lower torso, single antenna stem with glowing orb!
	var body_col := Color("82cfe6")
	var belly_col := Color("d6f2e4")
	var torso_c := base_pos + Vector2(0.0, -32.0 * s)

	# Arms
	var sh_l := torso_c + Vector2(-16.0 * s, -18.0 * s)
	var sh_r := torso_c + Vector2(16.0 * s, -18.0 * s)
	if pose == "success" or pose == "cheer":
		draw_limb(canvas, sh_l, sh_l + Vector2(-34.0 * s, -24.0 * s), 7.5 * s, body_col, INK, 4.0 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(34.0 * s, -24.0 * s), 7.5 * s, body_col, INK, 4.0 * s)
	elif pose == "sing":
		draw_limb(canvas, sh_l, sh_l + Vector2(-28.0 * s, -2.0 * s), 7.5 * s, body_col, INK, 4.0 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(32.0 * s, -10.0 * s), 7.5 * s, body_col, INK, 4.0 * s)
	else:
		draw_limb(canvas, sh_l, sh_l + Vector2(-16.0 * s, 16.0 * s), 6.5 * s, body_col, INK, 3.8 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(16.0 * s, 16.0 * s), 6.5 * s, body_col, INK, 3.8 * s)

	# Torso & Stubby Legs
	if full_body:
		draw_limb(canvas, base_pos + Vector2(-9.0 * s, -18.0 * s), base_pos + Vector2(-10.0 * s, 2.0 * s), 7.5 * s, belly_col, INK, 3.8 * s)
		draw_limb(canvas, base_pos + Vector2(9.0 * s, -18.0 * s), base_pos + Vector2(10.0 * s, 2.0 * s), 7.5 * s, belly_col, INK, 3.8 * s)
	var body_pts := PackedVector2Array([
		torso_c + Vector2(-17.0 * s, -24.0 * s),
		torso_c + Vector2(17.0 * s, -24.0 * s),
		torso_c + Vector2(20.0 * s, 22.0 * s),
		torso_c + Vector2(-20.0 * s, 22.0 * s),
	])
	draw_outlined_polygon(canvas, body_pts, body_col, INK, 4.2 * s)
	canvas.draw_circle(torso_c + Vector2(0, 8.0 * s), 14.0 * s, Color(belly_col.r, belly_col.g, belly_col.b, 0.65))

	# Large Round Sky-Cyan Head
	var head_c := torso_c + Vector2(0.0, -56.0 * s)
	var head_rot := -0.10 if pose == "sing" else 0.0
	draw_outlined_ellipse(canvas, head_c, 44.0 * s, 36.0 * s, head_rot, body_col, INK, 4.4 * s)
	# Cel highlight on upper-left of head
	draw_outlined_ellipse(canvas, head_c + Vector2(-14.0 * s, -12.0 * s), 16.0 * s, 10.0 * s, -0.3, Color(1, 1, 1, 0.22), Color.TRANSPARENT, 0.0)

	# Antenna stem & glowing orb
	var ant_base := head_c + Vector2(-4.0 * s, -34.0 * s)
	var ant_tip := ant_base + Vector2(-4.0 * s, -22.0 * s)
	canvas.draw_line(ant_base, ant_tip, INK, 4.5 * s, true)
	var orb_lit := (pose == "sing" or pose == "success" or pose == "cheer" or face_idx == 5)
	var orb_col := GOLD if orb_lit else Color("5ce1e6")
	draw_cel_circle(canvas, ant_tip, 11.0 * s, orb_col, INK, 3.8 * s)

	# Radial burst rays around antenna / cheek when Singing or Success (Panels 05, 06, 11!)
	if pose == "sing":
		for wi in range(3):
			var arc_r := (26.0 + float(wi) * 15.0) * s
			canvas.draw_arc(head_c + Vector2(36.0 * s, -2.0 * s), arc_r, -0.58, 0.58, 16, GOLD, 5.0 * s, true)
	elif pose == "success":
		for ri in range(3):
			var ra := -0.45 + float(ri) * 0.36
			var p0 := head_c + Vector2(46.0 * s, -18.0 * s) + Vector2(cos(ra), sin(ra)) * 10.0 * s
			var p1 := head_c + Vector2(46.0 * s, -18.0 * s) + Vector2(cos(ra), sin(ra)) * 34.0 * s
			canvas.draw_line(p0, p1, GOLD, 5.0 * s, true)

	# Alien Face Expression (0..5 from Panel 11)
	var fc := head_c + Vector2(4.0 * s, 2.0 * s)
	match face_idx:
		1: # Sing (Call) - closed downward eyes + tall singing mouth (Panel 05 & 11)
			draw_eyes(canvas, fc + Vector2(2.0 * s, -6.0 * s), 22.0 * s, 5.5 * s, "closed_down")
			draw_mouth(canvas, fc + Vector2(6.0 * s, 10.0 * s), 20.0 * s, 22.0 * s, "sing_tall")
		2: # Listen - closed downward peaceful eyes + gentle smile (Panel 11 Listen)
			draw_eyes(canvas, fc + Vector2(0, -4.0 * s), 22.0 * s, 5.5 * s, "closed_down")
			draw_mouth(canvas, fc + Vector2(0, 8.0 * s), 12.0 * s, 7.0 * s, "smile")
		3: # Success - happy upward arched eyes + big open D mouth (Panel 06 & 11 Success)
			draw_eyes(canvas, fc + Vector2(0, -5.0 * s), 22.0 * s, 6.0 * s, "happy")
			draw_mouth(canvas, fc + Vector2(2.0 * s, 10.0 * s), 20.0 * s, 18.0 * s, "open_d")
		4: # '> <' laugh (Panel 11 Face #4)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 22.0 * s, 5.5 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 16.0 * s, 14.0 * s, "open_d")
		5: # Surprised 'o' mouth / wide eyes (Panel 11 Face #1/#5)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 22.0 * s, 5.5 * s, "wide")
			draw_mouth(canvas, fc + Vector2(0, 11.0 * s), 12.0 * s, 11.0 * s, "open_o")
		_: # Idle (big oval black eyes + cute small smile)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 5.2 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0, 8.0 * s), 11.0 * s, 6.0 * s, "smile")

static func draw_echo_astronaut(canvas: CanvasItem, base_pos: Vector2, s: float = 1.0, pose: String = "listen") -> void:
	# Exact design from Panels 05 & 06: White spacesuit & round white helmet,
	# dark indigo upper visor band, rosy cheeks, waving in Listen and cheering in Response!
	var torso_c := base_pos + Vector2(0.0, -26.0 * s)
	var sh_l := torso_c + Vector2(-16.0 * s, -14.0 * s)
	var sh_r := torso_c + Vector2(16.0 * s, -14.0 * s)
	if pose == "cheer" or pose == "response":
		draw_limb(canvas, sh_l, sh_l + Vector2(-20.0 * s, -24.0 * s), 6.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(20.0 * s, -24.0 * s), 6.0 * s, Color.WHITE, INK, 3.8 * s)
	else:
		draw_limb(canvas, sh_l, sh_l + Vector2(-18.0 * s, -12.0 * s), 6.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(14.0 * s, 10.0 * s), 6.0 * s, Color.WHITE, INK, 3.8 * s)

	# White spacesuit torso
	draw_outlined_box(canvas, Rect2(torso_c.x - 18.0 * s, torso_c.y - 20.0 * s, 36.0 * s, 44.0 * s), Color.WHITE, INK, 4.0 * s, 8.0 * s)
	canvas.draw_line(Vector2(torso_c.x - 16.0 * s, torso_c.y + 4.0 * s), Vector2(torso_c.x + 16.0 * s, torso_c.y + 4.0 * s), INK, 3.5 * s)
	draw_outlined_box(canvas, Rect2(torso_c.x - 8.0 * s, torso_c.y - 14.0 * s, 16.0 * s, 10.0 * s), Color("d8e2f5"), INK, 2.8 * s, 3.0)

	# Round White Space Helmet
	var head_c := torso_c + Vector2(0.0, -48.0 * s)
	draw_outlined_circle(canvas, head_c, 34.0 * s, Color.WHITE, INK, 4.2 * s)
	# Inner helmet opening (purple visor top + peach face bottom)
	draw_outlined_circle(canvas, head_c + Vector2(0, 2.0 * s), 25.0 * s, SKIN, INK, 3.6 * s)
	# Dark purple upper visor forehead cap inside helmet
	var visor_pts := PackedVector2Array()
	for i in range(13):
		var a := PI + PI * float(i) / 12.0
		visor_pts.append(head_c + Vector2(cos(a) * 23.0 * s, sin(a) * 19.0 * s - 3.0 * s))
	draw_outlined_polygon(canvas, visor_pts, Color("493b78"), INK, 3.2 * s)
	# Rosy cheeks & cute eyes/smile
	draw_cheeks(canvas, head_c + Vector2(0, 9.0 * s), 28.0 * s, 5.5 * s, 3.5 * s)
	var e_style := "happy" if pose == "cheer" else ("dizzy" if pose == "miss" else "normal")
	var m_style := "open_d" if pose == "cheer" else ("frown" if pose == "miss" else "smile")
	draw_eyes(canvas, head_c + Vector2(0, 2.0 * s), 14.0 * s, 3.4 * s, e_style)
	draw_mouth(canvas, head_c + Vector2(0, 11.0 * s), 10.0 * s, 6.5 * s, m_style)

# =============================================================================
# 3. RHYTHM KITCHEN CHEF CHARACTER RIG (Panels 01, 02, 07, 08, 09, 12)
# =============================================================================
static func draw_kitchen_chef(canvas: CanvasItem, base_pos: Vector2, s: float = 1.0, pose: String = "idle", face_idx: int = 0, full_body: bool = false) -> void:
	# Exact design from Panels 07, 08, 12: Puffy white chef toque, chestnut brown hair with side buns,
	# rosy-cheeked round face, white chef coat with red neckerchief bow, blue apron skirt!
	var torso_c := base_pos + Vector2(0.0, -34.0 * s)

	if full_body:
		draw_limb(canvas, base_pos + Vector2(-9.0 * s, -10.0 * s), base_pos + Vector2(-9.0 * s, 8.0 * s), 6.0 * s, SKIN, INK, 3.6 * s)
		draw_limb(canvas, base_pos + Vector2(9.0 * s, -10.0 * s), base_pos + Vector2(9.0 * s, 8.0 * s), 6.0 * s, SKIN, INK, 3.6 * s)
		draw_outlined_ellipse(canvas, base_pos + Vector2(-10.0 * s, 10.0 * s), 9.0 * s, 5.0 * s, 0.0, INK, INK, 1.0)
		draw_outlined_ellipse(canvas, base_pos + Vector2(10.0 * s, 10.0 * s), 9.0 * s, 5.0 * s, 0.0, INK, INK, 1.0)

	# Blue lower apron/pants
	draw_outlined_box(canvas, Rect2(torso_c.x - 19.0 * s, torso_c.y + 8.0 * s, 38.0 * s, 26.0 * s), Color("245ca6"), INK, 4.0 * s, 4.0)

	# Arms
	var sh_l := torso_c + Vector2(-18.0 * s, -18.0 * s)
	var sh_r := torso_c + Vector2(18.0 * s, -18.0 * s)
	if pose == "cheer":
		draw_limb(canvas, sh_l, sh_l + Vector2(-26.0 * s, -34.0 * s), 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_l + Vector2(-28.0 * s, -36.0 * s), 8.0 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(26.0 * s, -34.0 * s), 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_r + Vector2(28.0 * s, -36.0 * s), 8.0 * s, SKIN, INK, 3.5 * s)
	elif pose == "left":
		var hand_l := sh_l + Vector2(-30.0 * s, 14.0 * s)
		draw_limb(canvas, sh_l, hand_l, 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hand_l, 8.5 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, sh_r + Vector2(18.0 * s, 18.0 * s), 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_r + Vector2(18.0 * s, 20.0 * s), 8.0 * s, SKIN, INK, 3.5 * s)
	elif pose == "right":
		draw_limb(canvas, sh_l, sh_l + Vector2(-18.0 * s, 18.0 * s), 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, sh_l + Vector2(-18.0 * s, 20.0 * s), 8.0 * s, SKIN, INK, 3.5 * s)
		var hand_r := sh_r + Vector2(30.0 * s, 14.0 * s)
		draw_limb(canvas, sh_r, hand_r, 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hand_r, 8.5 * s, SKIN, INK, 3.5 * s)
	elif pose == "both":
		var hl := sh_l + Vector2(-34.0 * s, 12.0 * s)
		var hr := sh_r + Vector2(34.0 * s, 12.0 * s)
		draw_limb(canvas, sh_l, hl, 7.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hl, 9.0 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, hr, 7.5 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hr, 9.0 * s, SKIN, INK, 3.5 * s)
	else:
		var hl := sh_l + Vector2(-24.0 * s, 18.0 * s)
		var hr := sh_r + Vector2(24.0 * s, 18.0 * s)
		draw_limb(canvas, sh_l, hl, 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hl, 8.5 * s, SKIN, INK, 3.5 * s)
		draw_limb(canvas, sh_r, hr, 7.0 * s, Color.WHITE, INK, 3.8 * s)
		draw_outlined_circle(canvas, hr, 8.5 * s, SKIN, INK, 3.5 * s)

	# White Chef Jacket
	var coat_pts := PackedVector2Array([
		torso_c + Vector2(-20.0 * s, -24.0 * s),
		torso_c + Vector2(20.0 * s, -24.0 * s),
		torso_c + Vector2(23.0 * s, 12.0 * s),
		torso_c + Vector2(-23.0 * s, 12.0 * s),
	])
	draw_outlined_polygon(canvas, coat_pts, Color.WHITE, INK, 4.0 * s)

	# Red Neckerchief / Bow at collar
	var bow_c := torso_c + Vector2(0.0, -20.0 * s)
	draw_limb(canvas, bow_c, bow_c + Vector2(-8.0 * s, 12.0 * s), 4.5 * s, Color("e63946"), INK, 3.0 * s)
	draw_limb(canvas, bow_c, bow_c + Vector2(8.0 * s, 12.0 * s), 4.5 * s, Color("e63946"), INK, 3.0 * s)
	draw_outlined_circle(canvas, bow_c, 6.0 * s, Color("ff4d5a"), INK, 3.0 * s)

	# Head + Brown Hair Side Puffs + Tall White Puffy Chef Hat
	var head_c := torso_c + Vector2(0.0, -58.0 * s)
	var hair_col := Color("5e3a1e")
	# Side hair buns/ponytail puffs (Panels 07, 08, 12)
	draw_outlined_circle(canvas, head_c + Vector2(-38.0 * s, -2.0 * s), 18.0 * s, hair_col, INK, 4.0 * s)
	draw_outlined_circle(canvas, head_c + Vector2(34.0 * s, -2.0 * s), 14.0 * s, hair_col, INK, 4.0 * s)

	# Round peach head
	draw_cel_circle(canvas, head_c, 36.0 * s, SKIN, INK, 4.2 * s)

	# Center-parted chestnut brown hair curtains framing forehead
	var hair_l := PackedVector2Array([
		head_c + Vector2(0.0, -35.0 * s),
		head_c + Vector2(-22.0 * s, -30.0 * s),
		head_c + Vector2(-36.0 * s, -6.0 * s),
		head_c + Vector2(-18.0 * s, -14.0 * s),
	])
	var hair_r := PackedVector2Array([
		head_c + Vector2(0.0, -35.0 * s),
		head_c + Vector2(22.0 * s, -30.0 * s),
		head_c + Vector2(36.0 * s, -6.0 * s),
		head_c + Vector2(18.0 * s, -14.0 * s),
	])
	draw_outlined_polygon(canvas, hair_l, hair_col, INK, 3.8 * s)
	draw_outlined_polygon(canvas, hair_r, hair_col, INK, 3.8 * s)

	draw_cheeks(canvas, head_c + Vector2(0, 8.0 * s), 42.0 * s, 7.5 * s, 4.5 * s)

	# Chef Face Expression (0..5 from Panel 12)
	var fc := head_c + Vector2(0.0, 2.0 * s)
	match face_idx:
		1: # Blushing happy '^ ^' eyes + smile (Panel 12 Left/Right)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 5.5 * s, "happy")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 16.0 * s, 11.0 * s, "open_d")
		2: # Surprised 'o' mouth (Panel 12 Face #3)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 4.2 * s, "surprised")
			draw_mouth(canvas, fc + Vector2(0, 11.0 * s), 12.0 * s, 11.0 * s, "open_o")
		3: # Big '> <' Laugh (Panel 08 Perfect!)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 22.0 * s, 6.0 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 22.0 * s, 16.0 * s, "open_d")
		4: # '> <' with sweat drops (Panel 12 Face #5)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 5.5 * s, "squint")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 18.0 * s, 13.0 * s, "open_d")
			draw_sweat_drop(canvas, fc + Vector2(28.0 * s, -16.0 * s), 0.9 * s)
		5: # Sweat drop miss (Panel 12 Face #6)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 4.2 * s, "focused")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 16.0 * s, 11.0 * s, "open_d")
			draw_sweat_drop(canvas, fc + Vector2(26.0 * s, -22.0 * s), 0.95 * s)
		_: # Idle bright open smile (Panel 07)
			draw_eyes(canvas, fc + Vector2(0, -3.0 * s), 20.0 * s, 4.5 * s, "normal")
			draw_mouth(canvas, fc + Vector2(0, 10.0 * s), 18.0 * s, 14.0 * s, "open_d")

	# Tall Puffy White Chef Hat (Toque)
	var hat_c := head_c + Vector2(0.0, -38.0 * s)
	# Puff lobes outline first, then white fill so interior seams merge cleanly!
	var puffs := [
		Vector2(-20.0 * s, -20.0 * s),
		Vector2(0.0, -26.0 * s),
		Vector2(20.0 * s, -20.0 * s),
	]
	var puff_r := [18.0 * s, 21.0 * s, 18.0 * s]
	for pi in range(3):
		canvas.draw_circle(hat_c + puffs[pi], puff_r[pi] + 4.2 * s, INK)
	for pi in range(3):
		canvas.draw_circle(hat_c + puffs[pi], puff_r[pi], Color.WHITE)
	# Chef hat band
	var band_rect := Rect2(hat_c.x - 27.0 * s, hat_c.y - 12.0 * s, 54.0 * s, 18.0 * s)
	draw_outlined_box(canvas, band_rect, Color.WHITE, INK, 4.0 * s, 4.0 * s)
	# Cover upper seam between band and puffs
	canvas.draw_rect(Rect2(hat_c.x - 24.0 * s, hat_c.y - 16.0 * s, 48.0 * s, 8.0 * s), Color.WHITE)
	# Pleat lines on chef toque
	canvas.draw_line(hat_c + Vector2(-9.0 * s, -20.0 * s), hat_c + Vector2(-7.0 * s, -10.0 * s), INK, 2.8 * s, true)
	canvas.draw_line(hat_c + Vector2(9.0 * s, -20.0 * s), hat_c + Vector2(7.0 * s, -10.0 * s), INK, 2.8 * s, true)

# =============================================================================
# 4. TITLE SCREEN CAST: SHOW HOST & ORANGE TV BUDDY (Panel 01)
# =============================================================================
static func draw_title_host(canvas: CanvasItem, base_pos: Vector2, s: float = 1.0, bob: float = 0.0) -> void:
	# Pink top-hat & pink tuxedo Show Host from Panel 01!
	var torso_c := base_pos + Vector2(0.0, -28.0 * s + bob)
	# Left arm down, Right arm raised with white glove welcoming the player!
	draw_limb(canvas, torso_c + Vector2(-22.0 * s, -18.0 * s), torso_c + Vector2(-42.0 * s, 22.0 * s), 9.0 * s, Color("f25487"), INK, 4.2 * s)
	draw_outlined_circle(canvas, torso_c + Vector2(-44.0 * s, 26.0 * s), 12.0 * s, Color.WHITE, INK, 3.8 * s)

	var wave_hand := torso_c + Vector2(62.0 * s, -52.0 * s)
	draw_limb(canvas, torso_c + Vector2(20.0 * s, -18.0 * s), wave_hand, 9.0 * s, Color("f25487"), INK, 4.2 * s)
	draw_outlined_circle(canvas, wave_hand + Vector2(6.0 * s, -4.0 * s), 14.0 * s, Color.WHITE, INK, 4.0 * s)
	draw_outlined_circle(canvas, wave_hand + Vector2(-4.0 * s, -12.0 * s), 6.5 * s, Color.WHITE, INK, 3.2 * s)

	# Pink tuxedo jacket + white shirt V + dark navy bowtie
	var jacket := PackedVector2Array([
		torso_c + Vector2(-24.0 * s, -24.0 * s),
		torso_c + Vector2(24.0 * s, -24.0 * s),
		torso_c + Vector2(32.0 * s, 28.0 * s),
		torso_c + Vector2(-32.0 * s, 28.0 * s),
	])
	draw_outlined_polygon(canvas, jacket, Color("f25487"), INK, 4.2 * s)
	var shirt_v := PackedVector2Array([
		torso_c + Vector2(-12.0 * s, -24.0 * s),
		torso_c + Vector2(12.0 * s, -24.0 * s),
		torso_c + Vector2(0.0, 2.0 * s),
	])
	draw_outlined_polygon(canvas, shirt_v, Color.WHITE, INK, 3.2 * s)
	# Dark bowtie
	var bow_l := PackedVector2Array([torso_c + Vector2(0, -20.0 * s), torso_c + Vector2(-14.0 * s, -28.0 * s), torso_c + Vector2(-14.0 * s, -12.0 * s)])
	var bow_r := PackedVector2Array([torso_c + Vector2(0, -20.0 * s), torso_c + Vector2(14.0 * s, -28.0 * s), torso_c + Vector2(14.0 * s, -12.0 * s)])
	draw_outlined_polygon(canvas, bow_l, Color("1f2238"), INK, 3.2 * s)
	draw_outlined_polygon(canvas, bow_r, Color("1f2238"), INK, 3.2 * s)
	draw_outlined_circle(canvas, torso_c + Vector2(0, -20.0 * s), 4.5 * s, Color("1f2238"), INK, 2.5 * s)

	# Round White Head + Pink Top Hat tilted slightly left
	var head_c := torso_c + Vector2(-4.0 * s, -64.0 * s)
	draw_outlined_circle(canvas, head_c, 38.0 * s, Color.WHITE, INK, 4.4 * s)
	draw_eyes(canvas, head_c + Vector2(4.0 * s, -4.0 * s), 20.0 * s, 4.8 * s, "normal")
	draw_mouth(canvas, head_c + Vector2(5.0 * s, 12.0 * s), 24.0 * s, 18.0 * s, "open_d")

	# Tilted Pink Top Hat with yellow ribbon band
	var hat_c := head_c + Vector2(-6.0 * s, -34.0 * s)
	var crown := PackedVector2Array([
		hat_c + Vector2(-28.0 * s, 4.0 * s),
		hat_c + Vector2(-34.0 * s, -36.0 * s),
		hat_c + Vector2(22.0 * s, -44.0 * s),
		hat_c + Vector2(26.0 * s, -4.0 * s),
	])
	draw_outlined_polygon(canvas, crown, Color("ff5d8f"), INK, 4.2 * s)
	var ribbon := PackedVector2Array([
		hat_c + Vector2(-29.0 * s, 2.0 * s),
		hat_c + Vector2(-30.0 * s, -8.0 * s),
		hat_c + Vector2(25.0 * s, -16.0 * s),
		hat_c + Vector2(26.0 * s, -6.0 * s),
	])
	draw_outlined_polygon(canvas, ribbon, Color("ffe066"), INK, 3.0 * s)
	draw_outlined_ellipse(canvas, hat_c + Vector2(-2.0 * s, 2.0 * s), 44.0 * s, 11.0 * s, -0.15, Color("ff80a8"), INK, 4.2 * s)

static func draw_orange_tv_buddy(canvas: CanvasItem, center_pos: Vector2, s: float = 1.0) -> void:
	# Cute orange square robot/TV character from Panel 01!
	var ant_top := center_pos + Vector2(8.0 * s, -46.0 * s)
	canvas.draw_line(center_pos + Vector2(2.0 * s, -24.0 * s), ant_top, INK, 4.0 * s, true)
	draw_outlined_circle(canvas, ant_top, 8.5 * s, Color("f05a28"), INK, 3.5 * s)
	var box_rect := Rect2(center_pos.x - 34.0 * s, center_pos.y - 26.0 * s, 68.0 * s, 52.0 * s)
	draw_outlined_box(canvas, box_rect, Color("f58a3e"), INK, 4.2 * s, 8.0 * s)
	draw_eyes(canvas, center_pos + Vector2(0, -2.0 * s), 22.0 * s, 4.2 * s, "normal")
	draw_mouth(canvas, center_pos + Vector2(0, 10.0 * s), 12.0 * s, 6.0 * s, "smile")
