extends Control
class_name RhythmVisual

var chart: Dictionary = {}
var session: RhythmSession
var last_grade := ""
var last_lane := ""
var flash := 0.0
var reaction_timer := 0.0
var last_combo := 0
var reduced_motion := false

func configure(game_chart: Dictionary, live_session: RhythmSession, minimal_motion: bool) -> void:
    chart = game_chart
    session = live_session
    reduced_motion = minimal_motion
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    session.feedback.connect(show_feedback)
    set_process(true)

func _gui_input(event: InputEvent) -> void:
    if session == null or not session.active or session.paused:
        return
    var click_pos := Vector2.ZERO
    var triggered := false
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        click_pos = event.position
        triggered = true
    elif event is InputEventScreenTouch and event.pressed:
        click_pos = event.position
        triggered = true
    if triggered:
        var lanes: Array = session.manifest.get("lanes", ["tap"]) if session.manifest != null else ["tap"]
        if lanes.size() == 1:
            session.submit("tap")
        else:
            session.submit("left" if click_pos.x < size.x * 0.5 else "right")
        accept_event()

func show_feedback(grade_name: String, lane: String, combo_val: int) -> void:
    last_grade = grade_name if grade_name != "Outside" else "Miss"
    last_lane = lane
    last_combo = combo_val
    flash = 0.34
    reaction_timer = 0.45
    queue_redraw()

func _process(delta: float) -> void:
    flash = maxf(0.0, flash - delta)
    reaction_timer = maxf(0.0, reaction_timer - delta)
    queue_redraw()

func current_beat() -> float:
    if session == null:
        return 0.0
    return session.song_time * float(chart.get("bpm", 100.0)) / 60.0

func event_grade(index: int) -> String:
    if session == null:
        return ""
    if index < session.event_grades.size() and session.event_grades[index] != "":
        return session.event_grades[index]
    if index < session.states.size() and session.states[index]:
        return "Perfect"
    return ""

func next_event_diff(lane_filter: String = "") -> float:
    var beat := current_beat()
    var best := 999.0
    var events: Array = chart.get("events", [])
    for i in range(events.size()):
        if session != null and i < session.states.size() and session.states[i]:
            continue
        var ev: Dictionary = events[i]
        if lane_filter != "" and str(ev.get("lane", "")) != lane_filter:
            continue
        var diff := float(ev.get("beat", 0.0)) - beat
        if diff >= -0.15 and diff < best:
            best = diff
    return best

func paint_feedback() -> void:
    if flash <= 0.0:
        return
    var ratio := 1.0 if reduced_motion else clampf(flash / 0.34, 0.0, 1.0)
    var is_narrow := size.x < 500.0
    var pop_scale := (0.82 if is_narrow else 1.0) + (0.0 if reduced_motion else sin(ratio * PI) * 0.12)
    var badge_center := Vector2(size.x * 0.82, size.y * 0.16)
    if is_narrow:
        badge_center = Vector2(size.x * 0.68, size.y * 0.15)
    var badge_col := CartoonDraw.GOLD if last_grade == "Perfect" else (CartoonDraw.MINT if last_grade == "Good" else CartoonDraw.CORAL)
    var label_str := "PERFECT!" if last_grade == "Perfect" else ("GOOD!" if last_grade == "Good" else "MISS!")
    if last_grade == "Perfect":
        CartoonDraw.draw_comic_burst(self, badge_center, 58.0 * pop_scale, 38.0 * pop_scale, 10, ratio * 0.4, CartoonDraw.GOLD, CartoonDraw.INK, 3.5)
        CartoonDraw.draw_star(self, badge_center + Vector2(-56.0, -18.0), 14.0 * pop_scale, 6.0 * pop_scale, 5, -0.3, CartoonDraw.MINT, CartoonDraw.INK, 2.5)
        CartoonDraw.draw_star(self, badge_center + Vector2(58.0, 14.0), 12.0 * pop_scale, 5.0 * pop_scale, 5, 0.4, CartoonDraw.HOT_PINK, CartoonDraw.INK, 2.5)
    else:
        var r_w := 112.0 * pop_scale
        var r_h := 38.0 * pop_scale
        CartoonDraw.draw_outlined_box(self, Rect2(badge_center - Vector2(r_w * 0.5, r_h * 0.5), Vector2(r_w, r_h)), badge_col, CartoonDraw.INK, 3.5, 12.0)
    CartoonDraw.draw_outlined_text(self, badge_center + Vector2(-75.0, 7.0), label_str, 150, 20, CartoonDraw.PAPER if last_grade == "Miss" else CartoonDraw.INK, CartoonDraw.INK if last_grade == "Miss" else CartoonDraw.PAPER, 3.0)
    if last_combo >= 3 and last_grade != "Miss":
        CartoonDraw.draw_outlined_text(self, badge_center + Vector2(-60.0, 32.0), "%d CHAIN!" % last_combo, 120, 14, CartoonDraw.GOLD, CartoonDraw.INK, 2.5)

func paint_event_bar(lane: String, y: float, center_x: float, scale_x: float) -> void:
    var current := current_beat()
    for event in chart.get("events", []):
        if str(event.get("lane", "")) != lane:
            continue
        var difference := float(event["beat"]) - current
        if difference < -0.45 or difference > 5.0:
            continue
        var x := center_x + difference * scale_x
        CartoonDraw.draw_star(self, Vector2(x, y), 14.0, 6.5, 5, current * 1.5, CartoonDraw.GOLD, CartoonDraw.INK, 3.0)
