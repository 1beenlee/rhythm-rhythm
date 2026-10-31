extends RhythmVisual

const SKY_TOP := Color("0f1538")
const SKY_MID := Color("1c2564")
const BAND_BG := Color("101748")
const CANYON_FAR := Color("3d2952")
const CANYON_NEAR := Color("523661")
const GROUND_COL := Color("3b2747")
const ALIEN_TEAL := Color("5ce0c8")
const ALIEN_LAVENDER := Color("b49bff")
const VAN_MINT := Color("55b8a6")
const VAN_TRIM := Color("94a5e8")

func _draw() -> void:
    var w := size.x
    var h := size.y
    var beat := current_beat()
    var cycle_beat := fposmod(beat, 8.0)
    var is_response_turn := (cycle_beat >= 3.45 and cycle_beat <= 7.65) and beat < 48.0
    var pulse := 0.0 if reduced_motion else sin(beat * TAU)
    var half_pulse := 0.0 if reduced_motion else absf(sin(beat * PI))
    var next_diff := next_event_diff("tap")
    var ant_ratio := clampf(1.0 - (next_diff / 0.55), 0.0, 1.0) if (next_diff >= 0.0 and next_diff <= 0.55) else 0.0
    var react_ratio := clampf(reaction_timer / 0.45, 0.0, 1.0)

    # Check if the alien is currently singing a call note
    var active_call_tone := -1
    var call_pop := 0.0
    for c_item in chart.get("calls", []):
        var d := beat - float(c_item.get("beat", -99.0))
        if d >= -0.04 and d <= 0.42:
            active_call_tone = int(c_item.get("tone", 0))
            call_pop = clampf(1.0 - d / 0.42, 0.0, 1.0)

    # 1. Deep Cosmic Night Sky & Twinkling Stars
    draw_rect(Rect2(0, 0, w, h), SKY_MID)
    draw_rect(Rect2(0, 0, w, h * 0.45), SKY_TOP)
    var star_seeds := [
        Vector2(0.08, 0.06), Vector2(0.22, 0.04), Vector2(0.37, 0.07),
        Vector2(0.64, 0.05), Vector2(0.79, 0.08), Vector2(0.92, 0.05),
        Vector2(0.14, 0.30), Vector2(0.49, 0.28), Vector2(0.86, 0.29),
    ]
    for s_idx in range(star_seeds.size()):
        var sv: Vector2 = star_seeds[s_idx]
        var tw := 2.5 + (0.0 if reduced_motion else absf(sin(beat * 1.5 + float(s_idx))) * 2.5)
        draw_circle(Vector2(sv.x * w, sv.y * h), tw, Color(1.0, 0.98, 0.85, 0.85))

    # Sleepy / Grooving Crescent Moon in Upper Right
    var moon_pos := Vector2(w * 0.90, h * 0.13)
    CartoonDraw.draw_outlined_circle(self, moon_pos, 34.0, Color("ffe270"), CartoonDraw.INK, 3.8)
    CartoonDraw.draw_eyes(self, moon_pos + Vector2(-4, -2), 14.0, 3.2, "happy")
    CartoonDraw.draw_mouth(self, moon_pos + Vector2(-4, 8), 10.0, 6.0, "smile")

    # 2. Canyon Mesa Silhouettes & Desert Planet Ground (First Contact homage)
    var mesa_far := PackedVector2Array([
        Vector2(-10, h * 0.68),
        Vector2(0, h * 0.36),
        Vector2(w * 0.14, h * 0.38),
        Vector2(w * 0.22, h * 0.54),
        Vector2(w * 0.44, h * 0.52),
        Vector2(w * 0.52, h * 0.34),
        Vector2(w * 0.82, h * 0.32),
        Vector2(w + 10, h * 0.37),
        Vector2(w + 10, h * 0.68),
    ])
    CartoonDraw.draw_outlined_polygon(self, mesa_far, CANYON_FAR, CartoonDraw.INK, 4.0)
    draw_rect(Rect2(0, h * 0.63, w, h * 0.37), GROUND_COL)
    draw_line(Vector2(0, h * 0.63), Vector2(w, h * 0.63), CartoonDraw.INK, 4.5)

    # Winding alien desert road
    var road_pts := PackedVector2Array([
        Vector2(w * 0.24, h * 0.63),
        Vector2(w * 0.32, h * 0.63),
        Vector2(w * 0.18, h + 10),
        Vector2(-20, h + 10),
    ])
    draw_colored_polygon(road_pts, Color("57436e"))

    # Spotlight Cone showing LISTEN (Left Alien) vs YOUR TURN (Right Crew)
    var spot_x := w * 0.70 if is_response_turn else w * 0.28
    var spot_col := Color(0.38, 0.95, 0.82, 0.13) if is_response_turn else Color(0.75, 0.62, 1.0, 0.13)
    var spot_pts := PackedVector2Array([
        Vector2(spot_x, h * 0.24),
        Vector2(spot_x - w * 0.22, h),
        Vector2(spot_x + w * 0.22, h),
    ])
    draw_colored_polygon(spot_pts, spot_col)

    # 3. Upper Sky Call-and-Response Phrase Band (Syllable Star Icons!)
    var band_rect := Rect2(0, h * 0.09, w, h * 0.16)
    draw_rect(band_rect, Color(BAND_BG.r, BAND_BG.g, BAND_BG.b, 0.88))
    draw_line(Vector2(0, band_rect.position.y), Vector2(w, band_rect.position.y), CartoonDraw.INK, 3.5)
    draw_line(Vector2(0, band_rect.end.y), Vector2(w, band_rect.end.y), CartoonDraw.INK, 3.5)
    _draw_phrase_constellation_band(band_rect, beat, is_response_turn)

    # 4. Left Stage: Expressive Alien Lead Singer ("Luma-Lou") + Observer Photographer
    var observer_pos := Vector2(w * 0.11, h * 0.74)
    _draw_observer_character(observer_pos, beat, half_pulse, react_ratio)

    var alien_pos := Vector2(w * 0.31, h * 0.82)
    _draw_alien_singer(alien_pos, beat, half_pulse, active_call_tone, call_pop, react_ratio)

    # 5. Right Stage: Radar Van + Satellite Dish + Player Duo ("Pip & Astro" with YOU badge)
    var van_pos := Vector2(w * (0.67 if w < 500.0 else 0.72), h * 0.77)
    _draw_radar_van_and_crew(van_pos, beat, pulse, half_pulse, is_response_turn, ant_ratio, react_ratio)

    # 6. Neon Star Concert Burst on Hit!
    if react_ratio > 0.0:
        _draw_echo_hit_stars(Vector2(w * 0.72, h * 0.62), react_ratio)

    paint_feedback()

