extends RefCounted
class_name CartoonDraw

const INK := Color("1d1716")
const PAPER := Color("fff8ea")
const GOLD := Color("ffd447")
const MINT := Color("4de2b8")
const CORAL := Color("ff686b")
const SKY_BLUE := Color("5ec8ff")
const HOT_PINK := Color("ff5ca8")

static func make_ellipse_points(center: Vector2, rx: float, ry: float, rot: float = 0.0, segments: int = 28) -> PackedVector2Array:
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

static func draw_outlined_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, rot: float, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0) -> void:
	var pts := make_ellipse_points(center, rx, ry, rot, 28)
	draw_outlined_polygon(canvas, pts, fill_color, outline_color, outline_width)

static func draw_outlined_box(canvas: CanvasItem, rect: Rect2, fill_color: Color, outline_color: Color = INK, outline_width: float = 4.0, corner_radius: float = 10.0) -> void:
	var pts := make_rounded_rect_points(rect, corner_radius, 5)
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
	canvas.draw_polyline(pts, Color(neon_color.r, neon_color.g, neon_color.b, 0.32), width * 2.2, true)
	canvas.draw_polyline(pts, neon_color, width, true)

static func draw_comic_burst(canvas: CanvasItem, center: Vector2, outer_r: float, inner_r: float, spikes: int = 10, rot: float = 0.0, fill_color: Color = GOLD, outline_color: Color = INK, outline_width: float = 3.5) -> void:
	draw_star(canvas, center, outer_r, inner_r, spikes, rot, fill_color, outline_color, outline_width)

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
	var r := 8.0 * scale_val
	var pts := PackedVector2Array([
		pos + Vector2(0, -r * 1.6),
		pos + Vector2(r * 0.9, -r * 0.2),
		pos + Vector2(r, r * 0.5),
		pos + Vector2(0, r * 1.1),
		pos + Vector2(-r, r * 0.5),
		pos + Vector2(-r * 0.9, -r * 0.2),
	])
	draw_outlined_polygon(canvas, pts, Color("6fe3ff"), outline_color, 2.5 * scale_val)
	canvas.draw_circle(pos + Vector2(-r * 0.25, r * 0.2), r * 0.25, Color.WHITE)

static func draw_music_note(canvas: CanvasItem, pos: Vector2, scale_val: float = 1.0, fill_color: Color = GOLD, outline_color: Color = INK) -> void:
	var s := scale_val
	var head := pos + Vector2(-4.0 * s, 8.0 * s)
	var top := pos + Vector2(3.0 * s, -14.0 * s)
	var flag_end := pos + Vector2(14.0 * s, -7.0 * s)
	canvas.draw_line(head + Vector2(5.0 * s, 0.0), top, outline_color, 6.5 * s, true)
	canvas.draw_line(top, flag_end, outline_color, 6.5 * s, true)
	draw_outlined_ellipse(canvas, head, 7.5 * s, 5.5 * s, -0.35, fill_color, outline_color, 3.0 * s)
	canvas.draw_line(head + Vector2(5.0 * s, 0.0), top, fill_color, 3.2 * s, true)
	canvas.draw_line(top, flag_end, fill_color, 3.2 * s, true)

static func draw_eyes(canvas: CanvasItem, center: Vector2, spacing: float, radius: float, style: String = "normal", look_offset: Vector2 = Vector2.ZERO, outline_color: Color = INK) -> void:
	var left_pos := center + Vector2(-spacing * 0.5, 0.0)
	var right_pos := center + Vector2(spacing * 0.5, 0.0)
	for eye_pos in [left_pos, right_pos]:
		var ep: Vector2 = eye_pos
		match style:
			"happy":
				canvas.draw_arc(ep + Vector2(0, radius * 0.3), radius, PI * 1.15, PI * 1.85, 12, outline_color, maxf(3.0, radius * 0.48), true)
			"squint":
				var dir: float = 1.0 if ep.x < center.x else -1.0
				canvas.draw_line(ep + Vector2(-radius * dir, -radius * 0.65), ep + Vector2(radius * 0.5 * dir, 0.0), outline_color, maxf(3.0, radius * 0.45), true)
				canvas.draw_line(ep + Vector2(radius * 0.5 * dir, 0.0), ep + Vector2(-radius * dir, radius * 0.65), outline_color, maxf(3.0, radius * 0.45), true)
			"dizzy":
				canvas.draw_line(ep + Vector2(-radius, -radius), ep + Vector2(radius, radius), outline_color, maxf(3.0, radius * 0.45), true)
				canvas.draw_line(ep + Vector2(radius, -radius), ep + Vector2(-radius, radius), outline_color, maxf(3.0, radius * 0.45), true)
			"wide":
				draw_outlined_circle(canvas, ep, radius * 1.35, Color.WHITE, outline_color, 3.0)
				canvas.draw_circle(ep + look_offset * 0.6, radius * 0.62, outline_color)
				canvas.draw_circle(ep + look_offset * 0.6 + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.24, Color.WHITE)
			_:
				canvas.draw_circle(ep + look_offset, radius, outline_color)
				canvas.draw_circle(ep + look_offset + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.34, Color.WHITE)

