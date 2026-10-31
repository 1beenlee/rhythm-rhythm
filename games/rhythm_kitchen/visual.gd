extends RhythmVisual

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("fff3e8"))
    var center := size * 0.5
    var lane_offset := minf(110.0, maxf(72.0, size.x * 0.5 - 80.0))
    var rail_width := minf(360.0, size.x - 24.0)
    draw_rect(Rect2(Vector2(center.x - rail_width * 0.5, center.y + 7), Vector2(rail_width, 44)), RhythmTokens.INK)
    draw_circle(Vector2(center.x - lane_offset, center.y - 2), 68, RhythmTokens.CORAL)
    draw_circle(Vector2(center.x + lane_offset, center.y - 2), 68, RhythmTokens.AQUA)
    draw_circle(Vector2(center.x - lane_offset, center.y - 2), 46, RhythmTokens.WHITE)
    draw_circle(Vector2(center.x + lane_offset, center.y - 2), 46, RhythmTokens.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(center.x - lane_offset - 40, center.y + 7), "LEFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, RhythmTokens.INK)
    draw_string(ThemeDB.fallback_font, Vector2(center.x + lane_offset - 31, center.y + 7), "RIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, RhythmTokens.INK)
    var current := current_beat()
    for event in chart.get("events", []):
        var diff := float(event["beat"]) - current
        if diff < -0.3 or diff > 4.0:
            continue
        var lane_x := center.x - lane_offset if str(event["lane"]) == "left" else center.x + lane_offset
        var ingredient_y := center.y - 26 - diff * 52.0
        draw_circle(Vector2(lane_x, ingredient_y), 13, RhythmTokens.YELLOW)
    var title := "RHYTHM KITCHEN" if size.x < 400.0 else "RHYTHM KITCHEN // SORT THE INGREDIENTS"
    draw_string(ThemeDB.fallback_font, Vector2(22, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, RhythmTokens.INK)
    paint_feedback()