func _draw_phrase_constellation_band(band_rect: Rect2, beat: float, is_response_turn: bool) -> void:
    var cycle_start := floorf(beat / 8.0) * 8.0
    if cycle_start >= 48.0:
        cycle_start = 40.0
    var cy := band_rect.get_center().y

    # Collect calls and events in this 8-beat phrase
    var phrase_calls: Array = []
    for c_item in chart.get("calls", []):
        var cb := float(c_item.get("beat", 0.0))
        if cb >= cycle_start - 0.1 and cb < cycle_start + 4.0:
            phrase_calls.append(c_item)

    var phrase_events: Array = []
    var events: Array = chart.get("events", [])
    for i in range(events.size()):
        var eb := float(events[i].get("beat", 0.0))
        if eb >= cycle_start + 3.5 and eb < cycle_start + 8.0:
            phrase_events.append({"index": i, "beat": eb, "rel": eb - (cycle_start + 4.0)})

    # Left half of band: Alien Call Syllables (4-pointed cyan/gold stars)
    for ci in range(phrase_calls.size()):
        var c_data: Dictionary = phrase_calls[ci]
        var cb := float(c_data.get("beat", 0.0))
        var rel := cb - cycle_start
        var sx := band_rect.size.x * (0.20 + rel * 0.085)
        var sy := cy - float(int(c_data.get("tone", 0)) - 1) * 8.0
        var sung := beat >= cb - 0.05
        var active_now := absf(beat - cb) <= 0.28
        var r := 24.0 if active_now else (19.0 if sung else 13.0)
        var col := Color("9be8ff") if sung else Color("34437a")
        if active_now:
            col = CartoonDraw.GOLD
        CartoonDraw.draw_star(self, Vector2(sx, sy), r, r * 0.45, 4, 0.0, col, CartoonDraw.INK, 3.5)

    # Right half of band: Player Echo Planet Targets (ringed planets -> burst stars on hit!)
    for ei in range(phrase_events.size()):
        var e_data: Dictionary = phrase_events[ei]
        var idx: int = int(e_data["index"])
        var eb: float = float(e_data["beat"])
        var rel: float = float(e_data["rel"])
        var px := band_rect.size.x * (0.58 + rel * 0.085)
        var py := cy
        var ev_grade := event_grade(idx)
        var is_hit := (ev_grade == "Perfect" or ev_grade == "Good")
        var is_missed := (ev_grade == "Miss" or (not is_hit and beat - eb > 0.20))
        var is_due := absf(eb - beat) <= 0.25
        if is_hit:
            CartoonDraw.draw_star(self, Vector2(px, py), 24.0, 11.0, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 3.5)
            CartoonDraw.draw_neon_star_outline(self, Vector2(px, py), 31.0, 15.0, 5, beat * 1.2, CartoonDraw.MINT, 3.0)
        elif is_missed:
            CartoonDraw.draw_outlined_circle(self, Vector2(px, py), 14.0, Color("6e4259"), CartoonDraw.INK, 3.0)
            CartoonDraw.draw_eyes(self, Vector2(px, py), 10.0, 3.0, "dizzy")
        else:
            var p_col := CartoonDraw.GOLD if is_due else ( Color("9c7ae8") if is_response_turn else Color("4a3b78") )
            var pr := 18.0 if is_due else 15.0
            # Planet ring + sphere with "A" cue
            CartoonDraw.draw_outlined_ellipse(self, Vector2(px, py), pr * 1.55, pr * 0.48, -0.45, p_col.lightened(0.18), CartoonDraw.INK, 3.0)
            CartoonDraw.draw_outlined_circle(self, Vector2(px, py), pr, p_col, CartoonDraw.INK, 3.5)
            CartoonDraw.draw_outlined_text(self, Vector2(px - 14, py + 6), "A", 28, 15, CartoonDraw.PAPER, CartoonDraw.INK, 2.5)

