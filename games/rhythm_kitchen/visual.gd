extends RhythmVisual

const TILE_CREAM := Color("fff6df")
const TILE_YELLOW := Color("f8d96d")
const TILE_MINT := Color("a5e3d6")
const COUNTER_TOP := Color("f2ece1")
const CABINET_RED := Color("a8422b")
const STOVE_DARK := Color("3b4047")
const FRIDGE_BLUE := Color("88c9df")
const PAN_RED := Color("eb524a")
const BOWL_GOLD := Color("ffb338")

func _draw() -> void:
    var w := size.x
    var h := size.y
    var beat := current_beat()
    var pulse := 0.0 if reduced_motion else sin(beat * TAU)
    var half_pulse := 0.0 if reduced_motion else absf(sin(beat * PI))
    var next_left := next_event_diff("left")
    var next_right := next_event_diff("right")
    var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)

    # 1. Background Kitchen Tile Wall (Yellow & Mint Checker Tiles like Reference Image 3!)
    draw_rect(Rect2(0, 0, w, h), TILE_CREAM)
    var cols := 10
    var rows := 5
    var tw := w / float(cols)
    var th := (h * 0.65) / float(rows)
    for r in range(rows):
        for c in range(cols):
            var t_col := TILE_YELLOW if (r + c) % 2 == 0 else TILE_MINT
            var trect := Rect2(float(c) * tw + 3.0, float(r) * th + 3.0, tw - 6.0, th - 6.0)
            draw_rect(trect, Color(t_col.r, t_col.g, t_col.b, 0.55))

    # 2. Left Sunlit Window with Ocean Sky, Palm Tree & Sink Counter
    var win_w := clampf(w * 0.22, 130.0, 220.0)
    var win_h := h * 0.44
    var win_rect := Rect2(w * 0.02, h * 0.08, win_w, win_h)
    CartoonDraw.draw_outlined_box(self, win_rect, Color("5ce1ff"), CartoonDraw.INK, 4.0, 8.0)
    # Ocean & Palm fronds outside window
    draw_rect(Rect2(win_rect.position.x + 4, win_rect.end.y - 36, win_rect.size.x - 8, 32), Color("1aa3c8"))
    var palm_base := Vector2(win_rect.position.x + 28, win_rect.end.y - 8)
    var palm_top := Vector2(win_rect.position.x + win_rect.size.x * 0.55, win_rect.position.y + win_rect.size.y * 0.42)
    CartoonDraw.draw_limb(self, palm_base, palm_top, 5.5, Color("9c6644"), CartoonDraw.INK, 3.0)
    var frond_sway := 0.0 if reduced_motion else pulse * 0.08
    for fi in range(4):
        var fa := -0.8 + float(fi) * 0.55 + frond_sway
        CartoonDraw.draw_outlined_ellipse(self, palm_top + Vector2(cos(fa) * 28.0, sin(fa) * 14.0), 26.0, 9.0, fa, Color("4eb857"), CartoonDraw.INK, 2.8)
    # Window frame Mullions
    CartoonDraw.draw_outlined_box(self, Rect2(win_rect.position.x, win_rect.position.y, win_rect.size.x, 12), Color("d8f3f7"), CartoonDraw.INK, 3.5, 4.0)

    # Upper Shelf with Retro Radio, Herb Plant & Red Stockpot
    var shelf_rect := Rect2(w * 0.28, h * 0.14, w * 0.52, 14.0)
    CartoonDraw.draw_outlined_box(self, shelf_rect, Color("c48449"), CartoonDraw.INK, 3.8, 4.0)
    # Retro Radio pulsing to the beat
    var radio_scale := 1.0 + (0.0 if reduced_motion else half_pulse * 0.06)
    var radio_rect := Rect2(shelf_rect.position.x + 18, shelf_rect.position.y - 38 * radio_scale, 58 * radio_scale, 38 * radio_scale)
    CartoonDraw.draw_outlined_box(self, radio_rect, CartoonDraw.CORAL, CartoonDraw.INK, 3.5, 8.0)
    CartoonDraw.draw_outlined_circle(self, radio_rect.position + Vector2(20, 19), 10.0, CartoonDraw.PAPER, CartoonDraw.INK, 2.8)
    # Hanging Kitchen Utensils below shelf
    var rack_y := h * 0.22
    draw_line(Vector2(w * 0.34, rack_y), Vector2(w * 0.68, rack_y), CartoonDraw.INK, 4.0)
    for ui in range(4):
        var ux := w * (0.38 + float(ui) * 0.08)
        var u_sway := 0.0 if reduced_motion else sin(beat * PI + float(ui)) * 4.0
        draw_line(Vector2(ux, rack_y), Vector2(ux + u_sway, rack_y + 38.0), CartoonDraw.INK, 4.0)
        CartoonDraw.draw_outlined_circle(self, Vector2(ux + u_sway, rack_y + 44.0), 9.0, Color("d9dee3"), CartoonDraw.INK, 3.0)

    # Right Pastel-Blue Refrigerator with Magnets
    var fridge_rect := Rect2(w * 0.83, h * 0.18, w * 0.19, h * 0.82)
    CartoonDraw.draw_outlined_box(self, fridge_rect, FRIDGE_BLUE, CartoonDraw.INK, 4.2, 14.0)
    CartoonDraw.draw_outlined_box(self, Rect2(fridge_rect.position.x + 16, fridge_rect.position.y + 44, 62, 54), CartoonDraw.PAPER, CartoonDraw.INK, 3.0, 4.0)
    CartoonDraw.draw_outlined_circle(self, fridge_rect.position + Vector2(28, 44), 6.0, CartoonDraw.CORAL, CartoonDraw.INK, 2.2)

    # 3. Kitchen Counter, Sink, Cabinets & Stove
    var counter_y := h * 0.66
    CartoonDraw.draw_outlined_box(self, Rect2(-10, counter_y, w * 0.86, h - counter_y + 12), CABINET_RED, CartoonDraw.INK, 4.2, 0.0)
    CartoonDraw.draw_outlined_box(self, Rect2(w * 0.34, counter_y + 18, w * 0.42, h - counter_y), STOVE_DARK, CartoonDraw.INK, 4.0, 6.0)
    # Stove Knobs
    for ki in range(4):
        CartoonDraw.draw_outlined_circle(self, Vector2(w * (0.40 + float(ki) * 0.08), counter_y + 42), 9.0, Color("8a949e"), CartoonDraw.INK, 3.0)
    # Countertop Slab
    CartoonDraw.draw_outlined_box(self, Rect2(-10, counter_y - 10, w * 0.86, 28), COUNTER_TOP, CartoonDraw.INK, 4.2, 6.0)

    # White Sous-Chef Cat ("Nori") sitting by the Left Window / Sink Counter!
    var cat_pos := Vector2(w * 0.14, counter_y - 10.0)
    _draw_sous_chef_cat(cat_pos, beat, half_pulse, react_ratio)

    # 4. Left & Right Cooking Stations + Chef Protagonist ("Chef Mimo" with YOU badge)
    var left_station := Vector2(w * 0.36, counter_y - 16.0)
    var right_station := Vector2(w * 0.66, counter_y - 16.0)
    var chef_pos := Vector2(w * 0.51, counter_y + 6.0)

    _draw_chef_mimo(chef_pos, left_station, right_station, beat, half_pulse, next_left, next_right, react_ratio)
    _draw_cooking_stations(left_station, right_station, beat, next_left, next_right, react_ratio)

    # 5. Parabolic Flying Ingredients for LEFT (Skillet) and RIGHT (Mixing Bowl)
    var events: Array = chart.get("events", [])
    for i in range(events.size()):
        var ev: Dictionary = events[i]
        var ev_beat := float(ev.get("beat", 0.0))
        var diff := ev_beat - beat
        if diff < -0.35 or diff > 2.4:
            continue
        var ev_grade := event_grade(i)
        var is_hit := (ev_grade == "Perfect" or ev_grade == "Good")
        var lane_str := str(ev.get("lane", "left"))
        _draw_flying_ingredient(i, lane_str, diff, is_hit, left_station, right_station, beat)

    # 6. Hit / Miss Kitchen Sparkles & Sizzle Effects
    if react_ratio > 0.0:
        var target_pt := left_station if last_lane == "left" else right_station
        _draw_kitchen_impact(target_pt + Vector2(0, -24), react_ratio)

    # Finale Completed Dish Banner at end of track
    if beat >= 58.0:
        var dish_pos := Vector2(w * 0.51, counter_y - 54.0)
        CartoonDraw.draw_comic_burst(self, dish_pos, 52.0, 32.0, 10, beat, CartoonDraw.GOLD, CartoonDraw.INK, 3.5)
        CartoonDraw.draw_outlined_text(self, dish_pos + Vector2(-70, 6), "BON APPETIT!", 140, 16, CartoonDraw.INK, CartoonDraw.PAPER, 2.5)

    paint_feedback()

