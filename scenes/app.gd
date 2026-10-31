extends Control

var games: Array[Dictionary] = []
var profile: Dictionary = {}
var selected: Dictionary = {}
var session: RhythmSession
var visual: RhythmVisual
var page: Control
var body: VBoxContainer
var hud: Label
var status: Label
var countdown_text: Label
var debug_label: Label
var pause_modal: Control
var rehearsal_art: StageUIArt
var preview_sfx: AudioStreamPlayer
var debug_open := false
var page_name := "home"
var latest_summary: Dictionary = {}

func _ready() -> void:
    preview_sfx = AudioStreamPlayer.new()
    add_child(preview_sfx)
    get_window().size_changed.connect(_adapt_viewport)
    _adapt_viewport()
    games = GameRegistry.discover()
    profile = RhythmSave.settings()
    _home()

func _adapt_viewport() -> void:
    var screen := get_window().size
    var base := Vector2i(420, 800) if screen.x < screen.y else Vector2i(960, 640)
    if get_window().content_scale_size != base:
        get_window().content_scale_size = base

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(session):
        if page_name == "play":
            session.pause_session()
            _update_pause_hint()

func _input(event: InputEvent) -> void:
    if page_name == "guide" and event is InputEventKey and event.pressed and not event.echo:
        var gkey: int = (event as InputEventKey).keycode
        if gkey in [KEY_SPACE, KEY_F, KEY_J, KEY_A, KEY_L, KEY_LEFT, KEY_RIGHT]:
            _rehearsal_tap()
            get_viewport().set_input_as_handled()
        return
    if page_name != "play" or not is_instance_valid(session):
        return
    if event is InputEventKey and event.pressed and not event.echo:
        var key: int = (event as InputEventKey).keycode
        if key == KEY_F3:
            debug_open = not debug_open
            if is_instance_valid(debug_label):
                debug_label.visible = debug_open
            if is_instance_valid(hud):
                hud.visible = debug_open
        elif key == KEY_ESCAPE or key == KEY_P:
            _toggle_pause()
        elif not session.paused:
            if selected["id"] == "rhythm_kitchen":
                if key == KEY_A or key == KEY_LEFT:
                    session.submit("left")
                elif key == KEY_L or key == KEY_RIGHT:
                    session.submit("right")
            elif key == KEY_SPACE or key == KEY_F or key == KEY_J:
                session.submit("tap")
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if page_name != "play" or not is_instance_valid(session):
        return
    if is_instance_valid(pause_modal) and pause_modal.visible != session.paused:
        _update_pause_hint()
    if is_instance_valid(debug_label) and debug_open:
        debug_label.text = "DEBUG | audio %.3fs | mix %.3fs | latency %.3fs | input %dms | output %dms" % [session.audio.get_playback_position(), AudioServer.get_time_since_last_mix(), AudioServer.get_output_latency(), int(profile["input_ms"]), int(profile["output_ms"])]
    if is_instance_valid(hud):
        var beat := session.song_time * float(session.chart["bpm"]) / 60.0
        hud.text = "SCORE %06d   COMBO %d   BEAT %.1f" % [session.score, session.combo, beat]

func _reset_page(name: String, margin_px: int = 16) -> void:
    page_name = name
    if is_instance_valid(page):
        page.queue_free()
    page = Control.new()
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(page)
    var background := ColorRect.new()
    background.color = Color("1f1924") if name == "play" else RhythmTokens.SKY
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    page.add_child(background)
    var margins := MarginContainer.new()
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margins.add_theme_constant_override("margin_left", margin_px)
    margins.add_theme_constant_override("margin_right", margin_px)
    margins.add_theme_constant_override("margin_top", margin_px)
    margins.add_theme_constant_override("margin_bottom", margin_px)
    page.add_child(margins)
    body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    margins.add_child(body)

func _text(value: String, size_px: int = 20, color: Color = RhythmTokens.INK) -> Label:
    var item := Label.new()
    item.text = value
    item.add_theme_font_size_override("font_size", size_px)
    item.add_theme_color_override("font_color", color)
    item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(item)
    return item

