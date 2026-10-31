extends Control
class_name StageUIArt

var mode := "home_banner"
var game_id := "beat_factory"
var grade_tier := "SUPERB"
var reduced_motion := false
var anim_time := 0.0
var rehearsal_flash := 0.0
var rehearsal_grade := "Perfect"

func setup(art_mode: String, target_game_id: String = "beat_factory", result_tier: String = "SUPERB", min_motion: bool = false) -> StageUIArt:
    mode = art_mode
    game_id = target_game_id
    grade_tier = result_tier
    reduced_motion = min_motion
    clip_contents = true
    set_process(true)
    return self

func trigger_rehearsal_hit(grade: String = "Perfect") -> void:
    rehearsal_grade = grade
    rehearsal_flash = 0.40
    queue_redraw()

func _process(delta: float) -> void:
    if not reduced_motion:
        anim_time += delta
    rehearsal_flash = maxf(0.0, rehearsal_flash - delta)
    queue_redraw()

func _draw() -> void:
    match mode:
        "home_banner":
            _draw_home_banner()
        "poster_card":
            _draw_poster_card()
        "rehearsal_stage":
            _draw_rehearsal_stage()
        "result_vignette":
            _draw_result_vignette()

func _draw_home_banner() -> void:
    var w := size.x
    var h := size.y
    var beat := anim_time * 1.8
    var bob := 0.0 if reduced_motion else absf(sin(beat * PI)) * 7.0

    # Vibrant Yellow Rhythm Heaven Groove Backdrop
    CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), Color("ffe033"), CartoonDraw.INK, 4.5, 22.0)

    # Radiating Dotted Rhythm Arcs (like Reference Image 1!)
    var center := Vector2(w * 0.48, h * 0.42)
    var dot_colors := [Color("ff7a33"), Color("34c9b9"), Color("ff4da6")]
    for ring in range(3):
        var r := minf(w, h) * (0.36 + float(ring) * 0.11)
        var dcol: Color = dot_colors[ring % 3]
        for di in range(20):
            var a := TAU * float(di) / 20.0 + (0.0 if reduced_motion else anim_time * 0.25 * (1.0 if ring % 2 == 0 else -1.0))
            var dp := center + Vector2(cos(a) * r * 1.25, sin(a) * r * 0.78)
            if dp.x > 16 and dp.x < w - 16 and dp.y > 16 and dp.y < h - 16:
                draw_circle(dp, 5.5, dcol)

    # Floating Pink/Silver UFO on Upper Left & Sleepy Moon on Upper Right
    var ufo_pos := Vector2(w * 0.14, h * 0.24 - bob * 0.6)
    CartoonDraw.draw_outlined_ellipse(self, ufo_pos, 48.0, 16.0, -0.18, Color("d4dce3"), CartoonDraw.INK, 3.8)
    CartoonDraw.draw_outlined_ellipse(self, ufo_pos + Vector2(2, -10), 24.0, 14.0, -0.18, Color("fff380"), CartoonDraw.INK, 3.2)
    CartoonDraw.draw_outlined_ellipse(self, ufo_pos + Vector2(-2, 8), 32.0, 9.0, -0.18, CartoonDraw.HOT_PINK, CartoonDraw.INK, 3.2)

    var moon_pos := Vector2(w * 0.88, h * 0.18)
    CartoonDraw.draw_outlined_circle(self, moon_pos, 28.0, Color("ffd24c"), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_eyes(self, moon_pos + Vector2(-3, -2), 12.0, 3.0, "happy")
    CartoonDraw.draw_mouth(self, moon_pos + Vector2(-3, 7), 9.0, 5.0, "smile")

    # Floating Musical Notes
    CartoonDraw.draw_music_note(self, Vector2(w * 0.24, h * 0.44 - bob), 1.1, CartoonDraw.CORAL, CartoonDraw.INK)
    CartoonDraw.draw_music_note(self, Vector2(w * 0.77, h * 0.26 - bob * 0.8), 1.15, Color("b85cff"), CartoonDraw.INK)

    # Big Thick-Outlined Cloud Logo ("RHYTHM RHYTHM" + "GROOVE v0.2" Star Banner)
    var cloud_c := Vector2(w * 0.48, h * 0.36)
    var cloud_offsets := [
        Vector2(-88, 6), Vector2(-42, -26), Vector2(18, -32),
        Vector2(76, -12), Vector2(96, 18), Vector2(-64, 28), Vector2(24, 28)
    ]
    for co in cloud_offsets:
        var cv: Vector2 = co
        draw_circle(cloud_c + cv, 46.0, Color.WHITE)
    for co in cloud_offsets:
        var cv: Vector2 = co
        CartoonDraw.draw_outlined_circle(self, cloud_c + cv, 40.0, CartoonDraw.INK, CartoonDraw.INK, 2.0)
    draw_rect(Rect2(cloud_c.x - 85, cloud_c.y - 26, 175, 56), CartoonDraw.INK)

    CartoonDraw.draw_outlined_text(self, Vector2(cloud_c.x - 135, cloud_c.y - 4), "RHYTHM", 270, 34, Color("ffb82e"), CartoonDraw.INK, 4.0)
    CartoonDraw.draw_outlined_text(self, Vector2(cloud_c.x - 135, cloud_c.y + 28), "RHYTHM", 270, 34, Color("ff5c2b"), CartoonDraw.INK, 4.0)

    # Purple/Blue Star Banner ("GROOVE SHOW")
    var banner_rect := Rect2(cloud_c.x - 108, cloud_c.y + 36, 216, 34)
    CartoonDraw.draw_star(self, banner_rect.position + Vector2(6, 17), 26.0, 12.0, 5, -0.4, Color("d946ef"), CartoonDraw.INK, 3.2)
    CartoonDraw.draw_outlined_box(self, banner_rect, Color("4f46e5"), CartoonDraw.INK, 3.8, 10.0)
    CartoonDraw.draw_outlined_text(self, Vector2(banner_rect.position.x, banner_rect.position.y + 24), "★ GROOVE SHOW ★", int(banner_rect.size.x), 19, Color.WHITE, CartoonDraw.INK, 3.0)

    # Bottom Parade of Characters (Poko, Alien Luma-Lou, Chef Mimo & Nori Cat)
    var ground_y := h - 18.0
    draw_rect(Rect2(6, ground_y, w - 12, 14), Color("5ac949"))
    draw_line(Vector2(6, ground_y), Vector2(w - 6, ground_y), CartoonDraw.INK, 3.5)

    # Left: Poko (Factory Worker)
    var p1 := Vector2(w * 0.20, ground_y - 18.0 - bob)
    CartoonDraw.draw_outlined_circle(self, p1, 18.0, Color("ffdfb8"), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_ellipse(self, p1 + Vector2(0, -14), 20.0, 11.0, 0.0, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
    CartoonDraw.draw_eyes(self, p1 + Vector2(2, -1), 10.0, 3.0, "happy")
    CartoonDraw.draw_mouth(self, p1 + Vector2(2, 7), 9.0, 5.0, "big_grin")

    # Center-Right: Alien Luma-Lou
    var p2 := Vector2(w * 0.76, ground_y - 20.0 - bob * 0.8)
    draw_line(p2 + Vector2(0, -18), p2 + Vector2(6, -34), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, p2 + Vector2(6, -34), 7.0, CartoonDraw.MINT, CartoonDraw.INK, 2.8)
    CartoonDraw.draw_outlined_ellipse(self, p2, 22.0, 17.0, 0.0, Color("75859c"), CartoonDraw.INK, 3.5)
    CartoonDraw.draw_outlined_circle(self, p2 + Vector2(-7, -2), 5.5, CartoonDraw.MINT, CartoonDraw.INK, 2.5)
    CartoonDraw.draw_outlined_circle(self, p2 + Vector2(7, -2), 5.5, CartoonDraw.MINT, CartoonDraw.INK, 2.5)

    # Right: White Cat Nori
    var p3 := Vector2(w * 0.89, ground_y - 16.0 - bob * 1.1)
    CartoonDraw.draw_outlined_circle(self, p3, 15.0, Color.WHITE, CartoonDraw.INK, 3.2)
    CartoonDraw.draw_eyes(self, p3, 9.0, 2.5, "happy")
    CartoonDraw.draw_mouth(self, p3 + Vector2(0, 5), 7.0, 4.0, "cat")

func _draw_poster_card() -> void:
    var w := size.x
    var h := size.y
    var bob := 0.0 if reduced_motion else absf(sin(anim_time * 3.2)) * 5.0
    if game_id == "beat_factory":
        CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), Color("f6dfc2"), CartoonDraw.INK, 3.8, 14.0)
        # Mini Conveyor & Stamper + Poko
        CartoonDraw.draw_outlined_box(self, Rect2(8, h * 0.72, w - 16, 22), Color("433633"), CartoonDraw.INK, 3.2, 6.0)
        CartoonDraw.draw_outlined_box(self, Rect2(w * 0.52, 8, 52, 38 + bob), Color("56b89e"), CartoonDraw.INK, 3.5, 10.0)
        CartoonDraw.draw_outlined_box(self, Rect2(w * 0.56, h * 0.46, 44, 34), Color("fff8e7"), CartoonDraw.INK, 3.2, 6.0)
        CartoonDraw.draw_star(self, Vector2(w * 0.68, h * 0.58), 10.0, 4.5, 5, -PI * 0.5, CartoonDraw.GOLD, CartoonDraw.INK, 2.2)
        var pk := Vector2(w * 0.28, h * 0.54 - bob)
        CartoonDraw.draw_outlined_circle(self, pk, 20.0, Color("ffdfb8"), CartoonDraw.INK, 3.5)
        CartoonDraw.draw_outlined_ellipse(self, pk + Vector2(0, -15), 22.0, 12.0, 0.0, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_eyes(self, pk + Vector2(2, -2), 11.0, 3.0, "happy")
        CartoonDraw.draw_mouth(self, pk + Vector2(2, 7), 10.0, 6.0, "big_grin")
    elif game_id == "echo_planet":
        CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), Color("1c2564"), CartoonDraw.INK, 3.8, 14.0)
        CartoonDraw.draw_star(self, Vector2(w * 0.25, h * 0.24), 14.0, 6.0, 4, 0.0, Color("9be8ff"), CartoonDraw.INK, 2.8)
        CartoonDraw.draw_star(self, Vector2(w * 0.48, h * 0.22), 16.0, 7.0, 4, 0.0, CartoonDraw.GOLD, CartoonDraw.INK, 2.8)
        CartoonDraw.draw_neon_star_outline(self, Vector2(w * 0.74, h * 0.26), 18.0, 8.0, 5, anim_time, CartoonDraw.MINT, 3.0)
        var al := Vector2(w * 0.34, h * 0.64 - bob)
        draw_line(al + Vector2(0, -20), al + Vector2(6, -38), CartoonDraw.INK, 3.5)
        CartoonDraw.draw_outlined_circle(self, al + Vector2(6, -38), 8.0, CartoonDraw.GOLD, CartoonDraw.INK, 2.8)
        CartoonDraw.draw_outlined_ellipse(self, al, 26.0, 20.0, 0.0, Color("75859c"), CartoonDraw.INK, 3.5)
        CartoonDraw.draw_outlined_circle(self, al + Vector2(10, -2), 7.0, Color("5ce0c8"), CartoonDraw.INK, 2.8)
        var kid := Vector2(w * 0.72, h * 0.66 - bob * 0.8)
        CartoonDraw.draw_outlined_circle(self, kid, 17.0, Color("f5d5b0"), CartoonDraw.INK, 3.2)
        CartoonDraw.draw_eyes(self, kid, 10.0, 2.8, "happy")
        CartoonDraw.draw_mouth(self, kid + Vector2(0, 6), 9.0, 5.0, "open_a")
    else:
        CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), Color("fff6df"), CartoonDraw.INK, 3.8, 14.0)
        CartoonDraw.draw_outlined_box(self, Rect2(8, h * 0.72, w - 16, 22), Color("a8422b"), CartoonDraw.INK, 3.2, 6.0)
        var ch := Vector2(w * 0.50, h * 0.56 - bob)
        CartoonDraw.draw_outlined_circle(self, ch + Vector2(0, -24), 16.0, Color.WHITE, CartoonDraw.INK, 3.2)
        CartoonDraw.draw_outlined_circle(self, ch, 19.0, Color("f5d2b0"), CartoonDraw.INK, 3.5)
        CartoonDraw.draw_eyes(self, ch, 11.0, 3.0, "happy")
        CartoonDraw.draw_mouth(self, ch + Vector2(0, 7), 10.0, 6.0, "big_grin")
        CartoonDraw.draw_outlined_circle(self, Vector2(w * 0.24, h * 0.42 - bob * 1.4), 14.0, Color("eb524a"), CartoonDraw.INK, 3.0)
        CartoonDraw.draw_outlined_circle(self, Vector2(w * 0.78, h * 0.42 - bob * 1.4), 14.0, Color("4cc968"), CartoonDraw.INK, 3.0)