func _draw_observer_character(pos: Vector2, _beat: float, half_pulse: float, react_ratio: float) -> void:
    var squat := 0.0 if reduced_motion else half_pulse * 4.0
    var p := pos + Vector2(0, squat)
    CartoonDraw.draw_outlined_ellipse(self, p, 24.0, 20.0, 0.0, Color("b89c46"), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, p + Vector2(0, -22), 16.0, Color("e8b496"), CartoonDraw.INK, 3.5)
    # Camera held in front of face
    CartoonDraw.draw_outlined_box(self, Rect2(p.x - 12, p.y - 28, 24, 15), Color("6e7d9c"), CartoonDraw.INK, 3.0, 4.0)
    CartoonDraw.draw_outlined_circle(self, p + Vector2(2, -20), 5.5, Color("aef2ff"), CartoonDraw.INK, 2.5)
    if react_ratio > 0.0 and last_grade == "Perfect":
        CartoonDraw.draw_star(self, p + Vector2(6, -20), 18.0 * react_ratio, 7.0 * react_ratio, 4, 0.2, Color.WHITE, CartoonDraw.GOLD, 2.0)

func _draw_alien_singer(base_pos: Vector2, beat: float, half_pulse: float, active_tone: int, call_pop: float, react_ratio: float) -> void:
    var bob := 0.0 if reduced_motion else half_pulse * 8.0
    var singing := active_tone >= 0
    var body_pos := base_pos + Vector2(0, -34.0 + bob)
    # Alien slender torso & outstretched arms
    var arm_lift := call_pop * 26.0 if singing else (0.0 if reduced_motion else half_pulse * 6.0)
    CartoonDraw.draw_limb(self, body_pos + Vector2(-14, -22), body_pos + Vector2(-46, 18 - arm_lift), 6.0, Color("66758a"), CartoonDraw.INK, 3.8)
    CartoonDraw.draw_limb(self, body_pos + Vector2(14, -22), body_pos + Vector2(48, 14 - arm_lift), 6.0, Color("66758a"), CartoonDraw.INK, 3.8)
    CartoonDraw.draw_outlined_ellipse(self, body_pos, 26.0, 46.0, 0.0, Color("66758a"), CartoonDraw.INK, 4.2)

    # Big Alien Head
    var head_pos := body_pos + Vector2(0, -68.0 - call_pop * 8.0)
    CartoonDraw.draw_outlined_ellipse(self, head_pos, 48.0, 38.0, -0.06, Color("75859c"), CartoonDraw.INK, 4.5)
    # Big Mint-Green Alien Side Eye & Expressive Face
    CartoonDraw.draw_outlined_ellipse(self, head_pos + Vector2(36, -2), 12.0, 17.0, 0.1, ALIEN_TEAL, CartoonDraw.INK, 3.8)
    draw_circle(head_pos + Vector2(39, -4), 5.0, CartoonDraw.INK)
    draw_circle(head_pos + Vector2(37, -7), 2.0, Color.WHITE)
    CartoonDraw.draw_outlined_ellipse(self, head_pos + Vector2(8, -2), 11.0, 15.0, 0.0, ALIEN_TEAL, CartoonDraw.INK, 3.5)
    draw_circle(head_pos + Vector2(11, -4), 4.5, CartoonDraw.INK)

    # Antenna on top of Alien Head
    var ant_base := head_pos + Vector2(4, -36)
    var ant_sway := 0.0 if reduced_motion else sin(beat * TAU) * 12.0
    var ant_tip := ant_base + Vector2(ant_sway, -34.0 - call_pop * 10.0)
    draw_line(ant_base, ant_tip, CartoonDraw.INK, 4.5, true)
    var orb_col := CartoonDraw.GOLD if singing else Color("8596b0")
    CartoonDraw.draw_outlined_circle(self, ant_tip, 13.0 + call_pop * 4.0, orb_col, CartoonDraw.INK, 3.8)

    # Singing Mouth & Speech Wave
    var m_style := "smile"
    if singing:
        m_style = "open_a" if active_tone >= 2 else "open_o"
    elif react_ratio > 0.0:
        m_style = "big_grin" if last_grade == "Perfect" else ("frown" if last_grade == "Miss" else "smile")
    CartoonDraw.draw_mouth(self, head_pos + Vector2(24, 16), 20.0, 14.0, m_style)

    if singing:
        var wave_center := head_pos + Vector2(68, -10)
        for wi in range(2):
            var wr := 18.0 + float(wi) * 14.0 + (1.0 - call_pop) * 12.0
            draw_arc(wave_center, wr, -0.6, 0.6, 12, CartoonDraw.GOLD, 3.5, true)
        CartoonDraw.draw_music_note(self, wave_center + Vector2(26, -18 - (1.0 - call_pop) * 12.0), 1.0, CartoonDraw.MINT, CartoonDraw.INK)