func _button(value: String, fn: Callable, accent: Color = RhythmTokens.LAVENDER) -> Button:
    var button := Button.new()
    button.text = value
    RhythmTokens.style_button(button, accent)
    button.pressed.connect(fn)
    body.add_child(button)
    return button

func _spacer() -> void:
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(spacer)

func _heading(title: String, subtitle: String) -> void:
    _text(title, 30, RhythmTokens.INK)
    _text(subtitle, 15, RhythmTokens.MUTED)

func _home() -> void:
    _dispose_session()
    _reset_page("home", 18)
    var banner := StageUIArt.new().setup("home_banner", "beat_factory", "SUPERB", bool(profile.get("reduced_motion", false)))
    banner.size_flags_vertical = Control.SIZE_EXPAND_FILL
    banner.custom_minimum_size = Vector2(0, 290)
    body.add_child(banner)

    var play_btn := _button("★  ENTER THE GROOVE SHOW  ★", _select_games, RhythmTokens.CORAL)
    play_btn.custom_minimum_size.y = 58
    play_btn.add_theme_font_size_override("font_size", 22)

    var sub_row := HBoxContainer.new()
    sub_row.add_theme_constant_override("separation", 12)
    body.add_child(sub_row)
    var set_btn := Button.new()
    set_btn.text = "⚙ TIMING & AUDIO"
    RhythmTokens.style_button(set_btn, RhythmTokens.AQUA, Vector2(140, 46), 17)
    set_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    set_btn.pressed.connect(_settings_page)
    sub_row.add_child(set_btn)

    var off_btn := Button.new()
    off_btn.text = "✈ OFFLINE READY"
    RhythmTokens.style_button(off_btn, RhythmTokens.YELLOW, Vector2(140, 46), 17)
    off_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    off_btn.pressed.connect(_offline_page)
    sub_row.add_child(off_btn)

    _text("Three Original Cartoon Music Worlds · 44.1kHz Stereo Soundtrack · v0.2", 13, RhythmTokens.MUTED)

func _select_games() -> void:
    var is_portrait := get_window().size.x < get_window().size.y
    _reset_page("select", 10 if is_portrait else 16)
    _heading("SELECT AN EPISODE", "Listen to the music cues and play the stage!")
    if games.is_empty():
        _text("No valid game packs found. Run the manifest validator.")
    var grid: BoxContainer
    if is_portrait:
        grid = VBoxContainer.new()
        grid.add_theme_constant_override("separation", 8)
    else:
        grid = HBoxContainer.new()
        grid.add_theme_constant_override("separation", 12)
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(grid)

    var ep_num := 1
    for game in games:
        var card := PanelContainer.new()
        var accent := Color(str(game["color"]))
        card.add_theme_stylebox_override("panel", RhythmTokens.panel( Color("fffdf7"), 18, 4, RhythmTokens.INK, 8 if is_portrait else 12 ))
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.size_flags_vertical = Control.SIZE_EXPAND_FILL
        grid.add_child(card)

        var cbox := VBoxContainer.new()
        cbox.add_theme_constant_override("separation", 4 if is_portrait else 6)
        card.add_child(cbox)

        var ep_lbl := Label.new()
        var bpm_val := int(float(game["_chart"].get("bpm", 100)))
        ep_lbl.text = "EPISODE 0%d  ·  %d BPM" % [ep_num, bpm_val]
        ep_lbl.add_theme_font_size_override("font_size", 12 if is_portrait else 13)
        ep_lbl.add_theme_color_override("font_color", RhythmTokens.MUTED)
        ep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cbox.add_child(ep_lbl)

        var poster := StageUIArt.new().setup("poster_card", str(game["id"]), "SUPERB", bool(profile.get("reduced_motion", false)))
        poster.size_flags_vertical = Control.SIZE_EXPAND_FILL
        poster.custom_minimum_size = Vector2(0, 62 if is_portrait else 170)
        cbox.add_child(poster)

        var title_lbl := Label.new()
        title_lbl.text = str(game["name"])
        title_lbl.add_theme_font_size_override("font_size", 18 if is_portrait else 21)
        title_lbl.add_theme_color_override("font_color", RhythmTokens.INK)
        title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        cbox.add_child(title_lbl)

        var desc_lbl := Label.new()
        desc_lbl.text = str(game["description"])
        desc_lbl.add_theme_font_size_override("font_size", 12 if is_portrait else 13)
        desc_lbl.add_theme_color_override("font_color", RhythmTokens.MUTED)
        desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        cbox.add_child(desc_lbl)

        var best_score := RhythmSave.best(str(game["id"]))
        var play_ep_btn := Button.new()
        play_ep_btn.text = "▶ PLAY  (BEST %d)" % best_score if best_score > 0 else "▶ PLAY EPISODE"
        RhythmTokens.style_button(play_ep_btn, accent, Vector2(120, 38 if is_portrait else 44), 15 if is_portrait else 17)
        play_ep_btn.pressed.connect(_guide.bind(game))
        cbox.add_child(play_ep_btn)
        ep_num += 1

    var back_btn := _button("◀ BACK TO TITLE", _home, RhythmTokens.INK)
    if is_portrait:
        back_btn.custom_minimum_size.y = 40