func _draw_rehearsal_stage() -> void:
    var w := size.x
    var h := size.y
    var beat := fposmod(anim_time * 1.7, 4.0)
    var react := clampf(rehearsal_flash / 0.40, 0.0, 1.0)
    CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), Color("fff8ea"), CartoonDraw.INK, 4.0, 18.0)

    # 4-Beat Interactive Rhythm Cue Meter ("1 - 2 - 3 - TAP!")
    var labels := ["1", "2", "3", "TAP! ★"]
    for bi in range(4):
        var bx := w * (0.20 + float(bi) * 0.20)
        var by := h * 0.36
        var active_b := int(floorf(beat)) == bi
        var col := CartoonDraw.GOLD if (bi == 3 and active_b) else (CartoonDraw.MINT if active_b else Color("e6dec8"))
        var r := 28.0 if active_b else 22.0
        if bi == 3:
            CartoonDraw.draw_star(self, Vector2(bx, by), r * 1.25, r * 0.58, 5, -PI * 0.5, col, CartoonDraw.INK, 3.5)
        else:
            CartoonDraw.draw_outlined_circle(self, Vector2(bx, by), r, col, CartoonDraw.INK, 3.5)
        CartoonDraw.draw_outlined_text(self, Vector2(bx - 36, by + 44), labels[bi], 72, 16, CartoonDraw.INK, Color.WHITE, 2.5)

    # Mascot Reaction feedback when player tests a tap in Rehearsal!
    var status_msg := "Listen to the 4-beat groove, or press PRACTICE TAP below to test the sound!"
    if react > 0.0:
        status_msg = "★ %s GROOVE! SOUND & INPUT LOCKED IN! ★" % rehearsal_grade.to_upper()
        CartoonDraw.draw_comic_burst(self, Vector2(w * 0.5, h * 0.76), 54.0 * react + 20.0, 30.0 * react + 10.0, 10, react, CartoonDraw.GOLD, CartoonDraw.INK, 3.2)
    CartoonDraw.draw_outlined_text(self, Vector2(16, h * 0.84), status_msg, int(w - 32), 17, CartoonDraw.INK, Color.WHITE, 2.5)

