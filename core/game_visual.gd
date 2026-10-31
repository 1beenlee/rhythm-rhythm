extends Control
class_name RhythmVisual

var chart: Dictionary = {}
var session: RhythmSession
var last_grade := ""
var last_lane := ""
var flash := 0.0
var reduced_motion := false

func configure(game_chart: Dictionary, live_session: RhythmSession, minimal_motion: bool) -> void:
    chart = game_chart
    session = live_session
    reduced_motion = minimal_motion
    clip_contents = true  # Keep game art inside its playfield, below the HUD.
    session.feedback.connect(show_feedback)
    set_process(true)

func show_feedback(grade_name: String, lane: String, _combo: int) -> void:
    last_grade = grade_name if grade_name != "Outside" else "Miss"
    last_lane = lane
    flash = 0.30
    queue_redraw()

func _process(delta: float) -> void:
    flash = maxf(0.0, flash - delta)
    queue_redraw()

func current_beat() -> float:
    if session == null:
        return 0.0
    return session.song_time * float(chart.get("bpm", 100.0)) / 60.0

func paint_feedback() -> void:
    if flash <= 0.0:
        return
    var alpha := 0.65 if reduced_motion else flash / 0.30
    draw_rect(Rect2(Vector2.ZERO, size), Color(RhythmTokens.grade_color(last_grade), alpha * 0.16))
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(0, size.y * 0.83), last_grade.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, int(size.x), 29, RhythmTokens.grade_color(last_grade))

func paint_event_bar(lane: String, y: float, center_x: float, scale_x: float) -> void:
    var current := current_beat()
    for event in chart.get("events", []):
        if str(event.get("lane", "")) != lane:
            continue
        var difference := float(event["beat"]) - current
        if difference < -0.45 or difference > 5.0:
            continue
        var x := center_x + difference * scale_x
        draw_circle(Vector2(x, y), 12.0, RhythmTokens.YELLOW)
