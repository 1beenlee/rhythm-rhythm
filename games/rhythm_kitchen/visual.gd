extends RhythmVisual

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("fff3e8"))
    var center := size * 0.5
    draw_rect(Rect2(Vector2(center.x - 180, center.y + 7), Vector2(360, 44)), RhythmTokens.INK)
    draw_circle(Vector2(center.x - 110, center.y - 2), 68, RhythmTokens.CORAL)
    draw_circle(Vector2(center.x + 110, center.y - 2), 68, RhythmTokens.AQUA)
    draw_circle(Vector2(center.x - 110, center.y - 2), 46, RhythmTokens.WHITE)
    draw_circle(Vector2(center.x + 110, center.y - 2), 46, RhythmTokens.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(center.x - 150, center.y + 7), "LEFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, RhythmTokens.INK)
    draw_string(ThemeDB.fallback_font, Vector2(center.x + 79, center.y + 7), "RIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, RhythmTokens.INK)
    var current := current_beat()
    for event in chart.get("events", []):
        var diff := float(event["beat"]) - current
        if diff < -0.3 or diff > 4.0:
            continue
        var lane_x := center.x - 110 if str(event["lane"]) == "left" else center.x + 110
        var ingredient_y := center.y - 26 - diff * 52.0
        draw_circle(Vector2(lane_x, ingredient_y), 13, RhythmTokens.YELLOW)
    draw_string(ThemeDB.fallback_font, Vector2(22, 36), "RHYTHM KITCHEN // SORT THE INGREDIENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, RhythmTokens.INK)
    paint_feedback()