func _guide(game: Dictionary) -> void:
    selected = game
    _reset_page("guide", 16)
    _heading(str(game["name"]) + " — REHEARSAL", str(game["description"]))

    rehearsal_art = StageUIArt.new().setup("rehearsal_stage", str(game["id"]), "SUPERB", bool(profile.get("reduced_motion", false)))
    rehearsal_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rehearsal_art.custom_minimum_size = Vector2(0, 180)
    body.add_child(rehearsal_art)

    var instruction := "Listen to the factory whistle cue, then press SPACE / F / J or Click the stage on the beat!"
    if str(game["id"]) == "echo_planet":
        instruction = "LISTEN to Luma-Lou's 4-beat alien phrase, then ECHO those exact beats back on YOUR TURN!"
    elif str(game["id"]) == "rhythm_kitchen":
        instruction = "LEFT (A / Left Arrow / Left Stage) flips the Skillet! RIGHT (L / Right Arrow / Right Stage) tosses the Bowl!"
    _text(instruction, 17, RhythmTokens.INK)

    var action_row := HBoxContainer.new()
    action_row.add_theme_constant_override("separation", 12)
    body.add_child(action_row)

    var prac_btn := Button.new()
    prac_btn.text = "♪ TEST SOUND & TAP"
    RhythmTokens.style_button(prac_btn, RhythmTokens.YELLOW, Vector2(150, 50), 18)
    prac_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    prac_btn.pressed.connect(_rehearsal_tap)
    action_row.add_child(prac_btn)

    var start_btn := Button.new()
    start_btn.text = "★ START THE SHOW! ▶"
    RhythmTokens.style_button(start_btn, RhythmTokens.CORAL, Vector2(170, 50), 20)
    start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    start_btn.pressed.connect(_play)
    action_row.add_child(start_btn)

    _button("◀ CHOOSE ANOTHER EPISODE", _select_games, RhythmTokens.INK)

func _rehearsal_tap() -> void:
    if is_instance_valid(preview_sfx) and not selected.is_empty():
        preview_sfx.volume_linear = float(profile.get("volume", 0.85))
        preview_sfx.stream = RhythmSynth.make_world_hit(str(selected["id"]), "Perfect", "left")
        preview_sfx.play()
    if is_instance_valid(rehearsal_art):
        rehearsal_art.trigger_rehearsal_hit("Perfect")

