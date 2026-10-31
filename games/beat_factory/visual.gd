extends RhythmVisual

const BG_WALL := Color("f6dfc2")
const WALL_PANEL := Color("e6c59e")
const GIRDER := Color("6b4c42")
const TEAL_MACHINE := Color("56b89e")
const TEAL_DARK := Color("368571")
const BELT_BODY := Color("433633")
const BELT_TOP := Color("6e5d58")
const PARCEL_CREAM := Color("fff8e7")
const PARCEL_TAN := Color("f3d39c")
const RIBBON_CORAL := Color("ff686b")

func _draw() -> void:
    var w := size.x
    var h := size.y
    var beat := current_beat()
    var pulse := 0.0 if reduced_motion else sin(beat * TAU)
    var half_pulse := 0.0 if reduced_motion else absf(sin(beat * PI))
    var next_diff := next_event_diff("tap")
    var anticipating := (next_diff >= 0.0 and next_diff <= 0.55)
    var ant_ratio := clampf(1.0 - (next_diff / 0.55), 0.0, 1.0) if anticipating else 0.0
    var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)

    # 1. Background factory wall & warm lighting
    draw_rect(Rect2(0, 0, w, h), BG_WALL)
    for stripe_i in range(6):
        var sx := w * (0.06 + float(stripe_i) * 0.16)
        draw_rect(Rect2(sx, 0, w * 0.08, h * 0.72), Color(WALL_PANEL.r, WALL_PANEL.g, WALL_PANEL.b, 0.45))

    # Wainscoting lower wall
    var wainscot_y := h * 0.64
    CartoonDraw.draw_outlined_box(self, Rect2(-8, wainscot_y, w + 16, h - wainscot_y + 10), Color("8c6556"), CartoonDraw.INK, 4.0, 0.0)

    # Rotating factory gears in background
    _draw_gear(Vector2(w * 0.11, h * 0.22), minf(w, h) * 0.085, beat * 0.65, Color("d4b08c"))
    _draw_gear(Vector2(w * 0.20, h * 0.31), minf(w, h) * 0.055, -beat * 1.0, Color("c49b76"))

    # Supervisor Window (Upper Left-Center) with Supervisor Bird ("Boss Pip")
    var win_w := clampf(w * 0.20, 130.0, 200.0)
    var win_h := clampf(h * 0.27, 120.0, 175.0)
    var win_rect := Rect2(w * 0.08, h * 0.11, win_w, win_h)
    CartoonDraw.draw_outlined_box(self, win_rect, Color("2d384c"), CartoonDraw.INK, 4.5, 18.0)
    CartoonDraw.draw_outlined_box(self, win_rect.grow(-7.0), Color("527996"), CartoonDraw.INK, 3.0, 12.0)
    _draw_supervisor_bird(win_rect, beat, react_ratio)

    # Swinging Industrial Lamp & Light Cone
    var lamp_swing := 0.0 if reduced_motion else sin(beat * PI) * 0.07
    var lamp_anchor := Vector2(w * 0.42, 0.0)
    var lamp_pos := lamp_anchor + Vector2(sin(lamp_swing) * h * 0.11, cos(lamp_swing) * h * 0.11)
    var cone_pts := PackedVector2Array([
        lamp_pos,
        Vector2(w * 0.18, h * 0.76),
        Vector2(w * 0.66, h * 0.76),
    ])
    draw_colored_polygon(cone_pts, Color(1.0, 0.96, 0.72, 0.18))
    draw_line(lamp_anchor, lamp_pos, CartoonDraw.INK, 4.5)
    CartoonDraw.draw_outlined_ellipse(self, lamp_pos + Vector2(0, 6), 34.0, 14.0, lamp_swing, Color("f5b841"), CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_circle(self, lamp_pos + Vector2(0, 14), 10.0, Color("fff7b2"), CartoonDraw.INK, 3.0)

    # Steam Pipe & Rhythm Call Gauge on Right Background
    var call_puff := _get_call_puff(beat)
    var pipe_x := w * 0.84
    CartoonDraw.draw_outlined_box(self, Rect2(pipe_x - 16, -6, 32, h * 0.34), Color("93a8ac"), CartoonDraw.INK, 4.0, 6.0)
    CartoonDraw.draw_outlined_box(self, Rect2(pipe_x - 24, h * 0.28, 48, 18), Color("6e8286"), CartoonDraw.INK, 4.0, 6.0)
    if call_puff > 0.0 or anticipating:
        var puff_scale := maxf(call_puff, ant_ratio * 0.8)
        var puff_pos := Vector2(pipe_x, h * 0.35 + (1.0 - puff_scale) * 14.0)
        CartoonDraw.draw_outlined_circle(self, puff_pos + Vector2(-14, 6), 15.0 * puff_scale + 6.0, Color.WHITE, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_outlined_circle(self, puff_pos + Vector2(12, 4), 13.0 * puff_scale + 5.0, Color.WHITE, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_outlined_circle(self, puff_pos, 18.0 * puff_scale + 8.0, Color.WHITE, CartoonDraw.INK, 3.5)
        CartoonDraw.draw_music_note(self, puff_pos + Vector2(0, -18.0), 0.95, CartoonDraw.GOLD, CartoonDraw.INK)

    # 2. Midground Conveyor Belt System
    var stamp_x := w * 0.42
    var belt_y := h * 0.71
    var belt_h := h * 0.13
    var recoil_y := 0.0
    if react_ratio > 0.0 and last_grade != "Miss" and not reduced_motion:
        recoil_y = sin(react_ratio * PI) * 8.0

    # Conveyor legs
    CartoonDraw.draw_outlined_box(self, Rect2(w * 0.14, belt_y + belt_h - 6, 34, h - belt_y), Color("3c3330"), CartoonDraw.INK, 4.0, 4.0)
    CartoonDraw.draw_outlined_box(self, Rect2(w * 0.72, belt_y + belt_h - 6, 34, h - belt_y), Color("3c3330"), CartoonDraw.INK, 4.0, 4.0)

    # Conveyor bed
    var bed_rect := Rect2(-20, belt_y + recoil_y, w + 40, belt_h)
    CartoonDraw.draw_outlined_box(self, bed_rect, BELT_BODY, CartoonDraw.INK, 4.5, 16.0)
    CartoonDraw.draw_outlined_box(self, Rect2(-20, belt_y + recoil_y, w + 40, belt_h * 0.36), BELT_TOP, CartoonDraw.INK, 3.5, 8.0)

    # Moving conveyor cleats synced to beat
    var cleat_spacing := 68.0
    var cleat_offset := fposmod(beat * cleat_spacing * 2.0, cleat_spacing)
    var num_cleats := int(w / cleat_spacing) + 3
    for ci in range(num_cleats):
        var cx := w - float(ci) * cleat_spacing + cleat_offset
        CartoonDraw.draw_outlined_box(self, Rect2(cx - 8, belt_y + recoil_y + 4, 16, belt_h * 0.28), CartoonDraw.GOLD, CartoonDraw.INK, 2.5, 4.0)

    # Rollers inside conveyor bed
    for ri in range(7):
        var rx := w * (0.08 + float(ri) * 0.14)
        var ry := belt_y + recoil_y + belt_h * 0.67
        CartoonDraw.draw_outlined_circle(self, Vector2(rx, ry), belt_h * 0.22, Color("99a3a6"), CartoonDraw.INK, 3.5)
        var spoke_a := -beat * 2.4 + float(ri) * 0.7
        draw_line(Vector2(rx, ry), Vector2(rx + cos(spoke_a) * belt_h * 0.16, ry + sin(spoke_a) * belt_h * 0.16), CartoonDraw.INK, 3.0)

    # Target Anvil Pad on the belt right under the stamper
    var anvil_col := CartoonDraw.GOLD if anticipating else Color("f0a85d")
    CartoonDraw.draw_outlined_box(self, Rect2(stamp_x - 54, belt_y + recoil_y - 7, 108, 16), anvil_col, CartoonDraw.INK, 3.8, 6.0)

    # 3. Foreground Worker Character ("Poko" with YOU badge) on the left of the stamper
    var worker_pos := Vector2(stamp_x - clampf(w * 0.17, 115.0, 160.0), belt_y + recoil_y + 8.0)
    _draw_worker_poko(worker_pos, beat, half_pulse, ant_ratio, react_ratio)

    # 4. Parcels traveling along the conveyor belt
    var parcel_speed := clampf(w * 0.22, 145.0, 225.0)
    var events: Array = chart.get("events", [])
    for i in range(events.size()):
        var ev: Dictionary = events[i]
        var ev_beat := float(ev.get("beat", 0.0))
        var diff := ev_beat - beat
        if diff < -1.8 or diff > 3.2:
            continue
        var ev_grade := event_grade(i)
        var is_hit := (ev_grade == "Perfect" or ev_grade == "Good")
        var is_missed := (ev_grade == "Miss" or (not is_hit and diff < -0.18))
        var px := stamp_x + diff * parcel_speed
        var py := belt_y + recoil_y - 38.0
        _draw_parcel(Vector2(px, py), i, diff, is_hit, is_missed, beat, react_ratio)

    # 5. Overhead Spring-Loaded Stamping Machine (with face & piston)
    _draw_stamper_machine(stamp_x, belt_y + recoil_y, beat, pulse, ant_ratio, react_ratio)

    # 6. Hit / Miss Impact Effects at the Stamp Zone
    if react_ratio > 0.0:
        _draw_stamp_impact(Vector2(stamp_x, belt_y + recoil_y - 36.0), react_ratio)

    paint_feedback()

func _get_call_puff(beat: float) -> float:
    for call_item in chart.get("calls", []):
        var c_beat := float(call_item.get("beat", -99.0))
        var d := beat - c_beat
        if d >= -0.05 and d <= 0.35:
            return clampf(1.0 - d / 0.35, 0.0, 1.0)
    return 0.0

func _draw_gear(center: Vector2, radius: float, rot: float, col: Color) -> void:
    var teeth := 8
    for t in range(teeth):
        var a := rot + TAU * float(t) / float(teeth)
        var tp := center + Vector2(cos(a), sin(a)) * (radius * 0.95)
        CartoonDraw.draw_outlined_circle(self, tp, radius * 0.24, col, CartoonDraw.INK, 3.0)
    CartoonDraw.draw_outlined_circle(self, center, radius * 0.82, col, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, center, radius * 0.32, BG_WALL, CartoonDraw.INK, 3.0)

func _draw_supervisor_bird(win_rect: Rect2, beat: float, react_ratio: float) -> void:
    var bob := 0.0 if reduced_motion else absf(sin(beat * PI)) * 6.0
    var bc := Vector2(win_rect.position.x + win_rect.size.x * 0.5, win_rect.end.y - 26.0 - bob)
    if react_ratio > 0.0 and last_grade == "Perfect" and not reduced_motion:
        bc.y -= sin(react_ratio * PI) * 14.0
    # Body & head
    CartoonDraw.draw_outlined_ellipse(self, bc, 30.0, 26.0, 0.0, Color("ffe169"), CartoonDraw.INK, 3.5)
    # Little supervisor cap
    CartoonDraw.draw_outlined_box(self, Rect2(bc.x - 22, bc.y - 34, 44, 14), Color("2b59c3"), CartoonDraw.INK, 3.2, 5.0)
    CartoonDraw.draw_outlined_box(self, Rect2(bc.x - 14, bc.y - 23, 38, 7), CartoonDraw.INK, CartoonDraw.INK, 2.0, 3.0)
    # Eyes & Beak
    var eye_style := "normal"
    if react_ratio > 0.0:
        eye_style = "happy" if last_grade == "Perfect" else ("dizzy" if last_grade == "Miss" else "wide")
    CartoonDraw.draw_eyes(self, bc + Vector2(4, -5), 16.0, 4.2, eye_style, Vector2(2, 0))
    var beak := PackedVector2Array([
        bc + Vector2(12, -2),
        bc + Vector2(28, 3),
        bc + Vector2(12, 8),
    ])
    CartoonDraw.draw_outlined_polygon(self, beak, Color("ff8833"), CartoonDraw.INK, 3.0)
    # Reaction icon above bird
    if react_ratio > 0.0 and last_grade == "Perfect":
        CartoonDraw.draw_heart(self, bc + Vector2(26, -34), 10.0, CartoonDraw.HOT_PINK, CartoonDraw.INK, 2.5)
    elif react_ratio > 0.0 and last_grade == "Miss":
        CartoonDraw.draw_sweat_drop(self, bc + Vector2(-26, -24), 1.0)

func _draw_worker_poko(base_pos: Vector2, beat: float, half_pulse: float, ant_ratio: float, react_ratio: float) -> void:
    var bounce := (0.0 if reduced_motion else half_pulse * 7.0)
    var body_pos := base_pos + Vector2(0, -42.0 + bounce)
    # Torso (blue overalls + coral shirt)
    CartoonDraw.draw_outlined_ellipse(self, body_pos, 32.0, 36.0, 0.0, Color("ff7868"), CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_box(self, Rect2(body_pos.x - 24, body_pos.y - 4, 48, 34), Color("3b75c4"), CartoonDraw.INK, 3.8, 10.0)
    CartoonDraw.draw_outlined_circle(self, body_pos + Vector2(-12, 4), 4.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.2)
    CartoonDraw.draw_outlined_circle(self, body_pos + Vector2(12, 4), 4.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.2)

    # Head
    var head_lean := -ant_ratio * 8.0 + (10.0 if (react_ratio > 0.0 and last_grade != "Miss") else 0.0)
    var head_pos := body_pos + Vector2(head_lean, -48.0 - bounce * 0.4)
    CartoonDraw.draw_outlined_circle(self, head_pos, 29.0, Color("ffdfb8"), CartoonDraw.INK, 4.0)
    # Rosy cheeks
    draw_circle(head_pos + Vector2(-14, 5), 5.5, Color(1.0, 0.45, 0.5, 0.55))
    draw_circle(head_pos + Vector2(16, 5), 5.5, Color(1.0, 0.45, 0.5, 0.55))

    # Facial Expression
    var eye_style := "normal"
    var mouth_style := "smile"
    if ant_ratio > 0.25:
        eye_style = "squint"
        mouth_style = "open_o"
    elif react_ratio > 0.0:
        if last_grade == "Perfect":
            eye_style = "happy"
            mouth_style = "big_grin"
        elif last_grade == "Good":
            eye_style = "wide"
            mouth_style = "open_o"
        else:
            eye_style = "dizzy"
            mouth_style = "frown"
    CartoonDraw.draw_eyes(self, head_pos + Vector2(4, -3), 18.0, 4.5, eye_style, Vector2(2, 0))
    CartoonDraw.draw_mouth(self, head_pos + Vector2(4, 11), 16.0, 10.0, mouth_style)
    if react_ratio > 0.0 and last_grade == "Good":
        CartoonDraw.draw_sweat_drop(self, head_pos + Vector2(-28, -10), 1.0)

    # Yellow Hard Hat
    var hat_pos := head_pos + Vector2(0, -18.0)
    if react_ratio > 0.0 and last_grade == "Miss" and not reduced_motion:
        hat_pos.y -= sin(react_ratio * PI) * 18.0
    CartoonDraw.draw_outlined_ellipse(self, hat_pos + Vector2(0, -4), 31.0, 20.0, -0.05, CartoonDraw.GOLD, CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_box(self, Rect2(hat_pos.x - 35, hat_pos.y + 4, 72, 10), Color("f5b82e"), CartoonDraw.INK, 3.8, 5.0)
    # Factory emblem on hat
    CartoonDraw.draw_star(self, hat_pos + Vector2(4, -6), 9.0, 4.2, 5, -PI * 0.5, CartoonDraw.CORAL, CartoonDraw.INK, 2.2)

    # Control Lever & Gloved Hand
    var lever_pivot := base_pos + Vector2(54.0, -16.0)
    var lever_angle := -0.35 - ant_ratio * 0.45
    if react_ratio > 0.0:
        lever_angle = 0.55 if last_grade != "Miss" else -0.75
    var lever_tip := lever_pivot + Vector2(sin(lever_angle), -cos(lever_angle)) * 56.0
    CartoonDraw.draw_outlined_box(self, Rect2(lever_pivot.x - 16, lever_pivot.y - 10, 32, 24), Color("596569"), CartoonDraw.INK, 3.5, 6.0)
    draw_line(lever_pivot, lever_tip, CartoonDraw.INK, 10.0, true)
    draw_line(lever_pivot, lever_tip, Color("cfd8dc"), 4.5, true)
    CartoonDraw.draw_outlined_circle(self, lever_tip, 11.0, CartoonDraw.CORAL, CartoonDraw.INK, 3.5)

    # Arm from shoulder to lever knob
    CartoonDraw.draw_limb(self, body_pos + Vector2(14, -10), lever_tip, 7.5, Color("ff7868"), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, lever_tip, 13.0, Color.WHITE, CartoonDraw.INK, 3.5)

    # Rhythm Heaven style "YOU" badge above Poko
    CartoonDraw.draw_you_badge(self, hat_pos + Vector2(0, -24.0), "YOU", true)

func _draw_parcel(pos: Vector2, idx: int, diff: float, is_hit: bool, is_missed: bool, beat: float, react_ratio: float) -> void:
    var box_w := 74.0
    var box_h := 62.0
    var squash_x := 1.0
    var squash_y := 1.0
    if is_hit and absf(diff) < 0.35 and react_ratio > 0.0 and not reduced_motion:
        squash_x = 1.0 + sin(react_ratio * PI) * 0.24
        squash_y = 1.0 - sin(react_ratio * PI) * 0.22
    elif is_missed:
        squash_x = 1.15
        squash_y = 0.82
    var w := box_w * squash_x
    var h := box_h * squash_y
    var bob := 0.0 if (reduced_motion or is_hit or is_missed) else absf(sin((beat + float(idx) * 0.5) * PI)) * 4.0
    var rect := Rect2(pos.x - w * 0.5, pos.y + (box_h - h) * 0.5 - bob, w, h)
    var fill_col := PARCEL_CREAM if is_hit else (PARCEL_TAN if idx % 2 == 0 else Color("f8e3b4"))
    if is_missed:
        fill_col = Color("c9b9b0")

    CartoonDraw.draw_outlined_box(self, rect, fill_col, CartoonDraw.INK, 4.0, 10.0)
    # Cross ribbon / tape
    CartoonDraw.draw_outlined_box(self, Rect2(rect.position.x + w * 0.42, rect.position.y, w * 0.16, h), RIBBON_CORAL, CartoonDraw.INK, 3.0, 2.0)
    CartoonDraw.draw_outlined_box(self, Rect2(rect.position.x, rect.position.y + h * 0.22, w, h * 0.15), Color("e6b875"), CartoonDraw.INK, 2.5, 2.0)

    # Cute parcel face
    var face_center := rect.get_center() + Vector2(0, 8.0)
    if is_hit:
        CartoonDraw.draw_eyes(self, face_center + Vector2(0, -4), 22.0, 4.0, "happy")
        CartoonDraw.draw_mouth(self, face_center + Vector2(0, 6), 14.0, 8.0, "big_grin")
        # Stamped Golden Crown / Star Seal on the parcel!
        var seal_pos := rect.position + Vector2(w * 0.76, h * 0.30)
        CartoonDraw.draw_outlined_circle(self, seal_pos, 15.0, CartoonDraw.MINT, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_star(self, seal_pos, 10.0, 4.5, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.0)
    elif is_missed:
        CartoonDraw.draw_eyes(self, face_center + Vector2(0, -4), 22.0, 4.0, "dizzy")
        CartoonDraw.draw_mouth(self, face_center + Vector2(0, 7), 14.0, 8.0, "frown")
    else:
        var look := Vector2(-2.0, 0.0)
        var p_eye := "wide" if (diff >= 0.0 and diff <= 0.45) else "normal"
        CartoonDraw.draw_eyes(self, face_center + Vector2(0, -4), 22.0, 3.8, p_eye, look)
        CartoonDraw.draw_mouth(self, face_center + Vector2(0, 6), 12.0, 7.0, "open_o" if p_eye == "wide" else "smile")

func _draw_stamper_machine(stamp_x: float, belt_y: float, _beat: float, pulse: float, ant_ratio: float, react_ratio: float) -> void:
    var top_h := size.y * 0.20
    var rest_head_y := belt_y - 148.0 + (0.0 if reduced_motion else pulse * 5.0)
    var head_y := rest_head_y - ant_ratio * 34.0
    if react_ratio > 0.0:
        var slam_depth := (belt_y - 68.0) - rest_head_y
        if last_grade == "Miss":
            slam_depth *= 0.65
        head_y = rest_head_y + sin(pow(react_ratio, 0.6) * PI) * slam_depth

    # Upper Mount Beam
    CartoonDraw.draw_outlined_box(self, Rect2(stamp_x - 76, -8, 152, top_h), TEAL_DARK, CartoonDraw.INK, 4.5, 12.0)

    # Big Coiled Spring between top beam and stamp head
    var spring_top := top_h - 6.0
    var spring_bot := head_y - 28.0
    var coils := 5
    var prev_pt := Vector2(stamp_x, spring_top)
    for c in range(1, coils * 2 + 1):
        var t := float(c) / float(coils * 2)
        var sy := lerpf(spring_top, spring_bot, t)
        var sx := stamp_x + (28.0 if c % 2 == 1 else -28.0)
        var next_pt := Vector2(sx, sy)
        CartoonDraw.draw_limb(self, prev_pt, next_pt, 5.5, Color("d4dde0"), CartoonDraw.INK, 3.2)
        prev_pt = next_pt

    # Heavy Stamp Head Housing with Expressive Cartoon Face
    var head_w := 116.0
    var head_h := 66.0
    if react_ratio > 0.0 and last_grade == "Perfect" and not reduced_motion:
        head_w += sin(react_ratio * PI) * 14.0
        head_h -= sin(react_ratio * PI) * 8.0
    var head_rect := Rect2(stamp_x - head_w * 0.5, head_y - head_h * 0.5, head_w, head_h)
    CartoonDraw.draw_outlined_box(self, head_rect, TEAL_MACHINE, CartoonDraw.INK, 4.5, 16.0)
    # Rubber Stamp Pad underneath
    CartoonDraw.draw_outlined_box(self, Rect2(stamp_x - head_w * 0.42, head_rect.end.y - 4, head_w * 0.84, 16), CartoonDraw.CORAL, CartoonDraw.INK, 4.0, 6.0)

    # Stamper Machine Eyes & Eyebrows
    var m_eye_style := "normal"
    if ant_ratio > 0.2:
        m_eye_style = "wide"
    elif react_ratio > 0.0:
        m_eye_style = "happy" if last_grade == "Perfect" else ("dizzy" if last_grade == "Miss" else "squint")
    CartoonDraw.draw_eyes(self, head_rect.get_center() + Vector2(0, -4), 36.0, 6.0, m_eye_style, Vector2(0, 2))
    CartoonDraw.draw_mouth(self, head_rect.get_center() + Vector2(0, 14), 24.0, 12.0, "big_grin" if (react_ratio > 0.0 and last_grade == "Perfect") else "smile")

func _draw_stamp_impact(impact_center: Vector2, react_ratio: float) -> void:
    var spread := (1.0 - react_ratio) * 58.0 + 24.0
    if last_grade == "Perfect":
        CartoonDraw.draw_comic_burst(self, impact_center, 46.0 * react_ratio + 16.0, 22.0 * react_ratio + 8.0, 8, react_ratio * 1.2, CartoonDraw.GOLD, CartoonDraw.INK, 3.0)
        for s_i in range(4):
            var a := -PI * 0.85 + float(s_i) * (PI * 0.56 / 3.0)
            var sp := impact_center + Vector2(cos(a), sin(a)) * spread
            CartoonDraw.draw_star(self, sp, 13.0 * react_ratio + 4.0, 5.5 * react_ratio + 2.0, 5, a, CartoonDraw.MINT if s_i % 2 == 0 else CartoonDraw.GOLD, CartoonDraw.INK, 2.5)
    elif last_grade == "Good":
        CartoonDraw.draw_comic_burst(self, impact_center, 34.0 * react_ratio + 10.0, 18.0 * react_ratio + 5.0, 6, 0.2, CartoonDraw.MINT, CartoonDraw.INK, 2.8)
    else:
        for p_i in range(3):
            var off := Vector2((float(p_i) - 1.0) * spread * 0.7, -spread * 0.35)
            CartoonDraw.draw_outlined_circle(self, impact_center + off, 14.0 * react_ratio + 4.0, Color("b0a8a4"), CartoonDraw.INK, 2.8)
