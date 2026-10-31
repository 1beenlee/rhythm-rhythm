extends RhythmVisual

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("e9f3ff"))
    var center := size * 0.5
    # Conveyor and advancing note tokens.
    draw_rect(Rect2(Vector2(0, center.y + 60), Vector2(size.x, 27)), Color("b9cae9"))
    paint_event_bar("tap", center.y + 73, center.x, 98.0)
    draw_rect(Rect2(Vector2(center.x - 40, center.y - 97), Vector2(80, 125)), RhythmTokens.LAVENDER)
    var pound := 0.0 if reduced_motion else 12.0 * flash / 0.30
    draw_rect(Rect2(Vector2(center.x - 72, center.y + 4 + pound), Vector2(144, 27)), RhythmTokens.CORAL)
    draw_circle(Vector2(center.x, center.y + 72), 19, RhythmTokens.INK)
    draw_circle(Vector2(center.x, center.y + 72), 14, RhythmTokens.YELLOW)
    draw_string(ThemeDB.fallback_font, Vector2(20, 36), "BEAT FACTORY // STAMP ON THE BEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, RhythmTokens.INK)
    paint_feedback()