static func draw_mouth(canvas: CanvasItem, center: Vector2, width: float, height: float, style: String = "smile", outline_color: Color = INK) -> void:
	match style:
		"big_grin":
			var pts := PackedVector2Array([
				center + Vector2(-width * 0.5, -height * 0.15),
				center + Vector2(width * 0.5, -height * 0.15),
				center + Vector2(width * 0.38, height * 0.65),
				center + Vector2(0.0, height * 0.85),
				center + Vector2(-width * 0.38, height * 0.65),
			])
			draw_outlined_polygon(canvas, pts, Color("b8253a"), outline_color, 3.0)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.48), width * 0.24, height * 0.25, 0.0, Color("ff7a8a"), outline_color, 0.0)
		"open_o":
			draw_outlined_ellipse(canvas, center, width * 0.38, height * 0.58, 0.0, Color("a61c3c"), outline_color, 3.2)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.2), width * 0.22, height * 0.22, 0.0, Color("ff7a8a"), outline_color, 0.0)
		"open_a":
			draw_outlined_ellipse(canvas, center, width * 0.52, height * 0.68, 0.0, Color("a61c3c"), outline_color, 3.4)
			draw_outlined_ellipse(canvas, center + Vector2(0.0, height * 0.24), width * 0.32, height * 0.26, 0.0, Color("ff7a8a"), outline_color, 0.0)
		"frown":
			canvas.draw_arc(center + Vector2(0.0, height * 0.55), width * 0.45, PI * 1.15, PI * 1.85, 12, outline_color, 3.4, true)
		"cat":
			canvas.draw_arc(center + Vector2(-width * 0.22, 0.0), width * 0.22, 0.1, PI - 0.1, 10, outline_color, 3.0, true)
			canvas.draw_arc(center + Vector2(width * 0.22, 0.0), width * 0.22, 0.1, PI - 0.1, 10, outline_color, 3.0, true)
		_:
			canvas.draw_arc(center + Vector2(0.0, -height * 0.2), width * 0.45, 0.18, PI - 0.18, 12, outline_color, 3.4, true)

static func draw_you_badge(canvas: CanvasItem, anchor_pos: Vector2, label_text: String = "YOU", above: bool = true) -> void:
	var font := ThemeDB.fallback_font
	var box_w := 56.0
	var box_h := 24.0
	var box_pos := anchor_pos + Vector2(-box_w * 0.5, -box_h - 10.0 if above else 10.0)
	var rect := Rect2(box_pos, Vector2(box_w, box_h))
	draw_outlined_box(canvas, rect, PAPER, INK, 3.2, 8.0)
	var tri := PackedVector2Array()
	if above:
		tri = PackedVector2Array([
			anchor_pos + Vector2(-6.0, -11.0),
			anchor_pos + Vector2(6.0, -11.0),
			anchor_pos + Vector2(0.0, -2.0),
		])
	else:
		tri = PackedVector2Array([
			anchor_pos + Vector2(-6.0, 11.0),
			anchor_pos + Vector2(6.0, 11.0),
			anchor_pos + Vector2(0.0, 2.0),
		])
	draw_outlined_polygon(canvas, tri, PAPER, INK, 2.8)
	canvas.draw_string(font, box_pos + Vector2(0.0, 17.5), label_text, HORIZONTAL_ALIGNMENT_CENTER, int(box_w), 15, INK)

static func draw_speech_bubble(canvas: CanvasItem, rect: Rect2, tail_target: Vector2, text: String, bg_color: Color = PAPER, text_color: Color = INK, font_size: int = 18) -> void:
	var center := rect.get_center()
	var dir := (tail_target - center).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var base_pt := center + dir * minf(rect.size.x, rect.size.y) * 0.35
	var tri := PackedVector2Array([
		base_pt - perp * 10.0,
		base_pt + perp * 10.0,
		tail_target,
	])
	draw_outlined_polygon(canvas, tri, bg_color, INK, 3.5)
	draw_outlined_box(canvas, rect, bg_color, INK, 3.8, 14.0)
	var font := ThemeDB.fallback_font
	var text_y := rect.position.y + rect.size.y * 0.5 + float(font_size) * 0.34
	canvas.draw_string(font, Vector2(rect.position.x + 6.0, text_y), text, HORIZONTAL_ALIGNMENT_CENTER, int(rect.size.x - 12.0), font_size, text_color)

static func draw_outlined_text(canvas: CanvasItem, pos: Vector2, text: String, width: int, font_size: int, fill_color: Color, outline_color: Color = INK, outline_px: float = 3.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var font := ThemeDB.fallback_font
	var offsets := [
		Vector2(-outline_px, 0.0),
		Vector2(outline_px, 0.0),
		Vector2(0.0, -outline_px),
		Vector2(0.0, outline_px),
		Vector2(-outline_px * 0.7, -outline_px * 0.7),
		Vector2(outline_px * 0.7, -outline_px * 0.7),
		Vector2(-outline_px * 0.7, outline_px * 0.7),
		Vector2(outline_px * 0.7, outline_px * 0.7),
	]
	for off in offsets:
		canvas.draw_string(font, pos + off, text, align, width, font_size, outline_color)
	canvas.draw_string(font, pos, text, align, width, font_size, fill_color)