func _play() -> void:
    _dispose_session()
    var is_portrait := get_window().size.x < get_window().size.y
    _reset_page("play", 6 if is_portrait else 8)
    session = RhythmSession.new()
    add_child(session)
    session.configure(selected, profile)
    session.finished.connect(_results)
    session.countdown.connect(_on_countdown)

    # Sleek, Minimal Top Stage Bar so the Cartoon World occupies ~90% of the screen!
    var top_bar := HBoxContainer.new()
    top_bar.add_theme_constant_override("separation", 6 if is_portrait else 10)
    body.add_child(top_bar)

    var stage_title := Label.new()
    stage_title.text = "★ " + str(selected["name"]).to_upper()
    stage_title.add_theme_font_size_override("font_size", 13 if is_portrait else 16)
    stage_title.add_theme_color_override("font_color", RhythmTokens.YELLOW)
    top_bar.add_child(stage_title)

    status = Label.new()
    status.text = "READY?"
    status.add_theme_font_size_override("font_size", 12 if is_portrait else 16)
    status.add_theme_color_override("font_color", RhythmTokens.WHITE)
    status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    top_bar.add_child(status)

    countdown_text = Label.new()
    countdown_text.text = "3"
    countdown_text.add_theme_font_size_override("font_size", 15 if is_portrait else 20)
    countdown_text.add_theme_color_override("font_color", RhythmTokens.CORAL)
    top_bar.add_child(countdown_text)

    hud = Label.new()
    hud.text = "SCORE 000000   COMBO 0   BEAT 0.0"
    hud.add_theme_font_size_override("font_size", 12)
    hud.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
    hud.visible = debug_open
    top_bar.add_child(hud)

    var pause_btn := Button.new()
    pause_btn.text = "II" if is_portrait else "II PAUSE"
    RhythmTokens.style_button(pause_btn, RhythmTokens.YELLOW, Vector2(44 if is_portrait else 96, 32 if is_portrait else 36), 14 if is_portrait else 15)
    pause_btn.pressed.connect(_toggle_pause)
    top_bar.add_child(pause_btn)

    # Full-Bleed Cartoon Stage Frame (~90% of viewport height!)
    var frame := PanelContainer.new()
    frame.add_theme_stylebox_override("panel", RhythmTokens.panel(RhythmTokens.WHITE, 18, 4, RhythmTokens.INK, 4))
    frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(frame)

    var stage_holder := Control.new()
    stage_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stage_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(stage_holder)

    var visual_scene := load(str(selected["scene"])) as PackedScene
    if visual_scene == null:
        _text("Scene unavailable", 18, RhythmTokens.WHITE)
        return
    visual = visual_scene.instantiate() as RhythmVisual
    stage_holder.add_child(visual)
    visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visual.configure(selected["_chart"], session, bool(profile["reduced_motion"]))

    # Pause Modal Overlay on top of the page
    pause_modal = _build_pause_modal()
    pause_modal.visible = false
    page.add_child(pause_modal)
    pause_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    debug_label = _text("", 12, RhythmTokens.YELLOW)
    debug_label.visible = debug_open

    # Subtle 1-line stage control hint at the bottom edge (No giant app buttons!)
    var hint_str := "TAP STAGE or SPACE / F / J on the beat!" if is_portrait else "CLICK / TAP STAGE or press SPACE / F / J on the beat!   (P / ESC to Pause)"
    if str(selected["id"]) == "rhythm_kitchen":
        hint_str = "◀ TAP LEFT : Skillet   |   TAP RIGHT : Bowl ▶" if is_portrait else "◀ CLICK LEFT STAGE (or A / Left) : Skillet     |     CLICK RIGHT STAGE (or L / Right) : Mixing Bowl ▶"
    _text(hint_str, 12 if is_portrait else 13, Color(1.0, 0.96, 0.86, 0.85))