func _draw_radar_van_and_crew(van_pos: Vector2, beat: float, pulse: float, half_pulse: float, is_response_turn: bool, ant_ratio: float, react_ratio: float) -> void:
    # Retro Space Van
    var vw := minf(168.0, size.x * 0.40)
    var vh := 102.0
    var vrect := Rect2(van_pos.x - vw * 0.5, van_pos.y - vh, vw, vh)
    CartoonDraw.draw_outlined_box(self, vrect, VAN_MINT, CartoonDraw.INK, 4.2, 10.0)
    CartoonDraw.draw_outlined_box(self, Rect2(vrect.position.x - 4, vrect.end.y - 22, vw + 8, 22), VAN_TRIM, CartoonDraw.INK, 3.8, 6.0)
    # Van Windows
    CartoonDraw.draw_outlined_box(self, Rect2(vrect.position.x + 14, vrect.position.y + 14, 48, 38), Color("2941ab"), CartoonDraw.INK, 3.5, 6.0)
    CartoonDraw.draw_outlined_box(self, Rect2(vrect.position.x + 74, vrect.position.y + 14, 76, 38), Color("2941ab"), CartoonDraw.INK, 3.5, 6.0)
    # Wheels
    CartoonDraw.draw_outlined_circle(self, Vector2(vrect.position.x + 34, vrect.end.y + 2), 16.0, Color("2e3244"), CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_circle(self, Vector2(vrect.end.x - 34, vrect.end.y + 2), 16.0, Color("2e3244"), CartoonDraw.INK, 4.0)

    # Rotating Satellite Dish on Van Roof
    var dish_base := Vector2(van_pos.x + 18, vrect.position.y)
    CartoonDraw.draw_limb(self, dish_base, dish_base + Vector2(0, -32), 5.0, VAN_TRIM, CartoonDraw.INK, 3.5)
    var dish_tilt := -0.55 + (0.0 if reduced_motion else pulse * 0.08) - ant_ratio * 0.18
    if react_ratio > 0.0 and last_grade != "Miss":
        dish_tilt -= sin(react_ratio * PI) * 0.25
    var dish_center := dish_base + Vector2(-8, -48)
    CartoonDraw.draw_outlined_ellipse(self, dish_center, 46.0, 14.0, dish_tilt, ALIEN_LAVENDER, CartoonDraw.INK, 4.0)
    var feed_pos := dish_center + Vector2(-24, -22)
    draw_line(dish_center + Vector2(-20, 8), feed_pos, CartoonDraw.INK, 3.0)
    draw_line(dish_center + Vector2(20, -8), feed_pos, CartoonDraw.INK, 3.0)
    var feed_col := CartoonDraw.GOLD if (is_response_turn or react_ratio > 0.0) else VAN_TRIM
    CartoonDraw.draw_outlined_circle(self, feed_pos, 9.0, feed_col, CartoonDraw.INK, 3.2)

    # Player Responder Characters standing in front of Van ("Pip" & "Astro")
    var bounce := 0.0 if reduced_motion else half_pulse * 6.0
    var jump := 0.0
    if react_ratio > 0.0 and last_grade != "Miss" and not reduced_motion:
        jump = sin(react_ratio * PI) * 18.0

    var pip_pos := Vector2(van_pos.x - 36, van_pos.y + 8 - bounce - jump)
    var astro_pos := Vector2(van_pos.x + 34, van_pos.y + 8 - bounce * 0.85 - jump)
    _draw_crew_kid(pip_pos, Color("d938bf"), Color("e85d3f"), false, is_response_turn, ant_ratio, react_ratio)
    _draw_crew_kid(astro_pos, Color("62b6cb"), Color("f0e168"), true, is_response_turn, ant_ratio, react_ratio)

    # Iconic "You" label underneath Player Character (matching Reference Image 2!)
    CartoonDraw.draw_you_badge(self, Vector2(pip_pos.x, van_pos.y + 22), "YOU", false)

func _draw_crew_kid(pos: Vector2, outfit_col: Color, hair_col: Color, has_glasses: bool, is_turn: bool, ant_ratio: float, react_ratio: float) -> void:
    # Legs
    CartoonDraw.draw_limb(self, pos + Vector2(-8, -8), pos + Vector2(-10, 8), 4.5, Color("f2d3ab"), CartoonDraw.INK, 3.2)
    CartoonDraw.draw_limb(self, pos + Vector2(8, -8), pos + Vector2(10, 8), 4.5, Color("f2d3ab"), CartoonDraw.INK, 3.2)
    # Arms (raise hands when singing back!)
    var arm_up := 18.0 if (react_ratio > 0.0 and last_grade != "Miss") else (ant_ratio * 10.0)
    CartoonDraw.draw_limb(self, pos + Vector2(-14, -28), pos + Vector2(-24, -12 - arm_up), 4.5, outfit_col, CartoonDraw.INK, 3.2)
    CartoonDraw.draw_limb(self, pos + Vector2(14, -28), pos + Vector2(24, -12 - arm_up), 4.5, outfit_col, CartoonDraw.INK, 3.2)
    # Body
    CartoonDraw.draw_outlined_box(self, Rect2(pos.x - 16, pos.y - 36, 32, 28), outfit_col, CartoonDraw.INK, 3.8, 8.0)
    # Head
    var hpos := pos + Vector2(0, -54)
    CartoonDraw.draw_outlined_circle(self, hpos, 20.0, Color("f5d5b0"), CartoonDraw.INK, 3.8)
    # Hair
    CartoonDraw.draw_outlined_ellipse(self, hpos + Vector2(0, -14), 20.0, 9.0, 0.0, hair_col, CartoonDraw.INK, 3.5)
    # Eyes & Mouth
    var e_style := "normal"
    var m_style := "smile"
    if react_ratio > 0.0:
        if last_grade == "Perfect":
            e_style = "happy"
            m_style = "open_a"
        elif last_grade == "Good":
            e_style = "wide"
            m_style = "open_o"
        else:
            e_style = "dizzy"
            m_style = "frown"
    elif ant_ratio > 0.2 or is_turn:
        e_style = "wide"
        m_style = "open_o"
    if has_glasses:
        CartoonDraw.draw_outlined_box(self, Rect2(hpos.x - 14, hpos.y - 6, 12, 9), Color.WHITE, CartoonDraw.INK, 2.5, 2.0)
        CartoonDraw.draw_outlined_box(self, Rect2(hpos.x + 2, hpos.y - 6, 12, 9), Color.WHITE, CartoonDraw.INK, 2.5, 2.0)
    else:
        CartoonDraw.draw_eyes(self, hpos + Vector2(0, -2), 12.0, 3.0, e_style)
    CartoonDraw.draw_mouth(self, hpos + Vector2(0, 8), 11.0, 7.0, m_style)

func _draw_echo_hit_stars(center: Vector2, react_ratio: float) -> void:
    var spread := (1.0 - react_ratio) * 95.0 + 28.0
    if last_grade == "Perfect":
        var colors := [CartoonDraw.GOLD, CartoonDraw.MINT, CartoonDraw.HOT_PINK, CartoonDraw.SKY_BLUE, Color("fff380")]
        for i in range(5):
            var a := -PI * 0.9 + float(i) * (PI * 0.8 / 4.0)
            var sp := center + Vector2(cos(a), sin(a)) * spread
            CartoonDraw.draw_neon_star_outline(self, sp, 24.0 * react_ratio + 8.0, 11.0 * react_ratio + 4.0, 5, a + react_ratio, colors[i], 3.8)
    elif last_grade == "Good":
        CartoonDraw.draw_neon_star_outline(self, center + Vector2(0, -40), 26.0 * react_ratio + 8.0, 12.0 * react_ratio + 4.0, 5, 0.2, CartoonDraw.MINT, 3.5)
    else:
        CartoonDraw.draw_sweat_drop(self, center + Vector2(-48, -32), 1.3)
