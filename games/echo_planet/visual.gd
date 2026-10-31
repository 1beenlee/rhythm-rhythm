extends RhythmVisual

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("222c5a"))
    var center := size * 0.5
    var beat := current_beat()
    var pulse := 0.0 if reduced_motion else sin(beat * PI * 2.0) * 9.0
    draw_circle(Vector2(center.x, center.y + 32), 96.0 + pulse, RhythmTokens.LAVENDER)
    draw_circle(Vector2(center.x - 33, center.y + 14), 11, RhythmTokens.WHITE)
    draw_circle(Vector2(center.x + 33, center.y + 14), 11, RhythmTokens.WHITE)
    draw_circle(Vector2(center.x - 33, center.y + 14), 5, RhythmTokens.INK)
    draw_circle(Vector2(center.x + 33, center.y + 14), 5, RhythmTokens.INK)
    draw_arc(Vector2(center.x, center.y + 50), 30, 0.25, PI - 0.25, 18, RhythmTokens.YELLOW, 5.0)
    var segment := int(floor(beat / 8.0))
    var listening := fposmod(beat, 8.0) < 4.0
    var title := "LISTEN TO THE PLANET" if listening else "YOUR TURN - ECHO!"
    draw_string(ThemeDB.fallback_font, Vector2(24, 36), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, RhythmTokens.WHITE)
    for call in chart.get("calls", []):
        var delta := beat - float(call["beat"])
        if delta >= 0.0 and delta < 0.28 and int(float(call["beat"]) / 8.0) == segment:
            var beam := 0.18 if reduced_motion else 0.42 * (1.0 - delta / 0.28)
            draw_circle(Vector2(center.x, center.y + 30), 115.0, Color(0.8, 1.0, 0.85, beam))
    if not listening:
        paint_event_bar("tap", center.y + 161, center.x, 85.0)
    paint_feedback()