func _build_pause_modal() -> Control:
    var overlay := ColorRect.new()
    overlay.color = Color(0.08, 0.06, 0.12, 0.72)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center)

    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(310, 230)
    card.add_theme_stylebox_override("panel", RhythmTokens.panel(RhythmTokens.CREAM, 20, 4, RhythmTokens.INK, 18))
    center.add_child(card)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    card.add_child(vbox)

    var p_title := Label.new()
    p_title.text = "SHOW PAUSED"
    p_title.add_theme_font_size_override("font_size", 24)
    p_title.add_theme_color_override("font_color", RhythmTokens.INK)
    p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(p_title)

    var res_btn := Button.new()
    res_btn.text = "▶ RESUME SHOW"
    RhythmTokens.style_button(res_btn, RhythmTokens.CORAL, Vector2(220, 46), 18)
    res_btn.pressed.connect(_toggle_pause)
    vbox.add_child(res_btn)

    var rest_btn := Button.new()
    rest_btn.text = "↻ RESTART TRACK"
    RhythmTokens.style_button(rest_btn, RhythmTokens.AQUA, Vector2(220, 44), 17)
    rest_btn.pressed.connect(_play)
    vbox.add_child(rest_btn)

    var exit_btn := Button.new()
    exit_btn.text = "◀ STAGE SELECT"
    RhythmTokens.style_button(exit_btn, RhythmTokens.INK, Vector2(220, 44), 17)
    exit_btn.pressed.connect(_exit_play)
    vbox.add_child(exit_btn)

    return overlay

func _on_countdown(number: int) -> void:
    # Focus changes can deliver a queued countdown signal after Pause updates the UI.
    if is_instance_valid(session) and session.paused:
        return
    if is_instance_valid(countdown_text):
        countdown_text.text = "PLAY" if number < 0 else ("GO!" if number == 0 else str(number))
    if number < 0 and is_instance_valid(status):
        status.text = "FOLLOW THE SOUND"

func _submit_touch(lane: String) -> void:
    if is_instance_valid(session):
        session.submit(lane)

func _toggle_pause() -> void:
    if not is_instance_valid(session):
        return
    if session.paused:
        session.resume_session()
    else:
        session.pause_session()
    _update_pause_hint()

func _update_pause_hint() -> void:
    if is_instance_valid(pause_modal) and is_instance_valid(session):
        pause_modal.visible = session.paused
    if is_instance_valid(status) and is_instance_valid(session):
        status.text = "PAUSED - TAP RESUME OR PRESS P" if session.paused else ("FOLLOW THE SOUND" if session.active else "GET READY")
    if is_instance_valid(countdown_text) and is_instance_valid(session):
        if session.paused:
            countdown_text.text = "PAUSED"
        elif session.active:
            countdown_text.text = "PLAY"
        else:
            var elapsed := float(Time.get_ticks_usec() - session.countdown_start_usec) / 1000000.0
            countdown_text.text = str(maxi(0, 3 - int(elapsed)))

func _exit_play() -> void:
    _dispose_session()
    _select_games()

func _results(summary: Dictionary) -> void:
    latest_summary = summary
    _dispose_session()
    _reset_page("results", 16)

    var c: Dictionary = summary["counts"]
    var total_ev := maxi(1, int(summary.get("total", 1)))
    var hit_ratio := float(int(c["Perfect"]) + int(c["Good"])) / float(total_ev)
    var perf_ratio := float(int(c["Perfect"])) / float(total_ev)
    var tier := "TRY AGAIN"
    if hit_ratio >= 0.75 and perf_ratio >= 0.45:
        tier = "SUPERB"
    elif hit_ratio >= 0.45:
        tier = "OK"

    if is_instance_valid(preview_sfx):
        preview_sfx.volume_linear = float(profile.get("volume", 0.85))
        if tier == "SUPERB":
            preview_sfx.stream = RhythmSynth.make_fanfare(true)
        elif tier == "OK":
            preview_sfx.stream = RhythmSynth.make_fanfare(false)
        else:
            preview_sfx.stream = RhythmSynth.make_hit("Miss")
        preview_sfx.play()

    var ep_title := str(selected.get("name", "Stage"))
    var ep_comment := "The crowd goes wild! Every beat hit the mark!" if tier == "SUPERB" else ("Solid groove! Keep riding the rhythm!" if tier == "OK" else "Listen closely to the musical cues and try again!")
    _heading(ep_title + " — " + tier + "!", ep_comment)

    var vignette := StageUIArt.new().setup("result_vignette", str(selected.get("id", "beat_factory")), tier, bool(profile.get("reduced_motion", false)))
    vignette.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vignette.custom_minimum_size = Vector2(0, 185)
    body.add_child(vignette)

    _text("SCORE %06d     ·     BEST %06d     ·     MAX COMBO %d" % [int(summary["score"]), int(summary["best"]), int(summary["max_combo"])], 21, RhythmTokens.INK)
    _text("★ PERFECT %d     |     ♪ GOOD %d     |     ✗ MISS %d" % [c["Perfect"], c["Good"], c["Miss"]], 17, RhythmTokens.MUTED)

    var btn_row := HBoxContainer.new()
    btn_row.add_theme_constant_override("separation", 12)
    body.add_child(btn_row)

    var retry_btn := Button.new()
    retry_btn.text = "↻ PLAY AGAIN"
    RhythmTokens.style_button(retry_btn, RhythmTokens.CORAL, Vector2(150, 50), 19)
    retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    retry_btn.pressed.connect(_play)
    btn_row.add_child(retry_btn)

    var stages_btn := Button.new()
    stages_btn.text = "◀ STAGE SELECT"
    RhythmTokens.style_button(stages_btn, RhythmTokens.INK, Vector2(150, 50), 19)
    stages_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stages_btn.pressed.connect(_select_games)
    btn_row.add_child(stages_btn)