func _draw_sous_chef_cat(pos: Vector2, beat: float, half_pulse: float, react_ratio: float) -> void:
    var bob := 0.0 if reduced_motion else half_pulse * 4.0
    # Tail wagging on beat
    var tail_sway := 0.0 if reduced_motion else sin(beat * PI) * 14.0
    CartoonDraw.draw_limb(self, pos + Vector2(-18, -12), pos + Vector2(-36 + tail_sway, -38), 5.0, Color.WHITE, CartoonDraw.INK, 3.5)
    # Cat body
    CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(0, -24 + bob), 22.0, 28.0, 0.0, Color.WHITE, CartoonDraw.INK, 3.8)
    # Cat head & pointed ears
    var head_c := pos + Vector2(2, -56 + bob)
    var left_ear := PackedVector2Array([head_c + Vector2(-18, -8), head_c + Vector2(-22, -28), head_c + Vector2(-4, -16)])
    var right_ear := PackedVector2Array([head_c + Vector2(4, -16), head_c + Vector2(22, -28), head_c + Vector2(18, -8)])
    CartoonDraw.draw_outlined_polygon(self, left_ear, Color.WHITE, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_polygon(self, right_ear, Color.WHITE, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, head_c, 20.0, Color.WHITE, CartoonDraw.INK, 3.8)
    var c_eye := "squint"
    if react_ratio > 0.0:
        c_eye = "happy" if last_grade == "Perfect" else ("dizzy" if last_grade == "Miss" else "wide")
    CartoonDraw.draw_eyes(self, head_c + Vector2(2, -2), 13.0, 3.2, c_eye)
    CartoonDraw.draw_mouth(self, head_c + Vector2(2, 6), 10.0, 5.0, "cat")
    if react_ratio > 0.0 and last_grade == "Perfect":
        CartoonDraw.draw_heart(self, head_c + Vector2(22, -24), 9.0, CartoonDraw.HOT_PINK, CartoonDraw.INK, 2.5)

func _draw_chef_mimo(pos: Vector2, left_st: Vector2, right_st: Vector2, _beat: float, half_pulse: float, next_left: float, next_right: float, react_ratio: float) -> void:
    var bounce := 0.0 if reduced_motion else half_pulse * 6.0
    var lean_x := 0.0
    if react_ratio > 0.0:
        lean_x = -16.0 if last_lane == "left" else 16.0
    elif next_left >= 0.0 and next_left <= 0.55 and next_left <= next_right:
        lean_x = -10.0
    elif next_right >= 0.0 and next_right <= 0.55:
        lean_x = 10.0

    var torso_c := pos + Vector2(lean_x, -64.0 + bounce)
    # Arms reaching toward the active cooking stations
    var left_hand := left_st + Vector2(28, -22)
    var right_hand := right_st + Vector2(-28, -22)
    if react_ratio > 0.0 and last_lane == "left":
        left_hand += Vector2(0, -18.0 * sin(react_ratio * PI))
    if react_ratio > 0.0 and last_lane == "right":
        right_hand += Vector2(0, -18.0 * sin(react_ratio * PI))

    CartoonDraw.draw_limb(self, torso_c + Vector2(-24, -18), left_hand, 7.0, Color("f5d2b0"), CartoonDraw.INK, 3.8)
    CartoonDraw.draw_limb(self, torso_c + Vector2(24, -18), right_hand, 7.0, Color("f5d2b0"), CartoonDraw.INK, 3.8)

    # White Shirt & Yellow Crossed Apron (Inspired by Reference Image 3!)
    CartoonDraw.draw_outlined_box(self, Rect2(torso_c.x - 30, torso_c.y - 34, 60, 68), Color.WHITE, CartoonDraw.INK, 4.0, 14.0)
    CartoonDraw.draw_outlined_box(self, Rect2(torso_c.x - 24, torso_c.y - 4, 48, 42), TILE_YELLOW, CartoonDraw.INK, 3.8, 8.0)
    # Crossed apron straps
    draw_line(torso_c + Vector2(-22, -32), torso_c + Vector2(18, -2), CartoonDraw.INK, 10.0)
    draw_line(torso_c + Vector2(-22, -32), torso_c + Vector2(18, -2), TILE_YELLOW, 5.0)
    draw_line(torso_c + Vector2(22, -32), torso_c + Vector2(-18, -2), CartoonDraw.INK, 10.0)
    draw_line(torso_c + Vector2(22, -32), torso_c + Vector2(-18, -2), TILE_YELLOW, 5.0)

    # Chef Head & Bun Hairstyle + Puffy Chef Hat
    var head_c := torso_c + Vector2(lean_x * 0.3, -64.0)
    CartoonDraw.draw_outlined_circle(self, head_c, 28.0, Color("f5d2b0"), CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_ellipse(self, head_c + Vector2(0, -14), 29.0, 14.0, 0.0, Color("63412c"), CartoonDraw.INK, 3.8)
    # Puffy Chef Toque Hat
    var hat_lift := 0.0
    if react_ratio > 0.0 and last_grade == "Miss" and not reduced_motion:
        hat_lift = sin(react_ratio * PI) * 16.0
    var hat_c := head_c + Vector2(0, -34.0 - hat_lift)
    CartoonDraw.draw_outlined_circle(self, hat_c + Vector2(-14, -6), 15.0, Color.WHITE, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, hat_c + Vector2(14, -6), 15.0, Color.WHITE, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, hat_c + Vector2(0, -12), 18.0, Color.WHITE, CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_box(self, Rect2(hat_c.x - 22, hat_c.y + 2, 44, 12), Color.WHITE, CartoonDraw.INK, 3.5, 4.0)

    # Expressive Chef Face
    var look_dir := Vector2(clampf(lean_x * 0.25, -4.0, 4.0), 0.0)
    var e_style := "normal"
    var m_style := "smile"
    if react_ratio > 0.0:
        if last_grade == "Perfect":
            e_style = "happy"
            m_style = "big_grin"
        elif last_grade == "Good":
            e_style = "wide"
            m_style = "open_o"
        else:
            e_style = "dizzy"
            m_style = "frown"
    CartoonDraw.draw_eyes(self, head_c + Vector2(0, 0), 16.0, 4.0, e_style, look_dir)
    CartoonDraw.draw_mouth(self, head_c + Vector2(0, 12), 14.0, 9.0, m_style)

    # Iconic "YOU" badge above Chef Mimo (matching Reference Image 3!)
    CartoonDraw.draw_you_badge(self, hat_c + Vector2(0, -30.0), "YOU", true)

func _draw_cooking_stations(left_st: Vector2, right_st: Vector2, _beat: float, next_left: float, next_right: float, react_ratio: float) -> void:
    # Left Station: Sizzling Tomato-Red Skillet Pan
    var pan_bounce := 0.0
    if react_ratio > 0.0 and last_lane == "left" and last_grade != "Miss" and not reduced_motion:
        pan_bounce = -sin(react_ratio * PI) * 14.0
    var l_pos := left_st + Vector2(0, pan_bounce)
    var left_due := (next_left >= 0.0 and next_left <= 0.45)
    # Burner flame under pan
    var flame_col := CartoonDraw.GOLD if left_due else Color("ff7b3b")
    for fi in range(3):
        CartoonDraw.draw_outlined_circle(self, left_st + Vector2(-18 + float(fi) * 18, 6), 8.0 if left_due else 6.0, flame_col, CartoonDraw.INK, 2.5)
    # Skillet handle & body
    CartoonDraw.draw_limb(self, l_pos + Vector2(-38, -8), l_pos + Vector2(-72, -16), 5.5, CartoonDraw.INK, CartoonDraw.INK, 1.0)
    var pan_pts := PackedVector2Array([
        l_pos + Vector2(-46, -16),
        l_pos + Vector2(46, -16),
        l_pos + Vector2(36, 6),
        l_pos + Vector2(-36, 6),
    ])
    CartoonDraw.draw_outlined_polygon(self, pan_pts, CartoonDraw.GOLD if left_due else PAN_RED, CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_text(self, l_pos + Vector2(-40, 28), "◀ LEFT", 80, 14, CartoonDraw.PAPER, CartoonDraw.INK, 2.8)

    # Right Station: Golden Mixing Salad Bowl
    var bowl_bounce := 0.0
    if react_ratio > 0.0 and last_lane == "right" and last_grade != "Miss" and not reduced_motion:
        bowl_bounce = -sin(react_ratio * PI) * 14.0
    var r_pos := right_st + Vector2(0, bowl_bounce)
    var right_due := (next_right >= 0.0 and next_right <= 0.45)
    # Salad leaves peeking inside bowl
    CartoonDraw.draw_outlined_circle(self, r_pos + Vector2(-16, -22), 12.0, Color("56c963"), CartoonDraw.INK, 3.0)
    CartoonDraw.draw_outlined_circle(self, r_pos + Vector2(14, -22), 12.0, Color("56c963"), CartoonDraw.INK, 3.0)
    CartoonDraw.draw_outlined_circle(self, r_pos + Vector2(0, -24), 11.0, PAN_RED, CartoonDraw.INK, 3.0)
    var bowl_pts := PackedVector2Array([
        r_pos + Vector2(-48, -20),
        r_pos + Vector2(48, -20),
        r_pos + Vector2(32, 8),
        r_pos + Vector2(-32, 8),
    ])
    CartoonDraw.draw_outlined_polygon(self, bowl_pts, CartoonDraw.MINT if right_due else BOWL_GOLD, CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_text(self, r_pos + Vector2(-40, 28), "RIGHT ▶", 80, 14, CartoonDraw.PAPER, CartoonDraw.INK, 2.8)

func _draw_flying_ingredient(idx: int, lane_str: String, diff: float, is_hit: bool, left_st: Vector2, right_st: Vector2, beat: float) -> void:
    if is_hit:
        return
    var target := (left_st if lane_str == "left" else right_st) + Vector2(0, -24.0)
    var spawn := Vector2(size.x * 0.06, size.y * 0.34) if lane_str == "left" else Vector2(size.x * 0.94, size.y * 0.34)
    if diff < 0.0:
        # Missed / Splatting onto the counter!
        var splat_pos := target + Vector2(0, 24.0)
        CartoonDraw.draw_outlined_ellipse(self, splat_pos, 26.0, 9.0, 0.0, PAN_RED if lane_str == "left" else CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
        return

    var u := clampf(diff / 2.2, 0.0, 1.0)
    var arc_h := sin((1.0 - u) * PI) * minf(size.y * 0.32, 190.0)
    var pos := target.lerp(spawn, u) + Vector2(0, -arc_h)
    var rot := (0.0 if reduced_motion else (beat * 3.5 + float(idx)) * (1.0 if lane_str == "left" else -1.0))

    # Draw shadow/target ring on station when close (`diff <= 0.75`)
    if diff <= 0.75:
        var ring_r := lerpf(16.0, 42.0, clampf(diff / 0.75, 0.0, 1.0))
        var ring_col := CartoonDraw.GOLD if diff <= 0.22 else Color(1.0, 1.0, 1.0, 0.65)
        draw_arc(target, ring_r, 0.0, TAU, 24, ring_col, 3.5, true)

    # Distinct cute ingredient art per index!
    var kind := idx % 3
    if lane_str == "left":
        if kind == 0:
            # Smiling Red Tomato
            CartoonDraw.draw_outlined_circle(self, pos, 20.0, PAN_RED, CartoonDraw.INK, 3.8)
            CartoonDraw.draw_star(self, pos + Vector2(0, -16), 9.0, 4.0, 5, rot, Color("43b554"), CartoonDraw.INK, 2.5)
            CartoonDraw.draw_eyes(self, pos + Vector2(0, -2), 11.0, 3.0, "normal")
            CartoonDraw.draw_mouth(self, pos + Vector2(0, 6), 9.0, 5.0, "smile")
        else:
            # Sunny Golden Egg / Pepper
            CartoonDraw.draw_outlined_ellipse(self, pos, 22.0, 17.0, rot * 0.2, Color.WHITE, CartoonDraw.INK, 3.8)
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(2, 2), 9.0, CartoonDraw.GOLD, CartoonDraw.INK, 2.8)
    else:
        if kind == 0:
            # Bouncy Mint Herb / Broccoli
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(-8, -4), 13.0, Color("4cc968"), CartoonDraw.INK, 3.5)
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(8, -4), 13.0, Color("4cc968"), CartoonDraw.INK, 3.5)
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(0, -10), 15.0, Color("5ede79"), CartoonDraw.INK, 3.5)
            CartoonDraw.draw_outlined_box(self, Rect2(pos.x - 6, pos.y + 2, 12, 14), Color("a8e090"), CartoonDraw.INK, 3.2, 4.0)
            CartoonDraw.draw_eyes(self, pos + Vector2(0, -6), 10.0, 2.8, "normal")
        else:
            # Cute Cap Mushroom
            CartoonDraw.draw_outlined_box(self, Rect2(pos.x - 8, pos.y, 16, 16), CartoonDraw.PAPER, CartoonDraw.INK, 3.5, 5.0)
            CartoonDraw.draw_outlined_ellipse(self, pos + Vector2(0, -4), 22.0, 14.0, 0.0, Color("f08c4b"), CartoonDraw.INK, 3.8)
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(-8, -6), 4.5, CartoonDraw.PAPER, CartoonDraw.INK, 2.0)
            CartoonDraw.draw_outlined_circle(self, pos + Vector2(9, -5), 4.0, CartoonDraw.PAPER, CartoonDraw.INK, 2.0)

func _draw_kitchen_impact(center: Vector2, react_ratio: float) -> void:
    var spread := (1.0 - react_ratio) * 65.0 + 18.0
    if last_grade == "Perfect":
        CartoonDraw.draw_comic_burst(self, center, 42.0 * react_ratio + 14.0, 20.0 * react_ratio + 8.0, 8, react_ratio, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_heart(self, center + Vector2(-spread * 0.6, -spread * 0.8), 11.0 * react_ratio + 4.0, CartoonDraw.HOT_PINK, CartoonDraw.INK, 2.5)
        CartoonDraw.draw_star(self, center + Vector2(spread * 0.6, -spread * 0.7), 14.0 * react_ratio + 4.0, 6.0 * react_ratio + 2.0, 5, 0.3, CartoonDraw.MINT, CartoonDraw.INK, 2.5)
    elif last_grade == "Good":
        CartoonDraw.draw_comic_burst(self, center, 30.0 * react_ratio + 10.0, 15.0 * react_ratio + 5.0, 6, 0.2, CartoonDraw.MINT, CartoonDraw.INK, 2.8)
    else:
        CartoonDraw.draw_sweat_drop(self, center + Vector2(0, -28), 1.2)