func _draw_result_vignette() -> void:
    var w := size.x
    var h := size.y
    var bob := 0.0 if reduced_motion else absf(sin(anim_time * 3.6)) * 8.0
    var bg_col := Color("ffe359") if grade_tier == "SUPERB" else (Color("aef2d6") if grade_tier == "OK" else Color("d8c8d6"))
    CartoonDraw.draw_outlined_box(self, Rect2(2, 2, w - 4, h - 4), bg_col, CartoonDraw.INK, 4.5, 20.0)

    if grade_tier == "SUPERB":
        for si in range(6):
            var sx := w * (0.10 + float(si) * 0.16)
            var sy := h * (0.22 if si % 2 == 0 else 0.72)
            CartoonDraw.draw_neon_star_outline(self, Vector2(sx, sy), 24.0, 11.0, 5, anim_time + float(si), CartoonDraw.HOT_PINK if si % 2 == 0 else CartoonDraw.MINT, 3.5)

    # Center Character Vignette Reaction
    var mc := Vector2(w * 0.28, h * 0.54 - (bob if grade_tier != "TRY AGAIN" else 0.0))
    CartoonDraw.draw_outlined_circle(self, mc, 38.0, Color("ffdfb8"), CartoonDraw.INK, 4.2)
    var eye_st := "happy" if grade_tier == "SUPERB" else ("normal" if grade_tier == "OK" else "dizzy")
    var mouth_st := "big_grin" if grade_tier == "SUPERB" else ("smile" if grade_tier == "OK" else "frown")
    CartoonDraw.draw_eyes(self, mc + Vector2(0, -4), 20.0, 4.5, eye_st)
    CartoonDraw.draw_mouth(self, mc + Vector2(0, 12), 18.0, 11.0, mouth_st)
    if grade_tier == "SUPERB":
        CartoonDraw.draw_star(self, mc + Vector2(0, -44), 18.0, 8.0, 5, -PI * 0.5, CartoonDraw.CORAL, CartoonDraw.INK, 3.0)
    elif grade_tier == "TRY AGAIN":
        CartoonDraw.draw_sweat_drop(self, mc + Vector2(-42, -16), 1.3)

    # Big Grade Stamp on Right Side of Vignette
    var stamp_c := Vector2(w * 0.66, h * 0.52)
    var stamp_col: Color = CartoonDraw.CORAL if grade_tier == "SUPERB" else (RhythmTokens.PERFECT if grade_tier == "OK" else RhythmTokens.MUTED)
    CartoonDraw.draw_outlined_box(self, Rect2(stamp_c.x - 115, stamp_c.y - 36, 230, 72), stamp_col, CartoonDraw.INK, 4.5, 16.0)
    var title_str := "★ SUPERB! ★" if grade_tier == "SUPERB" else ("♪ OK! GOOD SHOW ♪" if grade_tier == "OK" else "TRY AGAIN...")
    CartoonDraw.draw_outlined_text(self, Vector2(stamp_c.x - 110, stamp_c.y + 9), title_str, 220, 24, Color.WHITE, CartoonDraw.INK, 3.5)