func _settings_page() -> void:
    _reset_page("settings", 18)
    _heading("TIMING & AUDIO CALIBRATION", "Offsets are stored locally on this device")
    _spacer()
    _slider("Input offset (ms)  - later tap = positive", "input_ms", -250, 250, 5)
    _slider("Extra output offset (ms)", "output_ms", -250, 250, 5)
    _slider("Music & SFX volume", "volume", 0, 100, 5)
    var toggle := CheckButton.new()
    toggle.text = "Reduced motion (calm stage effects)"
    toggle.button_pressed = bool(profile["reduced_motion"])
    toggle.toggled.connect(func(checked: bool): profile["reduced_motion"] = checked)
    body.add_child(toggle)
    _spacer()
    _text("Tip: Bluetooth headphones may need +40 to +90 ms input offset.", 14, RhythmTokens.MUTED)
    _button("SAVE & RETURN TO TITLE", _save_settings, RhythmTokens.AQUA)

func _slider(label_text: String, key: String, lo: float, hi: float, step: float) -> void:
    var value := int(round(float(profile[key]) * (100.0 if key == "volume" else 1.0)))
    var label := _text(label_text + ": " + str(value), 17)
    var slider := HSlider.new()
    slider.min_value = lo
    slider.max_value = hi
    slider.step = step
    slider.value = value
    slider.custom_minimum_size.y = 40
    body.add_child(slider)
    slider.value_changed.connect(func(v: float):
        profile[key] = v / 100.0 if key == "volume" else int(v)
        label.text = label_text + ": " + str(int(v))
    )

func _save_settings() -> void:
    var err := RhythmSave.write_settings(profile)
    if err != OK:
        push_warning("Could not write user settings: " + str(err))
    _home()

func _offline_page() -> void:
    _reset_page("offline", 18)
    _spacer()
    _heading("PLAY ANYWHERE OFFLINE", "100% self-contained cartoon art & 44.1kHz stereo audio")
    _spacer()
    _text("WEB / PWA: Use your browser's Install App / Add to Home Screen command. Complete the first online load so the Service Worker caches the full game and 44.1kHz stereo soundtracks.", 18)
    _text("WINDOWS DESKTOP: Launch RhythmRhythm.exe alongside RhythmRhythm.pck for zero-network native play.", 18)
    _text("All highscores and timing offsets are saved locally on your device.", 15, RhythmTokens.MUTED)
    _spacer()
    _button("◀ BACK TO TITLE", _home, RhythmTokens.INK)

func _dispose_session() -> void:
    if is_instance_valid(session):
        session.stop_session()
        session.queue_free()
    session = null
    visual = null
    pause_modal = null
